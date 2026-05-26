import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database/database.service';
import { TokenService } from '../token/token.service';
import { EmailService } from '../../email/email.service';
import { EmailTemplates } from '../../email/model/emailTemplates';
import { formatSlotForEmail } from './webinar-timezone.util';
import { EmailUnsubscriptionService } from '../email-unsubscription/email-unsubscription.service';

@Injectable()
export class WebinarService {
  constructor(
    private readonly databaseService: DatabaseService,
    private readonly tokenService: TokenService,
    private readonly emailService: EmailService,
    private readonly emailUnsubscriptionService: EmailUnsubscriptionService,
  ) {}

  private generateUnsubscribeLink(email: string): string {
    const base = process.env.FRONTEND_URL ?? 'https://portal.nczgroup.com';
    return `${base}/unsubscribe?email=${encodeURIComponent(email)}`;
  }

  // ── Webinars ─────────────────────────────────────────────────────────────

  async getWebinars(): Promise<any[]> {
    const result = await this.databaseService.execute('[portal].[spWebinar_Get]', [
      { name: 'webinarId', type: mssql.TYPES.Int, value: null },
    ]);
    return result.results ?? [];
  }

  async getWebinarById(webinarId: number): Promise<{ webinar: any; slots: any[]; bookings: any[] }> {
    const result = await this.databaseService.execute('[portal].[spWebinar_Get]', [
      { name: 'webinarId', type: mssql.TYPES.Int, value: webinarId },
    ]);
    const webinar = result.results?.[0] ?? null;
    const slots = result.recordsets?.[1] ?? [];

    const bookingsResult = await this.databaseService.execute('[portal].[spWebinarBooking_Get]', [
      { name: 'webinarId', type: mssql.TYPES.Int, value: webinarId },
      { name: 'bookingId', type: mssql.TYPES.Int, value: null },
    ]);

    return { webinar, slots, bookings: bookingsResult.results ?? [] };
  }

  async createWebinar(
    title: string,
    description: string | null,
    organizerUserId: number,
    companyId: number,
    companyName: string,
    slots: Array<{ slotDateTime: string; capacity: number; meetingLink?: string | null; durationMinutes?: number }>,
    timezone: string = 'UTC',
    invitationHtml?: string | null,
  ): Promise<any> {
    // 1. Insert webinar (no tokenKey yet)
    const webinarResult = await this.databaseService.execute('[portal].[spWebinar_Save]', [
      { name: 'webinarId',       type: mssql.TYPES.Int,      value: null },
      { name: 'title',           type: mssql.TYPES.NVarChar, value: title },
      { name: 'description',     type: mssql.TYPES.NVarChar, value: description ?? null },
      { name: 'organizerUserId', type: mssql.TYPES.Int,      value: organizerUserId },
      { name: 'companyId',       type: mssql.TYPES.Int,      value: companyId },
      { name: 'tokenKey',        type: mssql.TYPES.NVarChar, value: null },
      { name: 'postWebinarFormToken', type: mssql.TYPES.NVarChar, value: null },
      { name: 'isActive',        type: mssql.TYPES.Bit,      value: 1 },
      { name: 'timezone',        type: mssql.TYPES.NVarChar, value: timezone },
      { name: 'invitationHtml',  type: mssql.TYPES.NVarChar, value: invitationHtml ?? null },
    ]);

    const webinar = webinarResult.results?.[0];
    if (!webinar) throw new Error('Failed to create webinar');

    const webinarId: number = webinar.webinarId;

    // 2. Auto-generate token (no expiry — activeTo far future)
    const activeTo = new Date('2099-12-31T23:59:59Z');
    const properties = JSON.stringify({ companyId, webinarId, companyName });
    const token = await this.tokenService.createToken(null, null, null, activeTo, true, 'webinar', properties);
    const tokenKey: string = token?.tokenKey ?? null;

    // 3. Update webinar with tokenKey (pass timezone explicitly so it is never lost)
    await this.databaseService.execute('[portal].[spWebinar_Save]', [
      { name: 'webinarId',            type: mssql.TYPES.Int,      value: webinarId },
      { name: 'title',                type: mssql.TYPES.NVarChar, value: null },
      { name: 'description',          type: mssql.TYPES.NVarChar, value: null },
      { name: 'organizerUserId',      type: mssql.TYPES.Int,      value: null },
      { name: 'companyId',            type: mssql.TYPES.Int,      value: null },
      { name: 'tokenKey',             type: mssql.TYPES.NVarChar, value: tokenKey },
      { name: 'postWebinarFormToken', type: mssql.TYPES.NVarChar, value: null },
      { name: 'isActive',             type: mssql.TYPES.Bit,      value: null },
      { name: 'timezone',             type: mssql.TYPES.NVarChar, value: timezone },
    ]);

    // 4. Insert slots
    const savedSlots: any[] = [];
    for (const slot of slots) {
      const slotResult = await this.databaseService.execute('[portal].[spWebinarSlot_Save]', [
        { name: 'slotId',          type: mssql.TYPES.Int,      value: null },
        { name: 'webinarId',       type: mssql.TYPES.Int,      value: webinarId },
        { name: 'slotDateTime',    type: mssql.TYPES.NVarChar, value: slot.slotDateTime },
        { name: 'capacity',        type: mssql.TYPES.Int,      value: slot.capacity },
        { name: 'meetingLink',     type: mssql.TYPES.NVarChar, value: slot.meetingLink ?? null },
        { name: 'durationMinutes', type: mssql.TYPES.Int,      value: slot.durationMinutes ?? 45 },
      ]);
      if (slotResult.results?.[0]) savedSlots.push(slotResult.results[0]);
    }

    return { ...webinar, tokenKey, slots: savedSlots };
  }

  async updateWebinar(
    webinarId: number,
    title?: string,
    description?: string,
    organizerUserId?: number,
    companyId?: number,
    isActive?: boolean,
    slots?: Array<{ slotId?: number; slotDateTime: string; capacity: number; meetingLink?: string | null; durationMinutes?: number }>,
    timezone?: string,
  ): Promise<any> {
    const result = await this.databaseService.execute('[portal].[spWebinar_Save]', [
      { name: 'webinarId',       type: mssql.TYPES.Int,      value: webinarId },
      { name: 'title',           type: mssql.TYPES.NVarChar, value: title ?? null },
      { name: 'description',     type: mssql.TYPES.NVarChar, value: description ?? null },
      { name: 'organizerUserId', type: mssql.TYPES.Int,      value: organizerUserId ?? null },
      { name: 'companyId',       type: mssql.TYPES.Int,      value: companyId ?? null },
      { name: 'tokenKey',        type: mssql.TYPES.NVarChar, value: null },
      { name: 'postWebinarFormToken', type: mssql.TYPES.NVarChar, value: null },
      { name: 'isActive',        type: mssql.TYPES.Bit,      value: isActive !== undefined ? (isActive ? 1 : 0) : null },
      { name: 'timezone',        type: mssql.TYPES.NVarChar, value: timezone ?? null },
    ]);

    if (slots && slots.length > 0) {
      for (const slot of slots) {
        await this.databaseService.execute('[portal].[spWebinarSlot_Save]', [
          { name: 'slotId',          type: mssql.TYPES.Int,      value: slot.slotId ?? null },
          { name: 'webinarId',       type: mssql.TYPES.Int,      value: webinarId },
          { name: 'slotDateTime',    type: mssql.TYPES.NVarChar, value: slot.slotDateTime },
          { name: 'capacity',        type: mssql.TYPES.Int,      value: slot.capacity },
          { name: 'meetingLink',     type: mssql.TYPES.NVarChar, value: slot.meetingLink ?? null },
          { name: 'durationMinutes', type: mssql.TYPES.Int,      value: slot.durationMinutes ?? 45 },
        ]);
      }
    }

    return result.results?.[0] ?? null;
  }

  async patchInvitationHtml(webinarId: number, invitationHtml: string | null): Promise<any> {
    const result = await this.databaseService.execute('[portal].[spWebinar_Save]', [
      { name: 'webinarId',            type: mssql.TYPES.Int,      value: webinarId },
      { name: 'title',                type: mssql.TYPES.NVarChar, value: null },
      { name: 'description',          type: mssql.TYPES.NVarChar, value: null },
      { name: 'organizerUserId',      type: mssql.TYPES.Int,      value: null },
      { name: 'companyId',            type: mssql.TYPES.Int,      value: null },
      { name: 'tokenKey',             type: mssql.TYPES.NVarChar, value: null },
      { name: 'postWebinarFormToken', type: mssql.TYPES.NVarChar, value: null },
      { name: 'isActive',             type: mssql.TYPES.Bit,      value: null },
      { name: 'invitationHtml',       type: mssql.TYPES.NVarChar, value: invitationHtml },
    ]);
    return result.results?.[0] ?? null;
  }

  async patchPostWebinarFormToken(webinarId: number, postWebinarFormToken: string): Promise<any> {
    const result = await this.databaseService.execute('[portal].[spWebinar_Save]', [
      { name: 'webinarId',            type: mssql.TYPES.Int,      value: webinarId },
      { name: 'title',                type: mssql.TYPES.NVarChar, value: null },
      { name: 'description',          type: mssql.TYPES.NVarChar, value: null },
      { name: 'organizerUserId',      type: mssql.TYPES.Int,      value: null },
      { name: 'companyId',            type: mssql.TYPES.Int,      value: null },
      { name: 'tokenKey',             type: mssql.TYPES.NVarChar, value: null },
      { name: 'postWebinarFormToken', type: mssql.TYPES.NVarChar, value: postWebinarFormToken },
      { name: 'isActive',             type: mssql.TYPES.Bit,      value: null },
    ]);
    return result.results?.[0] ?? null;
  }

  async deleteWebinar(webinarId: number): Promise<void> {
    await this.databaseService.execute('[portal].[spWebinar_Delete]', [
      { name: 'webinarId', type: mssql.TYPES.Int, value: webinarId },
    ]);
  }

  // ── Public booking form ───────────────────────────────────────────────────

  async getPublicBookingForm(tokenKey: string): Promise<any> {
    // Validate the webinar token
    const token = await this.tokenService.validateToken(tokenKey, 'webinar');
    if (!token || !token.isActive) return null;

    let props: { companyId?: number; webinarId?: number; companyName?: string } = {};
    try {
      props = token.properties ? JSON.parse(token.properties) : {};
    } catch {
      props = {};
    }

    const webinarId: number = props.webinarId;
    if (!webinarId) return null;

    const slotsResult = await this.databaseService.execute('[portal].[spWebinarSlot_Get]', [
      { name: 'webinarId', type: mssql.TYPES.Int, value: webinarId },
      { name: 'activeOnly', type: mssql.TYPES.Bit, value: 0 },
    ]);

    const webinarResult = await this.databaseService.execute('[portal].[spWebinar_Get]', [
      { name: 'webinarId', type: mssql.TYPES.Int, value: webinarId },
    ]);

    const webinar = webinarResult.results?.[0];
    if (!webinar) return null;

    const now = new Date();
    const slots = (slotsResult.results ?? []).map((s: any) => ({
      ...s,
      isPast: new Date(s.slotDateTime) < now,
    }));

    return {
      webinarId,
      title: webinar.title,
      description: webinar.description,
      companyName: props.companyName ?? '',
      companyId: props.companyId,
      timezone: webinar.timezone ?? 'UTC',
      slots,
    };
  }

  async resolveWidToken(tokenKey: string): Promise<any> {
    const token = await this.tokenService.validateToken(tokenKey, 'webinar');
    if (!token || !token.isActive) return null;

    try {
      const props = token.properties ? JSON.parse(token.properties) : {};
      return {
        companyId: props.companyId ?? null,
        webinarId: props.webinarId ?? null,
        companyName: props.companyName ?? null,
      };
    } catch {
      return null;
    }
  }

  async createBooking(
    tokenKey: string,
    slotId: number,
    businessName: string,
    contactEmail: string,
    webinarId: number,
    companyId: number,
  ): Promise<any> {
    const result = await this.databaseService.execute('[portal].[spWebinarBooking_Save]', [
      { name: 'webinarId',    type: mssql.TYPES.Int,      value: webinarId },
      { name: 'slotId',       type: mssql.TYPES.Int,      value: slotId },
      { name: 'companyId',    type: mssql.TYPES.Int,      value: companyId },
      { name: 'businessName', type: mssql.TYPES.NVarChar, value: businessName },
      { name: 'contactEmail', type: mssql.TYPES.NVarChar, value: contactEmail },
      { name: 'tokenKey',     type: mssql.TYPES.NVarChar, value: tokenKey },
    ]);

    const booking = result.results?.[0];
    if (!booking) throw new Error('Failed to create booking');

    return booking;
  }

  async getPendingReminders(): Promise<any[]> {
    const result = await this.databaseService.execute('[portal].[spWebinarBooking_GetPendingReminders]', []);
    return result.results ?? [];
  }

  async markReminderSent(bookingId: number): Promise<void> {
    await this.databaseService.execute('[portal].[spWebinarBooking_MarkReminderSent]', [
      { name: 'bookingId', type: mssql.TYPES.Int, value: bookingId },
    ]);
  }

  // ── iCal helper ──────────────────────────────────────────────────────────

  generateIcsContent(
    summary: string,
    description: string,
    startDateTime: Date,
    organizerEmail?: string | null,
    attendeeEmail?: string | null,
    method = 'REQUEST',
    eventUid?: string | null,
    organizerName?: string | null,
    meetingLink?: string | null,
    extraAttendees?: Array<{ email: string; name?: string | null; role?: string; partstat?: string; rsvp?: boolean }>,
    durationMinutes = 45,
    sequence = 0,
  ): string {
    const pad = (n: number) => n.toString().padStart(2, '0');
    const fmt = (d: Date) =>
      `${d.getUTCFullYear()}${pad(d.getUTCMonth() + 1)}${pad(d.getUTCDate())}T` +
      `${pad(d.getUTCHours())}${pad(d.getUTCMinutes())}${pad(d.getUTCSeconds())}Z`;

    const endDateTime = new Date(startDateTime.getTime() + durationMinutes * 60 * 1000);
    const uid = eventUid ?? `webinar-${Date.now()}@nczgroup.com`;

    const lines = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Neutral Carbon Zone//Webinar Booking//EN',
      'CALSCALE:GREGORIAN',
      `METHOD:${method}`,
      'BEGIN:VEVENT',
      `UID:${uid}`,
      `DTSTAMP:${fmt(new Date())}`,
      `DTSTART:${fmt(startDateTime)}`,
      `DTEND:${fmt(endDateTime)}`,
      `SEQUENCE:${sequence}`,
      `SUMMARY:${summary}`,
      `DESCRIPTION:${(description ?? '').replace(/\\/g, '\\\\').replace(/;/g, '\\;').replace(/,/g, '\\,').replace(/\n/g, '\\n')}`,
      'STATUS:CONFIRMED',
    ];

    if (organizerEmail) {
      const orgCn = organizerName || organizerEmail;
      lines.push(`ORGANIZER;CN="${orgCn}":mailto:${organizerEmail}`);
    }
    if (attendeeEmail) {
      lines.push(`ATTENDEE;CN="${attendeeEmail}";ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE:mailto:${attendeeEmail}`);
    }
    if (extraAttendees?.length) {
      for (const a of extraAttendees) {
        const cn = a.name || a.email;
        const role = a.role || 'REQ-PARTICIPANT';
        const partstat = a.partstat || 'NEEDS-ACTION';
        const rsvp = a.rsvp !== false ? 'TRUE' : 'FALSE';
        lines.push(`ATTENDEE;CN="${cn}";ROLE=${role};PARTSTAT=${partstat};RSVP=${rsvp}:mailto:${a.email}`);
      }
    }
    if (meetingLink) {
      lines.push(`LOCATION:${meetingLink}`);
      lines.push(`URL:${meetingLink}`);
    }

    lines.push('END:VEVENT', 'END:VCALENDAR');

    // RFC 5545 §3.1: fold lines longer than 75 octets with CRLF + SPACE continuation
    const foldLine = (line: string): string => {
      if (line.length <= 75) return line;
      let out = line.substring(0, 75);
      let pos = 75;
      while (pos < line.length) {
        out += '\r\n ' + line.substring(pos, pos + 74);
        pos += 74;
      }
      return out;
    };

    // Each content line ends with CRLF (including the last one — required by RFC 5545)
    return lines.map(foldLine).join('\r\n') + '\r\n';
  }

  // ── Email helpers ─────────────────────────────────────────────────────────

  async getBookingsForSlot(slotId: number): Promise<any[]> {
    const result = await this.databaseService.execute('[portal].[spWebinarBooking_Get]', [
      { name: 'webinarId', type: mssql.TYPES.Int, value: null },
      { name: 'bookingId', type: mssql.TYPES.Int, value: null },
      { name: 'slotId',    type: mssql.TYPES.Int, value: slotId },
    ]);
    return result.results ?? [];
  }

  async queueBookingConfirmation(
    contactEmail: string,
    webinarTitle: string,
    businessName: string,
    slotDateTime: Date,
    webinarDescription: string,
    meetingLink?: string | null,
    organizerEmail?: string | null,
    organizerName?: string | null,
    slotId?: number | null,
    bookingId?: number | null,
    timezone: string = 'UTC',
    durationMinutes = 45,
  ): Promise<void> {
    const meetingLinkBlock = meetingLink
      ? `<div style="text-align:center;margin:24px 0"><a href="${meetingLink}" style="background:#2e7d32;color:#ffffff;padding:12px 28px;text-decoration:none;border-radius:4px;font-weight:600;font-size:15px;display:inline-block">&#127968; Join Webinar</a></div>`
      : '';
    const from = organizerName && organizerEmail ? `${organizerName} <${organizerEmail}>` : (organizerEmail || undefined);
    // Use the same per-slot UID as the organizer's event so calendar clients can update it in place
    const eventUid = slotId ? `webinar-slot-${slotId}@nczgroup.com` : null;
    await this.emailService.queueEmail(
      contactEmail,
      EmailTemplates.WEBINAR_BOOKING_CONFIRMATION,
      {
        webinarTitle,
        businessName,
        slotDateTime: formatSlotForEmail(new Date(slotDateTime), timezone),
        description: webinarDescription ?? '',
        // icsContent: this.generateIcsContent(webinarTitle, webinarDescription ?? '', new Date(slotDateTime), organizerEmail ?? null, contactEmail, 'REQUEST', eventUid, organizerName ?? null, meetingLink ?? null, undefined, durationMinutes),
        meetingLinkBlock,
        unsubscribeLink: this.generateUnsubscribeLink(contactEmail),
      },
      from,
    );
  }

  async queueOrganizerNotification(
    organizerEmail: string,
    webinarTitle: string,
    businessName: string,
    contactEmail: string,
    slotDateTime: Date,
    organizerName?: string | null,
    slotId?: number | null,
    bookingId?: number | null,
    meetingLink?: string | null,
    timezone: string = 'UTC',
    allSlotAttendees?: Array<{ email: string; name: string }>,
    sequence = 0,
  ): Promise<void> {
    // Per-slot UID so the organizer's calendar event is updated (not duplicated) on each new booking
    const eventUid = slotId ? `webinar-slot-${slotId}@nczgroup.com` : null;

    // Build attendee description
    const attendeeLines = (allSlotAttendees ?? [{ email: contactEmail, name: businessName }])
      .map((a) => `${a.name} (${a.email})`)
      .join('\n');
    const description = `Attendees:\n${attendeeLines}`;

    // All bookings as extra ATTENDEE entries in the ICS (so organizer's calendar shows guests)
    // ROLE=OPT-PARTICIPANT marks them as optional guests rather than required participants
    // const extraAttendees = (allSlotAttendees ?? [{ email: contactEmail, name: businessName }])
    //   .map((a) => ({ email: a.email, name: a.name, role: 'OPT-PARTICIPANT', partstat: 'NEEDS-ACTION', rsvp: false }));

    // const icsContent = this.generateIcsContent(
    //   webinarTitle,
    //   description,
    //   new Date(slotDateTime),
    //   organizerEmail,
    //   null,
    //   'PUBLISH',
    //   eventUid,
    //   organizerName ?? null,
    //   meetingLink ?? null,
    //   extraAttendees,
    //   45,
    //   sequence,
    // );
    const from = organizerName ? `${organizerName} <${organizerEmail}>` : organizerEmail;
    await this.emailService.queueEmail(
      organizerEmail,
      EmailTemplates.WEBINAR_ORGANIZER_NOTIFICATION,
      {
        webinarTitle,
        businessName,
        contactEmail,
        slotDateTime: formatSlotForEmail(new Date(slotDateTime), timezone),
        // icsContent,
      },
      from,
    );
  }

  async queueReminderEmail(
    contactEmail: string,
    webinarTitle: string,
    businessName: string,
    slotDateTime: Date,
    meetingLink?: string | null,
    organizerEmail?: string | null,
    organizerName?: string | null,
    timezone: string = 'UTC',
  ): Promise<void> {
    const meetingLinkBlock = meetingLink
      ? `<div style="text-align:center;margin:24px 0"><a href="${meetingLink}" style="background:#e65100;color:#ffffff;padding:12px 28px;text-decoration:none;border-radius:4px;font-weight:600;font-size:15px;display:inline-block">&#127968; Join Webinar</a></div>`
      : '';
    const from = organizerName && organizerEmail ? `${organizerName} <${organizerEmail}>` : (organizerEmail || undefined);
    await this.emailService.queueEmail(
      contactEmail,
      EmailTemplates.WEBINAR_REMINDER,
      {
        webinarTitle,
        businessName,
        slotDateTime: formatSlotForEmail(new Date(slotDateTime), timezone),
        meetingLinkBlock,
        unsubscribeLink: this.generateUnsubscribeLink(contactEmail),
      },
      from,
    );
  }

  async queueFeedbackEmail(
    contactEmail: string,
    webinarTitle: string,
    businessName: string,
    feedbackFormUrl: string,
    organizerEmail?: string | null,
    organizerName?: string | null,
  ): Promise<void> {
    const from = organizerName && organizerEmail ? `${organizerName} <${organizerEmail}>` : (organizerEmail || undefined);
    await this.emailService.queueEmail(
      contactEmail,
      EmailTemplates.WEBINAR_FEEDBACK_FORM,
      { webinarTitle, businessName, feedbackFormUrl, unsubscribeLink: this.generateUnsubscribeLink(contactEmail) },
      from,
    );
  }

  async sendFeedbackEmails(
    webinarId: number,
    recipients: Array<{ contactEmail: string; businessName: string }>,
  ): Promise<number> {
    const data = await this.getWebinarById(webinarId);
    const baseUrl = data?.webinar?.postWebinarFormToken;
    if (!baseUrl) throw new Error('Post-webinar form URL not configured for this webinar');

    const tokenKey = data?.webinar?.tokenKey;
    const feedbackFormUrl = tokenKey ? `${baseUrl}?wid=${tokenKey}` : baseUrl;

    const organizerEmail: string | null = data?.webinar?.organizerEmail ?? null;
    const organizerName: string | null  = data?.webinar?.organizerName  ?? null;

    let sent = 0;
    for (const r of recipients) {
      await this.queueFeedbackEmail(r.contactEmail, data.webinar.title, r.businessName, feedbackFormUrl, organizerEmail, organizerName);
      sent++;
    }
    return sent;
  }

  // ── Invitation helpers ────────────────────────────────────────────────────

  async sendInvitationEmails(
    webinarId: number,
    recipients: Array<{ supplierId: number; supplierName: string; supplierEmail: string }>,
  ): Promise<{ sent: number; insertedCount: number }> {
    const data = await this.getWebinarById(webinarId);
    if (!data?.webinar) throw new Error('Webinar not found');

    const invitationsJson = JSON.stringify(
      recipients.map((r) => ({ supplierId: r.supplierId, supplierName: r.supplierName, supplierEmail: r.supplierEmail })),
    );

    // Filter out any recipients that have globally unsubscribed
    const unsubscribedEmails = await this.emailUnsubscriptionService.getUnsubscribedEmails();
    const filteredRecipients = recipients.filter(
      (r) => !unsubscribedEmails.has(r.supplierEmail.toLowerCase()),
    );

    const saveResult = await this.databaseService.execute('[portal].[spWebinarInvitation_Save]', [
      { name: 'webinarId',       type: mssql.TYPES.Int,      value: webinarId },
      { name: 'invitationsJson', type: mssql.TYPES.NVarChar, value: invitationsJson },
    ]);
    const insertedCount: number = saveResult.results?.[0]?.insertedCount ?? 0;

    const webinar = data.webinar;
    const bookingLink = webinar.tokenKey ? `${process.env.FRONTEND_URL ?? 'https://portal.nczgroup.com'}/webinar-booking?token=${webinar.tokenKey}` : '';
    const organizerEmail: string | null = webinar.organizerEmail ?? null;
    const organizerName: string | null  = webinar.organizerName  ?? null;
    const from = organizerName && organizerEmail ? `${organizerName} <${organizerEmail}>` : (organizerEmail ?? undefined);

    // Use custom invitationHtml if set; fall back to plain description paragraph
    const descriptionBlock = webinar.invitationHtml
      ? webinar.invitationHtml
      : (webinar.description ? `<p style="color:#555;font-size:14px">${webinar.description}</p>` : '');

    let sent = 0;
    for (const r of filteredRecipients) {
      await this.emailService.queueEmail(
        r.supplierEmail,
        EmailTemplates.WEBINAR_INVITATION,
        {
          supplierName: r.supplierName,
          webinarTitle: webinar.title,
          description: webinar.description ?? '',
          descriptionBlock,
          bookingLink,
          unsubscribeLink: this.generateUnsubscribeLink(r.supplierEmail),
        },
        from,
      );
      sent++;
    }
    return { sent, insertedCount };
  }

  async getInvitations(webinarId: number): Promise<any[]> {
    const result = await this.databaseService.execute('[portal].[spWebinarInvitation_Get]', [
      { name: 'webinarId', type: mssql.TYPES.Int, value: webinarId },
    ]);
    return result.results ?? [];
  }

  async getWebinarSuppliers(webinarId: number, companyId: number, certId: number | null): Promise<any[]> {
    const result = await this.databaseService.execute('[portal].[spWebinarSuppliers_Get]', [
      { name: 'webinarId', type: mssql.TYPES.Int, value: webinarId },
      { name: 'companyId', type: mssql.TYPES.Int, value: companyId },
      { name: 'certId',    type: mssql.TYPES.Int, value: certId ?? null },
    ]);
    return result.results ?? [];
  }
}

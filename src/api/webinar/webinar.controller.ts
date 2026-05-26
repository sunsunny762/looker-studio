import {
  Body,
  Controller,
  Delete,
  Get,
  HttpException,
  HttpStatus,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Put,
  UseGuards,
  Req,
} from '@nestjs/common';
import { WebinarService } from './webinar.service';
import { TokenAuthGuard } from '../token/guards/token-auth.guard';

@Controller('webinars')
export class WebinarController {
  constructor(private readonly webinarService: WebinarService) {}

  // ── Authenticated endpoints (Firebase JWT, NCZ users) ────────────────────

  @Get()
  async getWebinars(): Promise<any> {
    try {
      return await this.webinarService.getWebinars();
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to fetch webinars',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get(':webinarId')
  async getWebinarById(@Param('webinarId', ParseIntPipe) webinarId: number): Promise<any> {
    try {
      const data = await this.webinarService.getWebinarById(webinarId);
      if (!data.webinar) throw new HttpException('Webinar not found', HttpStatus.NOT_FOUND);
      return data;
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to fetch webinar',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post()
  async createWebinar(
    @Body() body: {
      title: string;
      description?: string;
      organizerUserId: number;
      companyId: number;
      companyName: string;
      timezone?: string;
      invitationHtml?: string;
      slots: Array<{ slotDateTime: string; capacity: number; meetingLink?: string; durationMinutes?: number }>;
    },
  ): Promise<any> {
    try {
      if (!body.title) throw new HttpException('title is required', HttpStatus.BAD_REQUEST);
      if (!body.companyId) throw new HttpException('companyId is required', HttpStatus.BAD_REQUEST);
      if (!body.organizerUserId) throw new HttpException('organizerUserId is required', HttpStatus.BAD_REQUEST);
      if (!body.slots || body.slots.length === 0) throw new HttpException('At least one slot is required', HttpStatus.BAD_REQUEST);

      const webinar = await this.webinarService.createWebinar(
        body.title,
        body.description ?? null,
        body.organizerUserId,
        body.companyId,
        body.companyName,
        body.slots,
        body.timezone ?? 'UTC',
        body.invitationHtml ?? null,
      );
      return { success: true, data: webinar };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to create webinar',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Put(':webinarId')
  async updateWebinar(
    @Param('webinarId', ParseIntPipe) webinarId: number,
    @Body() body: {
      title?: string;
      description?: string;
      organizerUserId?: number;
      companyId?: number;
      isActive?: boolean;
      timezone?: string;
      slots?: Array<{ slotId?: number; slotDateTime: string; capacity: number; meetingLink?: string; durationMinutes?: number }>;
    },
  ): Promise<any> {
    try {
      const result = await this.webinarService.updateWebinar(
        webinarId,
        body.title,
        body.description,
        body.organizerUserId,
        body.companyId,
        body.isActive,
        body.slots,
        body.timezone,
      );
      return { success: true, data: result };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to update webinar',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Patch(':webinarId/invitation-html')
  async patchInvitationHtml(
    @Param('webinarId', ParseIntPipe) webinarId: number,
    @Body() body: { invitationHtml: string | null },
  ): Promise<any> {
    try {
      const result = await this.webinarService.patchInvitationHtml(webinarId, body.invitationHtml ?? null);
      return { success: true, data: result };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to update invitation HTML',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Patch(':webinarId/post-form-token')
  async patchPostFormToken(
    @Param('webinarId', ParseIntPipe) webinarId: number,
    @Body() body: { postWebinarFormToken: string },
  ): Promise<any> {
    try {
      if (!body.postWebinarFormToken) throw new HttpException('postWebinarFormToken is required', HttpStatus.BAD_REQUEST);
      const result = await this.webinarService.patchPostWebinarFormToken(webinarId, body.postWebinarFormToken);
      return { success: true, data: result };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to update post-webinar form token',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Delete(':webinarId')
  async deleteWebinar(@Param('webinarId', ParseIntPipe) webinarId: number): Promise<any> {
    try {
      await this.webinarService.deleteWebinar(webinarId);
      return { success: true };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to delete webinar',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post(':webinarId/send-feedback-email')
  async sendFeedbackEmails(
    @Param('webinarId', ParseIntPipe) webinarId: number,
    @Body() body: { recipients: Array<{ contactEmail: string; businessName: string }> },
  ): Promise<any> {
    try {
      if (!body.recipients || body.recipients.length === 0) {
        throw new HttpException('At least one recipient is required', HttpStatus.BAD_REQUEST);
      }
      const sent = await this.webinarService.sendFeedbackEmails(webinarId, body.recipients);
      return { success: true, sent };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to send feedback emails',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  // ── Public endpoints (token-auth guarded) ────────────────────────────────

  @Get('public/booking-form/:tokenKey')
  async getPublicBookingForm(@Param('tokenKey') tokenKey: string): Promise<any> {
    try {
      const data = await this.webinarService.getPublicBookingForm(tokenKey);
      if (!data) throw new HttpException('Invalid or expired webinar token', HttpStatus.NOT_FOUND);
      return data;
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to load booking form',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get('public/resolve-wid/:tokenKey')
  async resolveWid(@Param('tokenKey') tokenKey: string): Promise<any> {
    try {
      const data = await this.webinarService.resolveWidToken(tokenKey);
      if (!data) throw new HttpException('Invalid webinar token', HttpStatus.NOT_FOUND);
      return data;
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to resolve wid token',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post('public/bookings')
  @UseGuards(TokenAuthGuard)
  async createBooking(
    @Body() body: {
      slotId: number;
      businessName: string;
      contactEmail: string;
    },
    @Req() req: any,
  ): Promise<any> {
    try {
      if (!body.slotId) throw new HttpException('slotId is required', HttpStatus.BAD_REQUEST);
      if (!body.businessName) throw new HttpException('businessName is required', HttpStatus.BAD_REQUEST);
      if (!body.contactEmail) throw new HttpException('contactEmail is required', HttpStatus.BAD_REQUEST);

      const validatedToken = req.validatedToken;
      let props: { companyId?: number; webinarId?: number; companyName?: string } = {};
      try {
        props = validatedToken.properties ? JSON.parse(validatedToken.properties) : {};
      } catch {
        props = {};
      }

      if (!props.webinarId) throw new HttpException('Invalid webinar token', HttpStatus.BAD_REQUEST);

      const booking = await this.webinarService.createBooking(
        validatedToken.tokenKey,
        body.slotId,
        body.businessName,
        body.contactEmail,
        props.webinarId,
        props.companyId,
      );

      // Queue notification emails (non-blocking)
      if (booking) {
        // Attendee confirmation — unique per-booking ICS UID
        this.webinarService.queueBookingConfirmation(
          body.contactEmail,
          booking.webinarTitle || '',
          body.businessName,
          booking.slotDateTime,
          '',
          booking.meetingLink ?? null,
          booking.organizerEmail ?? null,
          booking.organizerName ?? null,
          booking.slotId ?? null,
          booking.bookingId ?? null,
          booking.webinarTimezone ?? 'UTC',
          booking.durationMinutes ?? 45,
        ).catch(() => {});

        // Organizer notification — fetch ALL confirmed bookings for the slot so the ICS
        // contains the full guest list and SEQUENCE increments with each new booking.
        if (booking.organizerEmail) {
          (async () => {
            try {
              const slotBookings = await this.webinarService.getBookingsForSlot(booking.slotId);
              const allSlotAttendees = slotBookings.map((b: any) => ({
                email: b.contactEmail,
                name:  b.businessName,
              }));
              await this.webinarService.queueOrganizerNotification(
                booking.organizerEmail,
                booking.webinarTitle || '',
                body.businessName,
                body.contactEmail,
                booking.slotDateTime,
                booking.organizerName ?? null,
                booking.slotId ?? null,
                booking.bookingId ?? null,
                booking.meetingLink ?? null,
                booking.webinarTimezone ?? 'UTC',
                allSlotAttendees,
                booking.bookedCount ?? 1,
              );
            } catch {}
          })();
        }
      }

      return { success: true, data: booking };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to create booking',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  // ── Invitation endpoints ─────────────────────────────────────────────

  @Get(':webinarId/suppliers/:companyId')
  async getWebinarSuppliers(
    @Param('webinarId', ParseIntPipe) webinarId: number,
    @Param('companyId', ParseIntPipe) companyId: number,
    @Req() req: any,
  ): Promise<any> {
    try {
      const certId = req.query.certId ? parseInt(req.query.certId, 10) : null;
      const data = await this.webinarService.getWebinarSuppliers(webinarId, companyId, certId);
      return { success: true, data };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to fetch webinar suppliers',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Get(':webinarId/invitations')
  async getInvitations(@Param('webinarId', ParseIntPipe) webinarId: number): Promise<any> {
    try {
      const data = await this.webinarService.getInvitations(webinarId);
      return { success: true, data };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to fetch invitations',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  @Post(':webinarId/send-invitation')
  async sendInvitationEmails(
    @Param('webinarId', ParseIntPipe) webinarId: number,
    @Body() body: { recipients: Array<{ supplierId: number; supplierName: string; supplierEmail: string }> },
  ): Promise<any> {
    try {
      if (!body.recipients || body.recipients.length === 0) {
        throw new HttpException('At least one recipient is required', HttpStatus.BAD_REQUEST);
      }
      const result = await this.webinarService.sendInvitationEmails(webinarId, body.recipients);
      return { success: true, ...result };
    } catch (error: any) {
      throw new HttpException(
        error.message || 'Failed to send invitation emails',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}

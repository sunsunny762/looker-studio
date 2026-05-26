export interface Webinar {
  webinarId: number;
  title: string;
  description: string | null;
  organizerUserId: number;
  companyId: number;
  tokenKey: string | null;
  postWebinarFormToken: string | null;
  isActive: boolean;
  timezone: string;
  createdAt: Date;
  updatedAt: Date;
  totalBookings?: number;
  totalCapacity?: number;
  slotCount?: number;
  slots?: WebinarSlot[];
  bookings?: WebinarBooking[];
}

export interface WebinarSlot {
  slotId: number;
  webinarId: number;
  slotDateTime: Date;
  capacity: number;
  bookedCount: number;
  meetingLink?: string | null;
  durationMinutes?: number;
  remaining?: number;
  isFull?: boolean;
}

export interface WebinarBooking {
  bookingId: number;
  webinarId: number;
  slotId: number;
  companyId: number;
  businessName: string;
  contactEmail: string;
  status: string;
  reminderSent: boolean;
  createdAt: Date;
  tokenKey: string | null;
  slotDateTime?: Date;
  capacity?: number;
  bookedCount?: number;
  meetingLink?: string | null;
  isInvited?: boolean;
}

export interface WebinarInvitation {
  invitationId: number;
  webinarId: number;
  supplierId: number;
  supplierName: string;
  supplierEmail: string;
  certId?: number | null;
  invitedAt: Date;
  bookingId?: number | null;
  bookingStatus?: string | null;
  slotDateTime?: Date | null;
  isBooked: boolean;
}

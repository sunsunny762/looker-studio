/**
 * Payment gateway abstraction interface.
 * Implement this interface to add a new payment gateway in the future
 * without changing CartService or any other consumer.
 */
export interface IPaymentGateway {
  readonly gatewayName: string;

  /**
   * Creates a hosted checkout session.
   * @returns sessionUrl — redirect the browser here to start payment
   *          sessionId  — stored in FormCartPayments for later lookup
   */
  createCheckoutSession(params: CreateSessionParams): Promise<CreateSessionResult>;

  /**
   * Retrieves the current status of a session (used on the return redirect).
   */
  verifySession(sessionId: string): Promise<VerifySessionResult>;

  /**
   * Parses and validates an incoming webhook payload.
   * Throws if the signature is invalid (prevents replay attacks).
   */
  constructWebhookEvent(rawBody: Buffer, signature: string): Promise<WebhookEvent>;
}

export interface LineItem {
  name: string;
  description?: string;
  unitAmount: number;   // in smallest currency unit (e.g. pence)
  quantity: number;
  currency: string;
}

export interface CreateSessionParams {
  submissionId: number;
  formId: number;
  cartConfigId: number;
  currency: string;
  lineItems: LineItem[];
  discountAmount: number;     // already subtracted from totalAmount on Stripe side via coupon or line item
  taxAmount: number;          // in smallest currency unit; added as a separate line item
  taxLabel?: string;          // e.g. 'VAT (20%)'
  totalAmount: number;        // in smallest currency unit
  successUrl: string;
  cancelUrl: string;
  returnUrl?: string;         // URL to redirect the user to after payment (same-origin validated)
  metadata?: Record<string, string>;
}

export interface CreateSessionResult {
  sessionId: string;
  sessionUrl: string;
}

export interface VerifySessionResult {
  sessionId: string;
  paymentIntentId?: string;
  status: 'pending' | 'paid' | 'failed' | 'refunded';
  amountTotal: number;        // in smallest currency unit
  currency: string;
  paidAt?: Date;
}

export interface WebhookEvent {
  eventId: string;
  eventType: string;
  sessionId?: string;
  paymentIntentId?: string;
  rawData: any;
}

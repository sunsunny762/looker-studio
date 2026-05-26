import { Injectable, Logger } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { NczformsService } from '../nczforms/nczforms.service';
import { PaymentGatewayFactory } from './gateways/payment-gateway.factory';
import { LineItem } from './gateways/payment-gateway.interface';
import { CartDataDto, CreateCheckoutSessionDto, ValidateCouponDto } from './cart.dto';

@Injectable()
export class CartService {
  private readonly logger = new Logger(CartService.name);

  constructor(
    private readonly databaseService: DatabaseService,
    private readonly errorLoggerService: ErrorLoggerService,
    private readonly nczformsService: NczformsService,
    private readonly gatewayFactory: PaymentGatewayFactory,
  ) {}

  // ---------------------------------------------------------------------------
  // Coupon validation
  // ---------------------------------------------------------------------------

  async validateCoupon(dto: ValidateCouponDto) {
    try {
      const result = await this.databaseService.execute(
        '[portal].[spFormCartCoupon_Validate]',
        [
          { name: 'cartConfigId', type: mssql.TYPES.Int, value: dto.cartConfigId },
          { name: 'couponCode',   type: mssql.TYPES.NVarChar, value: dto.couponCode.trim() },
          { name: 'orderAmount',  type: mssql.TYPES.Decimal, value: dto.orderAmount },
        ],
      );
      return result.singleResult;
    } catch (error) {
      this.logger.error('validateCoupon failed', error);
      throw error;
    }
  }

  // ---------------------------------------------------------------------------
  // Cart configuration (without coupon codes)
  // ---------------------------------------------------------------------------

  async getCartConfig(cartConfigId?: number, questionId?: number) {
    try {
      const result = await this.databaseService.execute(
        '[portal].[spFormCartConfig_Get]',
        [
          { name: 'cartConfigId', type: mssql.TYPES.Int, value: cartConfigId ?? null },
          { name: 'questionId',   type: mssql.TYPES.Int, value: questionId ?? null },
        ],
      );
      // First recordset = config row; second = items
      const configs = result.recordsets?.[0] ?? result.results;
      const items   = result.recordsets?.[1] ?? [];
      if (!configs?.length) return null;
      return { ...configs[0], items: items ?? [] };
    } catch (error) {
      this.logger.error('getCartConfig failed', error);
      throw error;
    }
  }

  // ---------------------------------------------------------------------------
  // Checkout session creation
  // ---------------------------------------------------------------------------

  async createCheckoutSession(dto: CreateCheckoutSessionDto) {
    const { formId, submissionId, userId, cartData, returnBaseUrl, cartConfigId, returnUrl } = dto;

    // Derive the gateway from the cart config
    const cartConfig = await this.getCartConfig(cartConfigId);
    const gatewayName = cartConfig?.paymentGateway ?? 'stripe';
    const gateway = this.gatewayFactory.getGateway(gatewayName);

    // Build line items (prices in smallest unit, e.g. pence = amount * 100)
    const multiplier = 100; // assumes 2 decimal places for all supported currencies
    const lineItems: LineItem[] = cartData.items.map(item => ({
      name: item.itemLabel,
      unitAmount: Math.round(item.unitPrice * multiplier),
      quantity: item.quantity,
      currency: item.currency ?? cartData.currency,
    }));

    const totalAmount = Math.round(cartData.totalPayable * multiplier);
    const discountAmount = Math.round(cartData.discountAmount * multiplier);
    const subtotalAmount = Math.round(cartData.subtotal * multiplier);
    const taxAmount = Math.round((cartData.taxAmount ?? 0) * multiplier);

    const successUrl = `${returnBaseUrl}/payment/success`;

    // Validate returnUrl is same-origin as returnBaseUrl before passing to gateway
    let safeReturnUrl: string | undefined;
    if (returnUrl) {
      try {
        const baseOrigin = new URL(returnBaseUrl).origin;
        const returnOrigin = new URL(returnUrl).origin;
        safeReturnUrl = returnOrigin === baseOrigin ? returnUrl : undefined;
      } catch {
        safeReturnUrl = undefined;
      }
    }

    // Embed returnUrl in cancel_url so the cancel page can navigate back to the form
    const cancelUrl = safeReturnUrl
      ? `${returnBaseUrl}/payment/cancel?formId=${formId}&submissionId=${submissionId}&returnUrl=${encodeURIComponent(safeReturnUrl)}`
      : `${returnBaseUrl}/payment/cancel?formId=${formId}&submissionId=${submissionId}`;

    const sessionResult = await gateway.createCheckoutSession({
      submissionId,
      formId,
      cartConfigId: cartConfig?.cartConfigId ?? 0,
      currency: cartData.currency,
      lineItems,
      discountAmount,
      taxAmount,
      taxLabel: cartConfig?.taxLabel,
      totalAmount,
      successUrl,
      cancelUrl,
      returnUrl: safeReturnUrl,
      metadata: {
        couponCode: cartData.couponCode ?? '',
      },
    });

    // Persist the payment record
    await this.savePaymentRecord({
      submissionId,
      formId,
      userId,
      gateway: gatewayName,
      gatewaySessionId: sessionResult.sessionId,
      currency: cartData.currency,
      subtotalAmount: cartData.subtotal,
      taxAmount: cartData.taxAmount ?? 0,
      discountAmount: cartData.discountAmount,
      totalAmount: cartData.totalPayable,
      couponCode: cartData.couponCode,
      status: 'pending',
    });

    // Update submission status to pending-payment (status=2)
    await this.nczformsService.saveFormSubmission(
      formId,
      submissionId,
      userId ?? 0,
      [],
      dto.formData,
      true, // isDraft=true; status will be 2 after webhook confirms
    );

    return sessionResult;
  }

  // ---------------------------------------------------------------------------
  // Session verification (used on success redirect)
  // ---------------------------------------------------------------------------

  async verifySession(sessionId: string) {
    // Find the payment record to know which gateway to use
    const payment = await this.getPaymentBySession(sessionId);
    const gatewayName = payment?.gateway ?? 'stripe';
    const gateway = this.gatewayFactory.getGateway(gatewayName);

    const result = await gateway.verifySession(sessionId);

    // Update payment record
    await this.savePaymentRecord({
      submissionId: payment?.submissionId,
      formId: payment?.formId,
      userId: payment?.userId,
      gateway: gatewayName,
      gatewaySessionId: sessionId,
      gatewayPaymentIntentId: result.paymentIntentId,
      currency: result.currency,
      subtotalAmount: payment?.subtotalAmount,
      taxAmount: payment?.taxAmount,
      discountAmount: payment?.discountAmount,
      totalAmount: result.amountTotal / 100,
      couponCode: payment?.couponCode,
      status: result.status,
      paidAt: result.paidAt ? result.paidAt.toISOString() : null,
    });

    // Mark submission as submitted immediately on successful redirect verify.
    // This covers local dev (no webhook) and any timing race with the webhook.
    if (result.status === 'paid' && payment?.submissionId) {
      await this.databaseService.execute('[portal].[spFormSubmission_UpdateStatus]', [
        { name: 'submissionId', type: mssql.TYPES.Int, value: payment.submissionId },
        { name: 'status',       type: mssql.TYPES.Int, value: 1 },
      ]);
    }

    return {
      status: result.status,
      paymentId: payment?.paymentId,
      submissionId: payment?.submissionId,
      currency: result.currency,
      totalAmount: result.amountTotal / 100,
      discountAmount: payment?.discountAmount,
      paidAt: result.paidAt?.toISOString(),
      gatewaySessionId: sessionId,
      gatewayPaymentIntentId: result.paymentIntentId,
    };
  }

  // ---------------------------------------------------------------------------
  // Stripe webhook handler
  // ---------------------------------------------------------------------------

  async handleStripeWebhook(rawBody: Buffer, signature: string) {
    const gateway = this.gatewayFactory.getGateway('stripe');
    const event = await gateway.constructWebhookEvent(rawBody, signature);

    // Idempotency: check if we already processed this event
    const alreadyProcessed = await this.isEventProcessed(event.eventId);
    if (alreadyProcessed) {
      this.logger.log(`Stripe event ${event.eventId} already processed — skipping`);
      return { received: true };
    }

    if (event.eventType === 'checkout.session.completed' && event.sessionId) {
      await this.onPaymentSuccess(event.sessionId, event.paymentIntentId, event.eventId, event.rawData);
    } else if (event.eventType === 'checkout.session.expired' && event.sessionId) {
      await this.onPaymentFailed(event.sessionId, event.eventId);
    }

    return { received: true };
  }

  private async onPaymentSuccess(
    sessionId: string,
    paymentIntentId: string | undefined,
    eventId: string,
    rawData: any,
  ) {
    const payment = await this.getPaymentBySession(sessionId);
    if (!payment) {
      this.logger.warn(`Payment record not found for session ${sessionId}`);
      return;
    }

    // Mark payment as paid
    await this.savePaymentRecord({
      ...payment,
      gatewayPaymentIntentId: paymentIntentId,
      status: 'paid',
      paidAt: new Date().toISOString(),
      gatewayEventId: eventId,
      gatewayResponse: JSON.stringify(rawData),
    });

    // Mark submission as submitted (status=1) without overwriting form data
    await this.databaseService.execute('[portal].[spFormSubmission_UpdateStatus]', [
      { name: 'submissionId', type: mssql.TYPES.Int, value: payment.submissionId },
      { name: 'status',       type: mssql.TYPES.Int, value: 1 },
    ]);

    // Increment coupon usedCount if applicable
    if (payment.couponCode && payment.cartConfigId) {
      await this.databaseService.execute('[portal].[spFormCartCoupon_IncrementUsedCount]', [
        { name: 'cartConfigId', type: mssql.TYPES.Int,     value: payment.cartConfigId },
        { name: 'couponCode',   type: mssql.TYPES.NVarChar, value: payment.couponCode },
      ]);
    }

    this.logger.log(`Payment confirmed for submission ${payment.submissionId}, session ${sessionId}`);
  }

  private async onPaymentFailed(sessionId: string, eventId: string) {
    await this.updatePaymentStatus(sessionId, 'failed', eventId);
    this.logger.warn(`Payment failed/expired for session ${sessionId}`);
  }

  // ---------------------------------------------------------------------------
  // Database helpers
  // ---------------------------------------------------------------------------

  private async savePaymentRecord(params: {
    submissionId?: number;
    formId?: number;
    userId?: number | null;
    gateway?: string;
    gatewaySessionId: string;
    gatewayPaymentIntentId?: string;
    currency?: string;
    subtotalAmount?: number;
    taxAmount?: number;
    discountAmount?: number;
    totalAmount?: number;
    couponCode?: string;
    status: string;
    paidAt?: string | null;
    gatewayEventId?: string;
    gatewayResponse?: string;
    cartConfigId?: number;
  }) {
    await this.databaseService.execute('[portal].[spFormCartPayment_Save]', [
      { name: 'submissionId',           type: mssql.TYPES.Int,      value: params.submissionId ?? null },
      { name: 'formId',                 type: mssql.TYPES.Int,      value: params.formId ?? null },
      { name: 'userId',                 type: mssql.TYPES.Int,      value: params.userId ?? null },
      { name: 'gateway',                type: mssql.TYPES.NVarChar, value: params.gateway ?? 'stripe' },
      { name: 'gatewaySessionId',       type: mssql.TYPES.NVarChar, value: params.gatewaySessionId },
      { name: 'gatewayPaymentIntentId', type: mssql.TYPES.NVarChar, value: params.gatewayPaymentIntentId ?? null },
      { name: 'currency',               type: mssql.TYPES.NVarChar, value: params.currency ?? 'GBP' },
      { name: 'subtotalAmount',         type: mssql.TYPES.Decimal,  value: params.subtotalAmount ?? 0 },
      { name: 'taxAmount',              type: mssql.TYPES.Decimal,  value: params.taxAmount ?? 0 },
      { name: 'discountAmount',         type: mssql.TYPES.Decimal,  value: params.discountAmount ?? 0 },
      { name: 'totalAmount',            type: mssql.TYPES.Decimal,  value: params.totalAmount ?? 0 },
      { name: 'couponCode',             type: mssql.TYPES.NVarChar, value: params.couponCode ?? null },
      { name: 'status',                 type: mssql.TYPES.NVarChar, value: params.status },
      { name: 'paidAt',                 type: mssql.TYPES.DateTime2, value: params.paidAt ? new Date(params.paidAt) : null },
      { name: 'gatewayEventId',         type: mssql.TYPES.NVarChar, value: params.gatewayEventId ?? null },
      { name: 'gatewayResponse',        type: mssql.TYPES.NVarChar, value: params.gatewayResponse ?? null },
    ]);
  }

  private async updatePaymentStatus(sessionId: string, status: string, eventId?: string) {
    await this.databaseService.execute('[portal].[spFormCartPayment_Save]', [
      { name: 'submissionId',           type: mssql.TYPES.Int,      value: null },
      { name: 'formId',                 type: mssql.TYPES.Int,      value: null },
      { name: 'userId',                 type: mssql.TYPES.Int,      value: null },
      { name: 'gateway',                type: mssql.TYPES.NVarChar, value: 'stripe' },
      { name: 'gatewaySessionId',       type: mssql.TYPES.NVarChar, value: sessionId },
      { name: 'gatewayPaymentIntentId', type: mssql.TYPES.NVarChar, value: null },
      { name: 'currency',               type: mssql.TYPES.NVarChar, value: null },
      { name: 'subtotalAmount',         type: mssql.TYPES.Decimal,  value: 0 },
      { name: 'taxAmount',              type: mssql.TYPES.Decimal,  value: 0 },
      { name: 'discountAmount',         type: mssql.TYPES.Decimal,  value: 0 },
      { name: 'totalAmount',            type: mssql.TYPES.Decimal,  value: 0 },
      { name: 'couponCode',             type: mssql.TYPES.NVarChar, value: null },
      { name: 'status',                 type: mssql.TYPES.NVarChar, value: status },
      { name: 'paidAt',                 type: mssql.TYPES.DateTime2, value: null },
      { name: 'gatewayEventId',         type: mssql.TYPES.NVarChar, value: eventId ?? null },
      { name: 'gatewayResponse',        type: mssql.TYPES.NVarChar, value: null },
    ]);
  }

  private async getPaymentBySession(sessionId: string) {
    try {
      const result = await this.databaseService.execute(
        '[portal].[spFormCartPayment_GetBySession]',
        [{ name: 'gatewaySessionId', type: mssql.TYPES.NVarChar, value: sessionId }],
      );
      return result.singleResult ?? null;
    } catch {
      return null;
    }
  }

  async getPaymentBySubmission(submissionId: number) {
    try {
      const result = await this.databaseService.execute(
        '[portal].[spFormCartPayment_GetBySubmission]',
        [{ name: 'submissionId', type: mssql.TYPES.Int, value: submissionId }],
      );
      return result.singleResult ?? null;
    } catch {
      return null;
    }
  }

  private async isEventProcessed(eventId: string): Promise<boolean> {
    try {
      // Stripe event IDs are alphanumeric with underscores/hyphens — sanitise before embedding in query
      const safeEventId = eventId.replace(/[^a-zA-Z0-9_\-]/g, '');
      const result = await this.databaseService.query(
        `SELECT 1 AS found FROM [portal].[FormCartPayments] WHERE gatewayEventId = '${safeEventId}'`,
      );
      return !!(result.singleResult?.found);
    } catch {
      return false;
    }
  }

}

import { Injectable, Logger } from '@nestjs/common';
import Stripe from 'stripe';
import {
  IPaymentGateway,
  CreateSessionParams,
  CreateSessionResult,
  VerifySessionResult,
  WebhookEvent,
} from './payment-gateway.interface';

@Injectable()
export class StripePaymentGateway implements IPaymentGateway {
  readonly gatewayName = 'stripe';

  private readonly logger = new Logger(StripePaymentGateway.name);
  private readonly stripe: Stripe;
  private readonly webhookSecret: string;

  constructor() {
    const secretKey = process.env.STRIPE_SECRET_KEY;
    if (!secretKey) {
      throw new Error('STRIPE_SECRET_KEY environment variable is not set.');
    }
    this.webhookSecret = process.env.STRIPE_WEBHOOK_SECRET ?? '';
    this.stripe = new Stripe(secretKey, { apiVersion: '2026-03-25.dahlia' });
  }

  async createCheckoutSession(params: CreateSessionParams): Promise<CreateSessionResult> {
    const lineItems: Stripe.Checkout.SessionCreateParams.LineItem[] = params.lineItems.map(item => ({
      price_data: {
        currency: params.currency.toLowerCase(),
        product_data: {
          name: item.name,
          ...(item.description ? { description: item.description } : {}),
        },
        unit_amount: item.unitAmount,
      },
      quantity: item.quantity,
    }));

    // If there is a discount, add a negative line item so the total matches
    if (params.discountAmount > 0) {
      lineItems.push({
        price_data: {
          currency: params.currency.toLowerCase(),
          product_data: { name: 'Discount' },
          unit_amount: -params.discountAmount,
        },
        quantity: 1,
      });
    }

    // If there is tax, add it as a separate line item so the Stripe total matches
    if (params.taxAmount > 0) {
      lineItems.push({
        price_data: {
          currency: params.currency.toLowerCase(),
          product_data: { name: params.taxLabel ?? 'Tax' },
          unit_amount: params.taxAmount,
        },
        quantity: 1,
      });
    }

    const session = await this.stripe.checkout.sessions.create({
      mode: 'payment',
      payment_method_types: ['card'],
      line_items: lineItems,
      success_url: params.returnUrl
        ? `${params.successUrl}?returnUrl=${encodeURIComponent(params.returnUrl)}&session_id={CHECKOUT_SESSION_ID}`
        : `${params.successUrl}?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: params.cancelUrl,
      metadata: {
        submissionId: String(params.submissionId),
        formId: String(params.formId),
        cartConfigId: String(params.cartConfigId),
        ...params.metadata,
      },
    });

    return { sessionId: session.id, sessionUrl: session.url! };
  }

  async verifySession(sessionId: string): Promise<VerifySessionResult> {
    const session = await this.stripe.checkout.sessions.retrieve(sessionId);

    let status: VerifySessionResult['status'] = 'pending';
    if (session.payment_status === 'paid') {
      status = 'paid';
    } else if (session.status === 'expired') {
      status = 'failed';
    }

    return {
      sessionId: session.id,
      paymentIntentId: session.payment_intent as string | undefined,
      status,
      amountTotal: session.amount_total ?? 0,
      currency: session.currency?.toUpperCase() ?? 'GBP',
      paidAt: status === 'paid' ? new Date() : undefined,
    };
  }

  async constructWebhookEvent(rawBody: Buffer, signature: string): Promise<WebhookEvent> {
    if (!this.webhookSecret) {
      throw new Error('STRIPE_WEBHOOK_SECRET environment variable is not set.');
    }

    let event: Stripe.Event;
    try {
      event = this.stripe.webhooks.constructEvent(rawBody, signature, this.webhookSecret);
    } catch (err) {
      this.logger.error('Stripe webhook signature verification failed', err);
      throw err;
    }

    const session =
      event.type === 'checkout.session.completed' ||
      event.type === 'checkout.session.expired'
        ? (event.data.object as Stripe.Checkout.Session)
        : undefined;

    return {
      eventId: event.id,
      eventType: event.type,
      sessionId: session?.id,
      paymentIntentId: session?.payment_intent as string | undefined,
      rawData: event,
    };
  }
}

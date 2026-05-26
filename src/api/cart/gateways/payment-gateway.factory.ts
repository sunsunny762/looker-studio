import { Injectable } from '@nestjs/common';
import { IPaymentGateway } from './payment-gateway.interface';
import { StripePaymentGateway } from './stripe-payment.gateway';

/**
 * Resolves the correct IPaymentGateway implementation by gateway name.
 * Add new cases here when integrating additional payment providers.
 */
@Injectable()
export class PaymentGatewayFactory {
  constructor(private readonly stripeGateway: StripePaymentGateway) {}

  getGateway(gatewayName: string): IPaymentGateway {
    switch (gatewayName.toLowerCase()) {
      case 'stripe':
        return this.stripeGateway;
      default:
        throw new Error(`Unsupported payment gateway: "${gatewayName}"`);
    }
  }
}

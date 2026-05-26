import { Module } from '@nestjs/common';
import { CartController } from './cart.controller';
import { CartService } from './cart.service';
import { StripePaymentGateway } from './gateways/stripe-payment.gateway';
import { PaymentGatewayFactory } from './gateways/payment-gateway.factory';
import { DatabaseModule } from '../../database/database.module';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { NczformsModule } from '../nczforms/nczforms.module';

@Module({
  imports: [
    DatabaseModule,
    ErrorLoggerModule,
    NczformsModule,
  ],
  controllers: [CartController],
  providers: [
    CartService,
    StripePaymentGateway,
    PaymentGatewayFactory,
  ],
  exports: [CartService],
})
export class CartModule {}

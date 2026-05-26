import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Req,
  Res,
  HttpCode,
  HttpStatus,
  Headers,
  RawBodyRequest,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { CartService } from './cart.service';
import { ValidateCouponDto, CreateCheckoutSessionDto } from './cart.dto';

/**
 * CartController — handles all cart/payment endpoints.
 *
 * Routes are mounted at /cart and /public/cart (public routes added via
 * preAuthExcludes in app.module.ts where needed for guest checkout).
 */
@Controller('cart')
export class CartController {
  private readonly logger = new Logger(CartController.name);

  constructor(private readonly cartService: CartService) {}

  // ---------------------------------------------------------------------------
  // Coupon validation (server-side — coupon details never exposed to client)
  // ---------------------------------------------------------------------------

  @Post('validate-coupon')
  @HttpCode(HttpStatus.OK)
  async validateCoupon(@Body() dto: ValidateCouponDto) {
    if (!dto.cartConfigId || !dto.couponCode) {
      throw new BadRequestException('cartConfigId and couponCode are required.');
    }
    return this.cartService.validateCoupon(dto);
  }

  // ---------------------------------------------------------------------------
  // Cart configuration (items only — NO coupon codes)
  // ---------------------------------------------------------------------------

  @Get('config/:cartConfigId')
  async getCartConfig(@Param('cartConfigId') cartConfigId: string) {
    const id = parseInt(cartConfigId, 10);
    if (isNaN(id)) throw new BadRequestException('Invalid cartConfigId.');
    return this.cartService.getCartConfig(id);
  }

  // ---------------------------------------------------------------------------
  // Checkout session creation
  // ---------------------------------------------------------------------------

  @Post('checkout-session')
  @HttpCode(HttpStatus.OK)
  async createCheckoutSession(@Body() dto: CreateCheckoutSessionDto) {
    if (!dto.formId || !dto.cartData || !dto.returnBaseUrl) {
      throw new BadRequestException('formId, cartData and returnBaseUrl are required.');
    }
    if (!dto.cartData.items?.length) {
      throw new BadRequestException('Cart must contain at least one item.');
    }
    return this.cartService.createCheckoutSession(dto);
  }

  // ---------------------------------------------------------------------------
  // Payment details by submission (used by form view mode)
  // ---------------------------------------------------------------------------

  @Get('payment/submission/:submissionId')
  async getPaymentBySubmission(@Param('submissionId') submissionId: string) {
    const id = parseInt(submissionId, 10);
    if (isNaN(id)) throw new BadRequestException('Invalid submissionId.');
    return this.cartService.getPaymentBySubmission(id);
  }

  // ---------------------------------------------------------------------------
  // Session verification (called after Stripe redirects back)
  // ---------------------------------------------------------------------------

  @Get('session/:sessionId/verify')
  async verifySession(@Param('sessionId') sessionId: string) {
    if (!sessionId?.startsWith('cs_')) {
      throw new BadRequestException('Invalid session ID.');
    }
    return this.cartService.verifySession(sessionId);
  }

  // ---------------------------------------------------------------------------
  // Stripe webhook (raw body required for signature verification)
  // Must be excluded from JSON body parsing middleware — see main.ts note below.
  // ---------------------------------------------------------------------------

  @Post('webhook/stripe')
  @HttpCode(HttpStatus.OK)
  async stripeWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature: string,
  ) {
    if (!signature) {
      throw new BadRequestException('Missing stripe-signature header.');
    }
    const rawBody = req.rawBody;
    if (!rawBody) {
      throw new BadRequestException('Raw body not available. Ensure rawBody is enabled in NestJS bootstrap.');
    }
    return this.cartService.handleStripeWebhook(rawBody, signature);
  }
}

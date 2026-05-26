import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Query,
} from '@nestjs/common';
import { EmailUnsubscriptionService } from './email-unsubscription.service';
import { CreateUnsubscriptionDto } from './email-unsubscription.model';

@Controller('email-unsubscriptions')
export class EmailUnsubscriptionController {
  constructor(private readonly emailUnsubscriptionService: EmailUnsubscriptionService) {}

  /** PUBLIC — Unsubscribe an email address. */
  @Post()
  @HttpCode(HttpStatus.OK)
  async unsubscribe(@Body() body: CreateUnsubscriptionDto) {
    const record = await this.emailUnsubscriptionService.createUnsubscription(
      body.email,
      body.reason,
      body.details ?? null,
    );
    return { success: true, data: record };
  }

  /** PUBLIC — Check the unsubscription status of an email address. */
  @Get('check')
  async check(@Query('email') email: string) {
    const record = await this.emailUnsubscriptionService.checkUnsubscription(email);
    return {
      email,
      isUnsubscribed: record?.isUnsubscribed ?? false,
      data: record ?? null,
    };
  }

  /** PUBLIC — Re-subscribe (user self-service from the unsubscribe page). */
  @Post('resubscribe')
  @HttpCode(HttpStatus.OK)
  async resubscribe(@Body() body: { email: string }) {
    const record = await this.emailUnsubscriptionService.resubscribe(body.email);
    return { success: true, data: record };
  }

  /** AUTHENTICATED — Full list for NCZ admin grid. */
  @Get()
  async getAll() {
    const records = await this.emailUnsubscriptionService.getUnsubscriptions();
    return { success: true, data: records };
  }

  /** AUTHENTICATED — NCZ admin reinstates a specific email address. */
  @Post(':email/reinstate')
  @HttpCode(HttpStatus.OK)
  async reinstate(@Param('email') email: string) {
    const record = await this.emailUnsubscriptionService.resubscribe(
      decodeURIComponent(email),
    );
    return { success: true, data: record };
  }
}

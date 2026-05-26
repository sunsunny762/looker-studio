import { Module } from '@nestjs/common';
import { WebinarController } from './webinar.controller';
import { WebinarService } from './webinar.service';
import { DatabaseModule } from '../../database/database.module';
import { TokenModule } from '../token/token.module';
import { EmailModule } from '../../email/email.module';
import { EmailUnsubscriptionModule } from '../email-unsubscription/email-unsubscription.module';

@Module({
  imports: [DatabaseModule, TokenModule, EmailModule, EmailUnsubscriptionModule],
  controllers: [WebinarController],
  providers: [WebinarService],
  exports: [WebinarService],
})
export class WebinarModule {}

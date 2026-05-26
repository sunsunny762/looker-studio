import { Module } from '@nestjs/common';
import { EmailUnsubscriptionController } from './email-unsubscription.controller';
import { EmailUnsubscriptionService } from './email-unsubscription.service';
import { DatabaseModule } from '../../database/database.module';

@Module({
  imports: [DatabaseModule],
  controllers: [EmailUnsubscriptionController],
  providers: [EmailUnsubscriptionService],
  exports: [EmailUnsubscriptionService],
})
export class EmailUnsubscriptionModule {}

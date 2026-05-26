import { Module } from '@nestjs/common';
import { PowerbiService } from './powerbi.service';
import { ErrorLoggerModule } from '../error-logger/error-logger.module';
import { DatabaseModule } from '../database/database.module';
import { DatabaseService } from '../database/database.service';
import { EmailService } from '../email/email.service';
import { DocumentsModule } from '../documents/documents.module';

@Module({
  imports: [ErrorLoggerModule, DatabaseModule, DocumentsModule],
  providers: [PowerbiService, DatabaseService, EmailService ],
  exports: [PowerbiService],
})
export class PowerbiModule {}

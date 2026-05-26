import { Module } from '@nestjs/common';
import { ReportDataService } from './reportData.service';
import { ErrorLoggerModule } from '../error-logger/error-logger.module';
import { DatabaseModule } from '../database/database.module';
import { EmailService } from '../email/email.service';
import { DocumentsModule } from '../documents/documents.module';

@Module({
  imports: [ErrorLoggerModule, DatabaseModule, DocumentsModule],
  providers: [ReportDataService, EmailService],
  exports: [ReportDataService],
})
export class ReportDataModule {}

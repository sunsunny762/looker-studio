import { Module } from '@nestjs/common';
import { NestjsFormDataModule } from 'nestjs-form-data/dist/nestjs-form-data.module';
import { DocumentsModule } from '../../documents/documents.module';
import { EmailService } from '../../email/email.service';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { DatabaseModule } from '../../database/database.module';
import { JotformModule } from '../../jotform/jotoform.module';
import { CompanyModule } from '../company/company.module';
// import { ReportAdminService } from './report-admin.service';
import { ReportController } from './report.controller';
import { ReportService } from './report.service';

@Module({
    imports: [
        NestjsFormDataModule,
        DatabaseModule,
        ErrorLoggerModule,
        CompanyModule,
        JotformModule,
        DocumentsModule
    ],
    controllers: [ReportController],
    providers: [ReportService, /* ReportAdminService, */ EmailService],
    exports: [ReportService],
})
export class ReportModule {}

import { Module } from '@nestjs/common';
import { NestjsFormDataModule } from 'nestjs-form-data/dist/nestjs-form-data.module';
import { CertificationController } from './certification.controller';
import { CertificationService } from './certification.service';
import { DatabaseService } from '../../database';
import { DatabaseModule } from '../../database/database.module';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { CompanyModule } from '../company/company.module';
import { JotformModule } from '../../jotform/jotoform.module';
import { DocumentsModule } from '../../documents/documents.module';
import { NotificationsModule } from '../../notifications/notifications.module';
import { TokenModule } from '../token/token.module';
import { TokenAuthGuard } from '../token/guards/token-auth.guard';

@Module({
    imports: [
        NestjsFormDataModule, 
        DatabaseModule, 
        ErrorLoggerModule,
        CompanyModule,
        JotformModule,
        DocumentsModule,
        NotificationsModule,
        TokenModule
    ],
    controllers: [CertificationController],
    providers: [CertificationService],
    exports: [CertificationService],
})
export class CertificationModule {}

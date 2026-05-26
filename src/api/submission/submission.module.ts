import { Module } from '@nestjs/common';
import { NestjsFormDataModule } from 'nestjs-form-data/dist/nestjs-form-data.module';
import { SubmissionController } from './submission.controller';
import { PublicSubmissionsController } from './public-submissions.controller';
import { SubmissionService } from './submission.service';
import { DatabaseService } from '../../database';
import { DatabaseModule } from '../../database/database.module';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { CompanyModule } from '../company/company.module';
import { JotformModule } from '../../jotform/jotoform.module';
import { FirebaseService } from '../../firebase.service';
import { FirebaseAuthService } from '../../firebase/firebase-auth.service';
import { FirebaseAdminService } from '../../firebase/firebase-admin.service';
import { TokenModule } from '../token/token.module';
import { TokenAuthGuard } from '../token/guards/token-auth.guard';
import { NczformsModule } from '../nczforms/nczforms.module';
import { NotificationsModule } from '../../notifications/notifications.module';
import { CertificationModule } from '../certification/certification.module';
import { CartModule } from '../cart/cart.module';
import { DocumentsModule } from '../../documents/documents.module';

@Module({
    imports: [
        NestjsFormDataModule, 
        DatabaseModule, 
        ErrorLoggerModule,
        CompanyModule,
        JotformModule,
        TokenModule,
        NczformsModule,
        NotificationsModule,
        CertificationModule,
        CartModule,
        DocumentsModule
    ],
    controllers: [SubmissionController, PublicSubmissionsController],
    providers: [SubmissionService, FirebaseAuthService, FirebaseAdminService, TokenAuthGuard],
    exports: [SubmissionService],
})
export class SubmissionModule {}

import { Module } from '@nestjs/common';
import { PublicFormsController } from './public-forms.controller';
import { PublicFormTokenController } from './public-form-token.controller';
import { PublicFormsService } from './public-forms.service';
import { DatabaseModule } from '../../database/database.module';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { TokenModule } from '../token/token.module';
import { FirebaseAdminService } from '../../firebase/firebase-admin.service';
import { DocumentsModule } from '../../documents/documents.module';

@Module({
    imports: [
        DatabaseModule,
        ErrorLoggerModule,
        TokenModule,
        DocumentsModule,
    ],
    controllers: [PublicFormsController, PublicFormTokenController],
    providers: [PublicFormsService, FirebaseAdminService],
    exports: [PublicFormsService],
})
export class PublicFormsModule {}

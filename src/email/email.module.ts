import { Module } from '@nestjs/common';
import { EmailService } from './email.service';
import { DatabaseModule } from '../database/database.module'; //' 'src/database/database.module';
import { UserService } from '../api/user/user.service'; //' 'src/api/user/user.service';
import { ErrorLoggerModule } from '../error-logger/error-logger.module'; //' 'src/error-logger/error-logger.module';
import { FirebaseAuthService } from '../firebase/firebase-auth.service'; //' 'src/firebase/firebase-auth.service';
import { FirebaseAdminService } from '../firebase/firebase-admin.service'; //' 'src/firebase/firebase-admin.service';


@Module({
    imports: [
        DatabaseModule,
        ErrorLoggerModule
    ],
    providers: [EmailService, UserService, FirebaseAuthService, FirebaseAdminService],
    exports: [EmailService],
})
export class EmailModule { }

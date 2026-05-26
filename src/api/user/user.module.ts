import { Module } from '@nestjs/common';
import { NestjsFormDataModule } from 'nestjs-form-data/dist/nestjs-form-data.module';
import { UserController } from './user.controller';
import { UserService } from './user.service';
import { DatabaseService } from '../../database';
import { DatabaseModule } from '../../database/database.module';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { FirebaseModule } from '../../firebase/firebase.module';
import { FirebaseUserService } from './firebaseuser.service';
import { EmailService } from '../../email/email.service';

@Module({
    imports: [NestjsFormDataModule, DatabaseModule, ErrorLoggerModule, FirebaseModule],
    controllers: [UserController],
    providers: [UserService, FirebaseUserService, EmailService],
    exports: [UserService, FirebaseUserService],
})
export class UserModule {}

import { Module } from '@nestjs/common';
import { DatabaseModule } from '../database/database.module';
import { ErrorLoggerService } from './error-logger.service';
import { EmailService } from '../email/email.service';

@Module({
    imports: [DatabaseModule],
    providers: [ErrorLoggerService, EmailService],
    exports: [ErrorLoggerService],
})
export class ErrorLoggerModule {}

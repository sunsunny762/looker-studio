import { Module } from '@nestjs/common';
import { DatabaseModule } from '../../database/database.module';
import { LoginNotificationService } from './login-notification.service';
import { LoginNotificationController } from './login-notification.controller';

@Module({
    imports: [DatabaseModule],
    controllers: [LoginNotificationController],
    providers: [LoginNotificationService],
})
export class LoginNotificationModule {}

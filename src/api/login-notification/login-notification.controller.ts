import { Controller, Get, Post, Req, HttpException, HttpStatus } from '@nestjs/common';
import { LoginNotificationService } from './login-notification.service';

@Controller('login-notifications')
export class LoginNotificationController {

    constructor(private readonly loginNotificationService: LoginNotificationService) {}

    /**
     * GET /login-notifications/renewal-alert
     * Returns whether the renewal alert dialog should be shown for the authenticated user.
     */
    @Get('renewal-alert')
    async checkRenewalAlert(@Req() req: any): Promise<{ showDialog: boolean; }> {
        try {
            const uid = req.user?.uid;
            if (!uid) {
                return { showDialog: false };
            }
            return await this.loginNotificationService.checkRenewalAlert(uid);
        } catch (error: any) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * POST /login-notifications/renewal-alert/dismiss
     * Records that the renewal alert dialog was shown to the user this month.
     */
    @Post('renewal-alert/dismiss')
    async dismissRenewalAlert(@Req() req: any): Promise<void> {
        try {
            const uid = req.user?.uid;
            if (!uid) return;
            await this.loginNotificationService.dismissRenewalAlert(uid);
        } catch (error: any) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}

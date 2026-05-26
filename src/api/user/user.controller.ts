import { Body, Controller, Get, Param, Post, Put, Delete, Req, HttpException, HttpStatus, Query, Inject } from '@nestjs/common';
import { UserService } from './user.service';
import { FirebaseUserService } from './firebaseuser.service';

@Controller('users')
export class UserController {

    constructor(private readonly userService: UserService, private readonly firebaseUserService: FirebaseUserService) {}

    @Get()
    async getUsers(
        @Query('status') status?: string,
        @Query('companyId') companyId?: string,
    ): Promise<any> {
        try {
            return await this.userService.getUsers(null, status ? parseInt(status) : null, companyId ? parseInt(companyId) : null);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/:userId')
    async getUser(@Param('userId') userId: string): Promise<any> {
        try {
            return await this.userService.getUsers(parseInt(userId), null, null);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    @Get()
    async getUserByEmail(@Query('email') email: string) {
        return await this.userService.getUserByEmail(email);
    }
    
    @Post('add-new-user')
    async addNewUser(@Req() req: any, @Body() body: any): Promise<any> {
        try {
            const {
                companyId,
                fullName, 
                email, phone,
                status, roleId,
            } = body;

            //await this.firebaseUserService.deleteUserByEmail(email);
            const results = await this.userService.addUser(companyId, fullName, email, phone, status, roleId);
            if (results.length > 0) {
                const userRecord = await this.firebaseUserService.createUser(email, this.userService.generatePassword(), fullName);
                if (userRecord?.uid) {
                    await this.userService.updateUserUID(results[0].userId, userRecord.uid);
                    const verificationLink = await this.firebaseUserService.sendEmailVerification(email);
                    //this.userService.sendTestVerifyEmail(email, fullName, verificationLink);
                    this.userService.sendVerifyEmail(email, fullName, verificationLink);
                }
            }
            return results;
        } catch (error) {
            //console.error('Error updating user:', error.message);
            if(error.message.includes('DUPLICATE:')) 
                throw new HttpException(error.message.replace('DUPLICATE:', ''), HttpStatus.CONFLICT); 
            else
                throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    @Post()
    async addUser(@Req() req: any, @Body() body: any): Promise<any> {
        try {
            const {
                companyId,
                fullName, 
                email, phone,
                status, roleId, uId
            } = body;

            const results = await this.userService.addUser(companyId, fullName, email, phone, status, roleId, uId);
            
            return results;
        } catch (error) {
            //console.error('Error updating user:', error.message);
            if(error.message.includes('DUPLICATE:')) 
                throw new HttpException(error.message.replace('DUPLICATE:', ''), HttpStatus.CONFLICT); 
            
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Put('/:userId')
    async updateUser(@Param('userId') paramUserId: string, @Body() body: any): Promise<any> {
        if (paramUserId != body.userId) return null;
        try {
            const {
                userId,
                companyId,
                fullName,
                email, phone,
                status, roleId,
            } = body;

            return await this.userService.updateUser(userId, companyId, fullName, email, phone, status, roleId);
        } catch (error) {
            if(error.message.includes('DUPLICATE:')) 
                throw new HttpException(error.message.replace('DUPLICATE:', ''), HttpStatus.CONFLICT); 
            
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Delete('/:userId') 
    async deleteUser(@Param('userId') userId: string): Promise<any> {
        try {
            const result = await this.userService.deleteUser(parseInt(userId));
            this.firebaseUserService.deleteUserByEmail(result.email);
            return result;
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Post('send-verification')
    async sendVerificationEmail(@Body() body: { email: string, fullName: string }) {
        const verificationLink = await this.firebaseUserService.sendEmailVerification(body.email);
        this.userService.sendVerifyEmail(body.email, body.fullName, verificationLink);
        return { success: true, message: 'Verification email sent successfully' };
    }

    @Post('check-email')
    async checkEmail(@Body('email') email: string) {
       return await this.userService.checkUserEmailExists(email);
    }
    @Post('verify-email')
    async verifyEmail(@Body('email') email: string) {
       return await this.userService.updateUserEmailVerified(email, true);
    }

    @Post('/set-password')
    async changePassword(
        @Body() body: { uId: string, newPassword: string },
    ) {
        return this.firebaseUserService.changePassword(body.uId, body.newPassword);
    }

    @Post('reset-password')
    async sendPasswordResetEmail(@Body() body: { email: string }) {
        const res = await this.userService.getUserByEmail(body.email);
        if (res.length > 0) {
            if (res[0].disabled == 0) {
                const link = await this.firebaseUserService.sendPasswordResetEmail(body.email);
                //this.userService.sendTestResetPasswordEmail(body.email, res[0].displayName, link);
                this.userService.sendResetPasswordEmail(body.email, res[0].displayName, link);
                return { success: true, message: 'Password reset email sent successfully' };
            }
            else {
                throw new HttpException('User is disabled', HttpStatus.CONFLICT);
            }
        }
        else {
            throw new HttpException('User not found', HttpStatus.NOT_FOUND);
        }
    }

    @Put(':uid/email')
    async changeEmail(
        @Param('uid') uid: string,
        @Body() body: { newEmail: string },
    ) {
        return this.firebaseUserService.changeEmail(uid, body.newEmail);
    }

    @Put(':uid/enable')
    async enableUser(@Param('uid') uid: string) {
        return this.firebaseUserService.enableUser(uid);
    }

    @Put(':uid/disable')
    async disableUser(@Param('uid') uid: string) {
        return this.firebaseUserService.disableUser(uid);
    }
}

import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { th } from 'date-fns/locale';
import { Exception } from 'handlebars';
import { EmailService } from '../../email/email.service';
import { EmailTemplates } from '../../email/model/emailTemplates';

@Injectable()
export class UserService {

    constructor(private readonly databaseService: DatabaseService, 
        private readonly errorLoggerService: ErrorLoggerService,
        private readonly emailService: EmailService,

    ) { }

    public async getUsers(userId: number | null, status: number | null, companyId: number | null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spUser_Get]', [
            { name: "status", type: mssql.TYPES.Int, value: status },
            { name: "userId", type:mssql.TYPES.Int, value: userId },
            { name: "companyId", type: mssql.TYPES.Int, value: companyId }
        ]);
        const results = query.results;
        return results;
    }

    public async getUserByEmail(email: string): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spUser_GetbyEmail]', [
            { name: "email", type: mssql.TYPES.NVarChar, value: email }
        ]);
        const results = query.results;
        return results;
    }

    public async addUser(companyId: number, fullName: string, email: string, phone: string, status: number, roleId: number, uId: string = null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spUser_Save]', [
            { name: "userId", type: mssql.TYPES.Int, value: null },
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "fullName", type: mssql.TYPES.NVarChar, value: fullName },
            { name: "email", type: mssql.TYPES.NVarChar, value: email },
            { name: "phone", type: mssql.TYPES.NVarChar, value: phone },
            { name: "status", type: mssql.TYPES.Int, value: status },
            { name: "roleId", type: mssql.TYPES.Int, value: roleId },
            { name: "uId", type: mssql.TYPES.NVarChar, value: uId },
        ]);
        
        const results = query.results;
        if (results[0].errorMsg) 
            throw new Exception(results[0].errorMsg);

        return results;
    }
    public async updateUser(userId: number, companyId: number, fullName: string, email: string, phone: string, status: number, roleId: number): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spUser_Save]', [
            { name: "userId", type: mssql.TYPES.Int, value: userId },
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "fullName", type: mssql.TYPES.NVarChar, value: fullName },
            { name: "email", type: mssql.TYPES.NVarChar, value: email },
            { name: "phone", type: mssql.TYPES.NVarChar, value: phone },
            { name: "status", type: mssql.TYPES.Int, value: status },
            { name: "roleId", type: mssql.TYPES.Int, value: roleId },
        ]);
        
        const results = query.results;
        if (results[0].errorMsg) 
            throw new Exception(results[0].errorMsg);
        
        return results;
    }

    public async updateUserUID(userId: number, uId: string): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spUser_SaveUId]', [
            { name: "userId", type: mssql.TYPES.Int, value: userId },
            { name: "uId", type: mssql.TYPES.NVarChar, value: uId },
        ]);
        
        const results = query.results;
       
        return results;
    }

    public async updateUserEmailVerified(email: string, emailVerified: boolean): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spUser_EmailVerified]', [
            { name: "emailVerified", type: mssql.TYPES.Bit, value: emailVerified },
            { name: "email", type: mssql.TYPES.NVarChar, value: email },
        ]);
        
        const results = query.results;
       
        return results;
    }

    public async checkUserEmailExists(email: string): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spUser_CheckEmail]', [
            { name: "email", type: mssql.TYPES.NVarChar, value: email },
        ]);
        
        const results = query.results;
        return results[0].cnt;
    }

    public async deleteUser(userId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spUser_Delete]', [
            { name: "userId", type: mssql.TYPES.Int, value: userId },
        ]);
        
        const email = query?.results?.[0]?.email ?? null;
        return { email };
    }

    // public async setUserPassword(userId: number, password: string): Promise<any> {
    //     const hashedPassword = password; // TODO: hash the password before saving it to the database
    //     const query = await this.databaseService.execute('[portal].[spUser_SetPassword]', [
    //         { name: "userId", type: mssql.TYPES.Int, value: userId },
    //         { name: "password", type: mssql.TYPES.NVarChar, value: hashedPassword },
    //     ]);
        
    //     const results = query.results;
    //     return results;
    // }

    // public async validateUserPassword(userName: string, password: string): Promise<any> {
    //     const hashedPassword = password; // TODO: hash the password before saving it to the database
    //     const query = await this.databaseService.execute('[portal].[spUser_ValidatePassword]', [
    //         { name: "userName", type: mssql.TYPES.NVarChar, value: userName },
    //         { name: "password", type: mssql.TYPES.NVarChar, value: hashedPassword },
    //     ]);

    //     const results = query.results;
    //     return results;
    // }

    public  generatePassword(length = 8): string {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers = "0123456789";
        const special = "!@#$%^&*()-_=+[]{}|;:,.<>?";
      
        if (length < 8) throw new Error("Password length must be at least 8");
      
        const all = upper + lower + numbers + special;
      
        // Ensure at least one of each required character type
        let password = [
          upper[Math.floor(Math.random() * upper.length)],
          lower[Math.floor(Math.random() * lower.length)],
          numbers[Math.floor(Math.random() * numbers.length)],
          special[Math.floor(Math.random() * special.length)],
        ];
      
        // Fill the remaining length with random characters from all
        for (let i = password.length; i < length; i++) {
          password.push(all[Math.floor(Math.random() * all.length)]);
        }
      
        // Shuffle the password to avoid predictable order
        return password
          .sort(() => Math.random() - 0.5)
          .join('');
    }
    
    async sendVerifyEmail(
        email: string,
        fullName: string,
        verificationLink: string
    ): Promise<void> {
        await this.emailService.queueEmail(
            email,
            EmailTemplates.VERIFY_EMAIL_NCZ,
            {
                fullName,
                verificationLink
            }
        );
    }

    async sendResetPasswordEmail(
        email: string,
        fullName: string,
        resetLink: string
    ): Promise<void> {
        await this.emailService.queueEmail(
            email,
            EmailTemplates.RESET_PASSWORD_NCZ,
            {
                fullName,
                resetLink,
                email
            }
        );
    }
}
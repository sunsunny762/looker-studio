import { Injectable } from '@nestjs/common';
//import * as nodemailer from 'nodemailer';
import * as mssql from 'mssql';
import { DatabaseService } from '../database/database.service';
import { EmailStatus, EmailTemplates } from './model/emailTemplates';
import { IEmailContact } from './model/email';

@Injectable()
export class EmailService {

    constructor(private readonly databaseService: DatabaseService) {}

    private async getTemplateByName(templateName: EmailTemplates) {
        const res = await this.databaseService.execute(
            '[email].[spEmailTemplate_GetByName]',
            [{ name: 'name', type: mssql.TYPES.NVarChar, value: templateName }]
        );

        if (!res.singleResult) {
            throw new Error(`Email template not found: ${templateName}`);
        }

        return res.singleResult;
    }


    public async updateEmailById(
        id: number,
        messageId: string | undefined,
        status: string,
        attempt: number,
        error?: any
    ): Promise<void> {
        await this.databaseService.execute(
            '[email].[spEmailNotification_Update]',
            [
                { name: 'id', type: mssql.TYPES.Int, value: id },
                { name: 'messageId', type: mssql.TYPES.NVarChar, value: messageId ?? null },
                { name: 'status', type: mssql.TYPES.NVarChar, value: status },
                { name: 'sendAttemptCount', type: mssql.TYPES.Int, value: attempt },
                {
                    name: 'error',
                    type: mssql.TYPES.NVarChar,
                    value: error ? JSON.stringify(error) : null
                }
            ]
        );
    }

    public async updateEmailStatusByMessageId(
        messageId: string,
        status: string,
        error?: any
    ): Promise<void> {
        await this.databaseService.execute(
            '[email].[spEmailNotification_UpdateByMessageId]',
            [
                { name: 'messageId', type: mssql.TYPES.NVarChar, value: messageId },
                { name: 'status', type: mssql.TYPES.NVarChar, value: status },
                {
                    name: 'error',
                    type: mssql.TYPES.NVarChar,
                    value: error ? JSON.stringify(error) : null
                }
            ]
        );
    }

     public async queueEmail(
        toEmail: string,
        templateName: EmailTemplates,
        templateData?: Record<string, any>,
        fromEmail?: string,
        minimumSendDate?: Date
    ): Promise<number> {

        fromEmail = fromEmail || process.env.GOOGLE_SMTP_FROM;

        const template = await this.getTemplateByName(templateName);

        const result = await this.databaseService.execute(
            '[email].[spEmailNotification_Add]',
            [
                { name: 'toEmail', type: mssql.TYPES.NVarChar, value: toEmail },
                { name: 'templateId', type: mssql.TYPES.Int, value: template.id },
                {
                    name: 'templateData',
                    type: mssql.TYPES.NVarChar,
                    value: JSON.stringify(templateData || {})
                },
                { name: 'subject', type: mssql.TYPES.NVarChar, value: template.subject },
                { name: 'fromEmail', type: mssql.TYPES.NVarChar, value: fromEmail },
                {
                    name: 'minimumSendDate',
                    type: mssql.TYPES.DateTime,
                    value: minimumSendDate ?? null
                },
                {
                    name: 'status',
                    type: mssql.TYPES.NVarChar,
                    value: EmailStatus.Pending
                }
            ]
        );

        return result?.results?.[0]?.id;
    }

    public async queueEmailProcess(subject: string, body: string, to_JSON: Array<IEmailContact>, replyTo?: string, inReplyTo?: string, messageId?: string, documentId?: number): Promise<number> {
        
        const query = await this.databaseService.execute("[email].[spEmailQueue_Add]", [
            { name: "subject", type: mssql.TYPES.NVarChar, value: subject },
            { name: "body", type: mssql.TYPES.NVarChar, value: body },
            { name: "to_JSON", type: mssql.TYPES.NVarChar, value: JSON.stringify(to_JSON) },
            { name: "replyTo", type: mssql.TYPES.NVarChar, value: replyTo },
            { name: "inReplyTo", type: mssql.TYPES.NVarChar, value: inReplyTo },
            { name: "messageId", type: mssql.TYPES.NVarChar, value: messageId },
            //{ name: "documentId", type: mssql.TYPES.Int, value: documentId },
        ]);
        return 1;  //result.returnValue;
    }

}

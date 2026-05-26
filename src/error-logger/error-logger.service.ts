import { Injectable, Logger } from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import * as mssql from 'mssql';
import { EmailService } from '../email/email.service';
import * as path from 'path';
import * as fs from 'fs';
import { IEmailContact } from '../email/model/email';

@Injectable()
export class ErrorLoggerService extends Logger {
    
    constructor(private readonly databaseService: DatabaseService, private readonly emailService: EmailService) {
        super();
        // Override global console methods
        this.overrideConsole();
    }

    public async onModuleInit(): Promise<void> {
      if(!this.databaseService.isConnected)
        await this.databaseService.initialise();
    }
    
    private logDir: string = './logs'; private keepLogsForDays: number = 30;
    private static consoleOverridden = false;
    private static formId: string; // this will be set from JotformService
    private static submissionId: string; 

    public setFormSubmissionIds(formId: string, submissionId: string) { 
        ErrorLoggerService.formId = formId; 
        ErrorLoggerService.submissionId = submissionId; 
    }

    private overrideConsole() {
      if (ErrorLoggerService.consoleOverridden) return;
      ErrorLoggerService.consoleOverridden = true;

        const methods = ['log', 'error', 'warn', 'info', 'debug'];
        methods.forEach((method) => {
          const original = console[method].bind(console);
          console[method] = (...args: any[]) => {
            // Map `console.log` to `info`
            this.writeLogToFile(method === 'log' ? 'info' : method, JSON.stringify(args)); // Write logs to file
            
            if (method === 'error') { // Only errors to database
              this.writeLogToDB(args[0], args[1]);
            }
            
            original(...args); // Keep original console behavior
          };
        });
      }
      async writeLogToDB( functionName: string, error: any ): Promise<void> {
        try{
            await this.databaseService.execute('[utilities].[spLog_Error]', [
                { name: 'functionName', type: mssql.NVarChar, value: functionName },
                { name: 'errorMessage', type: mssql.NVarChar, value: error?.message || 'Unknown error' },
                { name: 'errorDetails', type: mssql.NVarChar, value: error?.stack || JSON.stringify(error) },
                { name: 'environmentKey', type: mssql.NVarChar, value: process.env.ENVIRONMENT_KEY },
                { name: 'formId', type: mssql.NVarChar, value: ErrorLoggerService.formId || null },
                { name: 'submissionId', type: mssql.NVarChar, value: ErrorLoggerService.submissionId || null },
            ]);
        }
        catch(e){
          this.writeLogToFile('ERROR', `writeLogToDB: ${e}`);
            //console.warn('writeLogToDB',e); 
        }
    }

    private writeLogToFile(level: string, message: string) {
      const logFile = path.join(this.logDir, `app-${new Date().toISOString().split('T')[0]}.log`);
      
      if (!fs.existsSync(logFile)) { // if Day changed, delete old log files once in a day
        this.deleteOldLogFiles();

      }

      const logMessage = `[${new Date().toISOString()}] [${level.toUpperCase()}] ${message}\n`;
      fs.appendFileSync(logFile, logMessage, 'utf8');
  }
  private deleteOldLogFiles() {
    const files = fs.readdirSync(this.logDir);
    const now = Date.now();
    const daysInMillis = this.keepLogsForDays * 24 * 60 * 60 * 1000;

    files.forEach(file => {
        const filePath = path.join(this.logDir, file);
        const stats = fs.statSync(filePath);
        if (now - stats.mtimeMs > daysInMillis) {
            fs.unlinkSync(filePath);
        }
    });
  }

  private async notifyErrorLogToAdmin( subject: string, body: string, emails: Array<IEmailContact> ): Promise<void> {
    try{
      const query = await this.databaseService.execute('[utilities].[spLog_GetPrevDayErrors]');
      if(query.results.length === 0) return;

      let email = [];
      const configration = await this.databaseService.execute('[email].[spEmailConfigration_Select]',  [
          { name: "name", type: mssql.TYPES.NVarChar, value: 'Admin Emails' },
      ]);
      
      if (configration.results || configration.results.length > 0) {
          configration.results.map( (row) => {
              email = JSON.parse(row.recipient).To;
              //template = row.template;
          })
      }
      const msgId = await this.emailService.queueEmail(`Error Log Notification ${new Date().toISOString().split('T')[0]}`, 
                    query.results[0].HTMLContent, 
                    email);

      //TODO attach log file to email
    }
    catch(e){
      this.writeLogToFile('ERROR', `notifyErrorToAdmin: ${e}`);
    }
  }

  public async notifyToAdmin( body: string,): Promise<void> {
    try{
      let email = [];
      const configration = await this.databaseService.execute('[email].[spEmailConfigration_Select]',  [
          { name: "name", type: mssql.TYPES.NVarChar, value: 'Admin Emails' },
      ]);
      
      if (configration.results || configration.results.length > 0) {
          configration.results.map( (row) => {
              email = JSON.parse(row.recipient).To;
              //template = row.template;
          })
      }
      await this.emailService.queueEmailProcess("Error notification", body, email);
    }
    catch(e){
      this.writeLogToFile('ERROR', `notifyErrorToAdmin: ${e}`);
    }
  }

}


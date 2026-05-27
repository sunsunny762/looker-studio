import { Injectable, Logger } from "@nestjs/common";
import { IJobStatus } from "./model/job-status";
import { CronJob } from "cron";
import fetch from "node-fetch";
import { JotformService } from "../jotform/jotoform.service";
import { ClickUpService } from "../clickup/clickup.service";
import { CurrencyService } from "../currency/currency.service";
import { PowerbiService } from "../powerbi/powerbi.service";
import { ScheduledJobType } from "./model/scheduled-job-type";
import { ScheduledJob } from "./model/schleduled-job";
import { ISchedulerHostContext } from "./model/scheduler-host-context";
import { BlueAwardReportJobAction, ClickupJobAction, CurrencyJobAction, FuelPriceJobAction, JotformJobAction, PowerbiJobAction, ReportDataJobAction } from "./model/scheduled-job-properties";
import { plainToInstance } from "class-transformer";
import { ScheduleFrequency } from "./model/scheduler-frequency";
import { DatabaseService } from "../database";

import * as mssql from 'mssql';
import { FormService } from "../jotform/form.service";
import { NCZFormService } from "../jotform/nczform.service";
import { FuelPriceService } from "../fuel-price/fuel-price.service";
import { ReportDataService } from "../reportData/reportData.service";
import { WebinarService } from "../api/webinar/webinar.service";
import { ReportService } from "../api/report/report.service";

@Injectable()
export class SchedulerService implements ISchedulerHostContext {
  //public readonly logger = new Logger(SchedulerService.name);
  private _scheduleFrequencies: Array<ScheduleFrequency> = [];
  private _heartbeatJobs: Array<CronJob> = [];

  constructor(
    public readonly jotformService: JotformService, 
    public readonly formService: FormService,
    public readonly nczformService: NCZFormService,
    public readonly clickupService: ClickUpService, 
    public readonly currencyService: CurrencyService,
    public readonly databaseService: DatabaseService,
    public readonly powerbiService: PowerbiService,
    public readonly reportDataService: ReportDataService,
    public readonly webinarService: WebinarService,
    public readonly reportService: ReportService,
    public readonly fuelPriceService: FuelPriceService
  ) { }
  

  public async initialise(fullScheduler: boolean): Promise<void> {
    const keepAliveUrl = process.env.KEEPALIVE_URL;
    const emailKeepAliveUrl = process.env.EMAIL_SERVICE_KEEPALIVE_URL;
    if (keepAliveUrl) { await this.startHeartbeatJob(keepAliveUrl); }
    if (emailKeepAliveUrl) { await this.startHeartbeatJob(emailKeepAliveUrl); }
    if (fullScheduler) {
        await this._loadConfig(true);
        this.generateCronJobs();    
    }
  }

public async executeScheduledJobs(frequency: ScheduleFrequency, contextHost: ISchedulerHostContext): Promise<void> {
    for (let job of frequency.jobs) {
        if (frequency.logActivity) {
            //contextHost.logger.log(`Running job ${job.displayName}`);
            console.log(`Running job ${job.displayName}`);
        }
        const start = new Date();
        let error = undefined;
        let statusInfo: string = undefined;
        let status = 'Started';
        try {
            /// Any jobs that can be run from this service need to have their own executor method
            /// which aligns to ScheduledJobType enum.
            switch (job.scheduledJobTypeId) {
                case ScheduledJobType.database: await contextHost.executeDatabaseJob(job, contextHost);                        
                    break;     
                case ScheduledJobType.jotform: await contextHost.executeJotformJob(job, contextHost);
                  break;  
                case ScheduledJobType.clickup: await contextHost.executeClickupJob(job, contextHost);
                  break;          
                case ScheduledJobType.currency: await contextHost.executeCurrencyJob(job, contextHost);
                    break; 
              case ScheduledJobType.powerbi: await contextHost.executePowerbiJob(job, contextHost);    
                    break;
              case ScheduledJobType.fuelprice: await contextHost.executeFuelPriceJob(job, contextHost);    
                    break;
              case ScheduledJobType.reportdata: await contextHost.executeReportDataJob(job, contextHost);    
                    break;
              case ScheduledJobType.webinarReminder: await contextHost.executeWebinarReminderJob(job, contextHost);
                    break;
               case ScheduledJobType.blueAwardReport: await contextHost.executeBlueAwardReportJob(job, contextHost);
                   break;
            }
            status = 'Complete';
        } catch(e) {
            //contextHost.logger.warn(`Exception ${(<any>e).toString()}`, job, e);
            console.error(`Exception ${(<any>e).toString()}`, job, e);
            status = 'Error';
            error = e;
        }
        if (frequency.logActivity || error || statusInfo) {
            contextHost.logRunHistoryEvent(job.id, frequency.id, start, status, error, statusInfo);
        }
    }
}

public async executeDatabaseJob(job: ScheduledJob, host: ISchedulerHostContext): Promise<any> {
    const query = await host.databaseService.execute(job.storedProcedureName);
    return query.results;
}

public async executeJotformJob(job: ScheduledJob, host: ISchedulerHostContext): Promise<any> {
    if (!job.properties.jotform || !job.properties.jotform.actions) {
        throw ('No Jotform configuration provided - use ScheduledJob.properties');
    }
    for (let action of job.properties.jotform.actions) {
      switch (action) {
          case JotformJobAction.processFormSubmission:
            await host.jotformService.processJotformResponses();
            break;
          case JotformJobAction.processPortalFormSubmission:
            await host.formService.processPortalFormResponses();
          break;
          case JotformJobAction.processNCZFormSubmission:
            await host.nczformService.processSubmissions();
          break;
          default:
            break;
      }
    }
}

public async executeCurrencyJob(job: ScheduledJob, host: ISchedulerHostContext): Promise<any> {
  if (!job.properties.currency || !job.properties.currency.actions) {
      throw ('No Currency configuration provided - use ScheduledJob.properties');
  }
  for (let action of job.properties.currency.actions) {
    switch (action) {
        case CurrencyJobAction.processConversionRate:
          await host.currencyService.processCurrencyRate();
          break;
        default:
          break;
    }
  }
}

public async executePowerbiJob(job: ScheduledJob, host: ISchedulerHostContext): Promise<any> {
  if (!job.properties.powerbi || !job.properties.powerbi.actions) {
      throw ('No Powerbi configuration provided - use ScheduledJob.properties');
  }
  for (let action of job.properties.powerbi.actions) {
    switch (action) {
        case PowerbiJobAction.exportReport:
          await host.powerbiService.exportPowerBIReports();
          break;
        default:
          break;
    }
  }
}

public async executeReportDataJob(job: ScheduledJob, host: ISchedulerHostContext): Promise<any> {
    if (!job.properties.reportdata || !job.properties.reportdata.actions) {
        throw ('No ReportData configuration provided - use ScheduledJob.properties');
    }
    for (let action of job.properties.reportdata.actions) {
      switch (action) {
          case ReportDataJobAction.silverReportData:
            await host.reportDataService.insertSilverReportData();
            break;
          default:
            break;
      }
    }
  }

  public async executeWebinarReminderJob(job: ScheduledJob, host: ISchedulerHostContext): Promise<any> {
    const pendingReminders = await host.webinarService.getPendingReminders();
    for (const booking of pendingReminders) {
      try {
        await host.webinarService.queueReminderEmail(
          booking.contactEmail,
          booking.webinarTitle,
          booking.businessName,
          booking.slotDateTime,
          booking.meetingLink ?? null,
          booking.organizerEmail ?? null,
          booking.organizerName ?? null,
          booking.webinarTimezone ?? 'UTC',
        );
        await host.webinarService.markReminderSent(booking.bookingId);
      } catch (e) {
        console.error(`Failed to send webinar reminder for bookingId=${booking.bookingId}`, e);
      }
    }
  }

  public async executeBlueAwardReportJob(job: ScheduledJob, host: ISchedulerHostContext): Promise<any> {
    if (!job.properties.blueAwardReport || !job.properties.blueAwardReport.actions) {
        throw ('No BlueAwardReport configuration provided - use ScheduledJob.properties');
    }
    for (let action of job.properties.blueAwardReport.actions) {
	      switch (action) {
	          case BlueAwardReportJobAction.downloadAndStoreBlueAwardReport:
	            await host.reportService.generateBlueAwardReport();
	            await host.reportService.queueGeneratedBlueAwardReportEmails();
	            break;
	          default:
	            break;
	      }
    }
  }


public async executeClickupJob(job: ScheduledJob, host: ISchedulerHostContext): Promise<any> {
  if (!job.properties.clickup || !job.properties.clickup.actions) {
      throw ('No Clickup configuration provided - use ScheduledJob.properties');
  }
  console.log('Clickup Job Action Start :', new Date().toLocaleString());
  console.log('Clickup Job Action:', job.properties.clickup.actions);
  for (let action of job.properties.clickup.actions) {
      switch (action) {
          case ClickupJobAction.deleteTask: 
            console.log('Clickup Job Action Delete Task ', new Date().toLocaleString());
            await host.clickupService.processUpdateDeletedTasks();
            break;
          case ClickupJobAction.processTask: 
            console.log('Clickup Job Action Process Task ', new Date().toLocaleString());
            await host.clickupService.processConfiguredClickUpTasks();
            break;
          case ClickupJobAction.statusHistory:
            console.log('Clickup Job Action Status History ', new Date().toLocaleString());
            await host.clickupService.processAllParentTasksStatusHistory();
            break;
          case ClickupJobAction.mapPersonCompany: 
            console.log('Clickup Job Action Map Person Company ', new Date().toLocaleString());
            await host.clickupService.processLinkCertificationWithPersonCompany();
            await host.clickupService.processTasksPersonCompany();
            break;
          case ClickupJobAction.mapCompanyCertification: 
            console.log('Clickup Job Action Map Company Certification ', new Date().toLocaleString());
            await host.clickupService.processTasksCompanyCertifications(); // This will be also done from mapPersonCompany
            break;
          case ClickupJobAction.populateCustomers: 
            console.log('Clickup Job Action Populate Customers ', new Date().toLocaleString());
            await host.clickupService.populateCustomers();
            break;
          case ClickupJobAction.updateDueDate:
            console.log('Clickup Job Action Update Due Date ', new Date().toLocaleString());
            await host.clickupService.processUpdatePeopleDueDate();
            break;
          default:
              break;
      }
  }
  console.log('Clickup Job Action End :', new Date().toLocaleString());
}

public async executeFuelPriceJob(job: ScheduledJob, host: ISchedulerHostContext): Promise<any> {
  if (!job.properties.fuelprice || !job.properties.fuelprice.actions) {
      throw ('No FuelPrice configuration provided - use ScheduledJob.properties');
  }
  for (let action of job.properties.fuelprice.actions) {
    switch (action) {
        case FuelPriceJobAction.updateFuelPrices:
          await host.fuelPriceService.processUpdateUKFuelPrices();
          break;
        default:
          break;
    }
  }
}
  
public async logRunHistoryEvent(jobId: number, scheduleFrequencyId: number, start: Date, status: string, error: any, statusInfo: string): Promise<void> {
  await this.databaseService.execute('[scheduler].[spScheduledJobRunHistory_Save]', [
      { name: "scheduledJobId", type: mssql.TYPES.Int, value: jobId },
      { name: "scheduleFrequencyId", type: mssql.TYPES.Int, value: scheduleFrequencyId },
      { name: "runStartDate", type: mssql.TYPES.DateTime, value: start },
      { name: "runEndDate", type: mssql.TYPES.DateTime, value: new Date() },
      { name: "status", type: mssql.TYPES.NVarChar, value: status },
      { name: "error", type: mssql.TYPES.NVarChar, value: error ? JSON.stringify(error): undefined },
      { name: "statusInfo", type: mssql.TYPES.NVarChar, value: statusInfo },            
  ]);
}

private generateCronJobs(): void {
  const contextHost: ISchedulerHostContext = this;
  this._scheduleFrequencies.forEach(j => {
      j.instance = new CronJob(
          j.cronDefinition,
          async () => {
              if (j.isProcessing) { return }
              try {
                  j.isProcessing = true;
                  await contextHost.executeScheduledJobs(j, contextHost);
              } catch (e) {
                  //contextHost.logger.warn(`Exception ${(<any>e).toString()}`, j, e);
                  console.error(`Exception ${(<any>e).toString()}`, j, e);
              } finally {
                  j.isProcessing = false;
              }
          },
          () => {
              //contextHost.logger.log(`Stopped`, j);
              console.log(`Stopped`, j);
          },
          true
      );
  });

}

private async _loadConfig(fullRefresh: boolean = true): Promise<void> {
  if (fullRefresh) {
      this._scheduleFrequencies = await this._loadSchedules();
  }
  for (let f of this._scheduleFrequencies) {
      f.jobs = await this._loadJobs(f);
      //this.logger.log(`Prepared job schedule ${f.name} ${f.cronDefinition} - ${f.jobs.length} job(s)`);
      console.log(`Prepared job schedule ${f.name} ${f.cronDefinition} - ${f.jobs.length} job(s)`);
  }
}

private async _loadSchedules(): Promise<Array<ScheduleFrequency>> {
  const query = await this.databaseService.execute('[scheduler].[spScheduleFrequencies_Select]', [
      { name: "environmentKey", type: mssql.TYPES.NVarChar, value: process.env.ENVIRONMENT_KEY },
  ]);
  return plainToInstance(ScheduleFrequency, query.results);
}

private async _loadJobs(frequency: ScheduleFrequency): Promise<Array<ScheduledJob>> {
  const query = await this.databaseService.execute('[scheduler].[spScheduledJobs_Select]', [
      { name: "environmentKey", type: mssql.TYPES.NVarChar, value: process.env.ENVIRONMENT_KEY },
      { name: "scheduleFrequencyId", type: mssql.TYPES.Int, value: frequency.id },
  ]);
  return plainToInstance(ScheduledJob, query.results);
}

private async startHeartbeatJob(url?: string): Promise<void> {
  const targetUrl = url || process.env.KEEPALIVE_URL;
  if (!targetUrl) {
    console.log('heartbeat job not set');
    return;
  }

  const schedule = '*/5 * * * *';
  const job = new CronJob(
    schedule,
    async () => {
      try {
        console.log('Scheduler Heartbeat - ', new Date().toLocaleString(), targetUrl);
        const response = await fetch(targetUrl);
        try { await response.json(); } catch (e) { }
      } catch (e) { }
    },
    undefined,
    false
  );

  this._heartbeatJobs.push(job);
  job.start();
  console.log('heartbeat job started for', targetUrl);
}

}

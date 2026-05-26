//import { Logger } from '@nestjs/common';
import { DatabaseService } from "../../database";
import { ScheduleFrequency } from './scheduler-frequency';
import { ScheduledJob } from './schleduled-job';
import { CurrencyService } from '../../currency/currency.service';
import { JotformService } from '../../jotform/jotoform.service';
import { ClickUpService } from '../../clickup/clickup.service';
import { PowerbiService } from '../../powerbi/powerbi.service';
import { FormService } from "../../jotform/form.service";
import { FuelPriceService } from "../../fuel-price/fuel-price.service";
import { NCZFormService } from "../../jotform/nczform.service";
import { ReportDataService } from "../../reportData/reportData.service";


import { ReportService } from "../../api/report/report.service";
import { WebinarService } from "../../api/webinar/webinar.service";

type ScheduleProcessor = (frequency: ScheduleFrequency, host: ISchedulerHostContext) => any;
type ExecuteDatabaseJobFN = (job: ScheduledJob, host: ISchedulerHostContext) => any;
type ExecuteJobFN = (job: ScheduledJob, host: ISchedulerHostContext) => any;

export interface ISchedulerHostContext {
    //logger: Logger,
    databaseService: DatabaseService,
    currencyService: CurrencyService, 
    fuelPriceService: FuelPriceService,
    formService: FormService,
    nczformService: NCZFormService,
    jotformService: JotformService,
    clickupService: ClickUpService,
    powerbiService: PowerbiService,
    reportDataService: ReportDataService,
    webinarService: WebinarService,
    reportService: ReportService,
    
    executeScheduledJobs: ScheduleProcessor,
    executeDatabaseJob: ExecuteDatabaseJobFN,
    executeCurrencyJob: ExecuteJobFN,
    executeJotformJob: ExecuteJobFN,
    executeClickupJob: ExecuteJobFN,
    executePowerbiJob: ExecuteJobFN,
    executeFuelPriceJob: ExecuteJobFN,
    executeReportDataJob: ExecuteJobFN,
    executeWebinarReminderJob: ExecuteJobFN,
    executeBlueAwardReportJob: ExecuteJobFN,
    logRunHistoryEvent: any,
}

import { Expose, plainToInstance, Transform } from "class-transformer";

export enum CurrencyJobAction { none, processConversionRate }
class CurrencyJobProperties {
    @Expose()
    public readonly actions: Array<CurrencyJobAction>;
}

export enum FuelPriceJobAction { none, updateFuelPrices }
class FuelPriceJobProperties {
    @Expose()
    public readonly actions: Array<FuelPriceJobAction>;
}

export enum PowerbiJobAction { none, exportReport }
class PowerbiJobProperties {
    @Expose()
    public readonly actions: Array<PowerbiJobAction>;
}
export enum ReportDataJobAction { none, silverReportData }
class ReportDataJobProperties {
    @Expose()
    public readonly actions: Array<ReportDataJobAction>;
}

export enum BlueAwardReportJobAction { none, downloadAndStoreBlueAwardReport, queueBlueAwardReportEmail }
class BlueAwardReportJobProperties {
    @Expose()
    public readonly actions: Array<BlueAwardReportJobAction>;
}

export enum JotformJobAction { none, processFormSubmission, processPortalFormSubmission, processNCZFormSubmission }
class JotformJobProperties {
    @Expose()
    public readonly actions: Array<JotformJobAction>;
}

export enum ClickupJobAction { none, deleteTask, processTask, statusHistory, mapPersonCompany, mapCompanyCertification, mapCertificationBuyer, populateCustomers, updateDueDate}
class ClickupJobProperties {
    @Expose()
    public readonly actions: Array<ClickupJobAction>;
}

export class ScheduledJobProperties {
    @Expose()
    public readonly jotform?: JotformJobProperties;

    @Expose()
    public readonly clickup?: ClickupJobProperties;

    @Expose()
    public readonly currency?: CurrencyJobProperties;
    
    @Expose()
    public readonly fuelprice?: FuelPriceJobProperties;

    @Expose()
    public readonly powerbi?: PowerbiJobProperties;

    @Expose()
    public readonly reportdata?: ReportDataJobProperties;

    @Expose()
    public readonly blueAwardReport?: BlueAwardReportJobProperties;

    static from(data: any): ScheduledJobProperties {
        if (!data) {
            return {}
        }
        return typeof data == "object"
          ? plainToInstance(ScheduledJobProperties, data)
          : plainToInstance(ScheduledJobProperties, JSON.parse(data));
    }
}

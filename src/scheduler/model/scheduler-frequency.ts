import { Expose } from "class-transformer";
import { ScheduledJob } from "./schleduled-job";

export class ScheduleFrequency {
    @Expose()
    public readonly id: number;
    
    @Expose()
    public readonly name: string;

    @Expose()
    public readonly cronDefinition: string;

    @Expose()
    public readonly environmentKey: string;

    @Expose()
    public readonly logActivity: boolean;

    /// The active cron job instance
    public instance: any;

    public isProcessing: boolean;

    public jobs: Array<ScheduledJob>;
}
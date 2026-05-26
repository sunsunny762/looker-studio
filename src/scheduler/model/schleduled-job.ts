import { Expose, Transform } from "class-transformer";
import { ScheduledJobProperties } from "./scheduled-job-properties";
import { ScheduledJobType } from "./scheduled-job-type";


export class ScheduledJob {
    @Expose()
    public readonly id: number;

    @Expose()
    public readonly displayName: string;

    @Expose()
    public readonly active: number;

    @Expose()
    public readonly runOrder: number;

    @Expose()
    public readonly storedProcedureName: string;

    @Expose()
    public readonly scheduledJobTypeId: ScheduledJobType;

    @Expose()
    @Transform(({ value }) => ScheduledJobProperties.from(value), { toClassOnly: true })
    public readonly properties: ScheduledJobProperties;
}
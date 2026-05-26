import { Module } from "@nestjs/common";
import { DatabaseModule } from "../database/database.module";
import { SchedulerService } from "./scheduler.service";
import { JotformModule } from "../jotform/jotoform.module";
import { ClickupModule } from "../clickup/clickup.module";
import { CurrencyModule } from "../currency/currency.module";
import { PowerbiModule } from "../powerbi/powerbi.module";
import { FuelPriceModule } from "../fuel-price/fuel-price.module";
import { ReportDataModule } from "../reportData/reportData.module";
import { WebinarModule } from "../api/webinar/webinar.module";
import { ReportModule } from "../api/report/report.module";

@Module({
  imports: [DatabaseModule, JotformModule, ClickupModule,
            CurrencyModule, PowerbiModule, FuelPriceModule, ReportDataModule, WebinarModule, ReportModule],
  providers: [SchedulerService],
  exports: [SchedulerService],
})
export class SchedulerModule {}

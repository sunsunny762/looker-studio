import { Module } from '@nestjs/common';
import { FuelPriceService } from './fuel-price.service';
import { DatabaseModule } from '../database/database.module';
import { DatabaseService } from '../database/database.service';

@Module({
  imports: [DatabaseModule],
  providers: [FuelPriceService, DatabaseService],
  exports: [FuelPriceService],
})
export class FuelPriceModule {}
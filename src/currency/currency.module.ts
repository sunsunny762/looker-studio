import { Module } from '@nestjs/common';
import { NestjsFormDataModule } from 'nestjs-form-data/dist/nestjs-form-data.module';
import { DatabaseService } from '../database';
import { DatabaseModule } from '../database/database.module';
import { CurrencyService } from './currency.service';

@Module({
    imports: [NestjsFormDataModule, DatabaseModule],
    controllers: [],
    providers: [CurrencyService],
    exports: [CurrencyService],
})
export class CurrencyModule {}

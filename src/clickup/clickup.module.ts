import { Module } from '@nestjs/common';
import { NestjsFormDataModule } from 'nestjs-form-data/dist/nestjs-form-data.module';
import { ClickupController } from './clickup.controller';
import { ClickUpService } from './clickup.service';
import { DatabaseService } from '../database';
import { DatabaseModule } from '../database/database.module';
import { CustomFieldsConstants } from './customfields-constants';
import { ErrorLoggerModule } from '../error-logger/error-logger.module';

@Module({
    imports: [NestjsFormDataModule, DatabaseModule, ErrorLoggerModule],
    controllers: [ClickupController],
    providers: [ClickUpService, CustomFieldsConstants],
    exports: [ClickUpService, CustomFieldsConstants],
})
export class ClickupModule {}

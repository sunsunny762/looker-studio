import { Module } from '@nestjs/common';
import { NestjsFormDataModule } from 'nestjs-form-data/dist/nestjs-form-data.module';
import { CompanyController } from './company.controller';
import { CompanyService } from './company.service';
import { DatabaseService } from '../../database';
import { DatabaseModule } from '../../database/database.module';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { DocumentsModule } from '../../documents/documents.module';
import { JotformService } from '../../jotform/jotoform.service';
import { ClickUpService } from '../../clickup/clickup.service';
import { CustomFieldsConstants } from '../../clickup/customfields-constants';

@Module({
    imports: [NestjsFormDataModule, DatabaseModule, ErrorLoggerModule, DocumentsModule],
    controllers: [CompanyController],
    providers: [CompanyService, JotformService, ClickUpService, CustomFieldsConstants],
    exports: [CompanyService, ClickUpService, CustomFieldsConstants],
})
export class CompanyModule { }

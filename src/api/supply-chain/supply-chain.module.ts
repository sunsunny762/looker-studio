import { Module } from '@nestjs/common';
import { NestjsFormDataModule } from 'nestjs-form-data/dist/nestjs-form-data.module';
import { SupplyChainService } from './supply-chain.service';
import { DatabaseModule } from '../../database/database.module';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { CompanyModule } from '../company/company.module';
import { DocumentsModule } from '../../documents/documents.module';
import { SupplyChainController } from './supply-chain.controller';

@Module({
    imports: [
        NestjsFormDataModule,
        DatabaseModule,
        ErrorLoggerModule,
        CompanyModule,
        DocumentsModule
    ],
    controllers: [SupplyChainController],
    providers: [SupplyChainService],
    exports: [SupplyChainService],
})
export class SupplyChainModule { }
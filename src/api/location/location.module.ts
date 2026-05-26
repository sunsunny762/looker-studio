import { Module } from '@nestjs/common';
import { NestjsFormDataModule } from 'nestjs-form-data/dist/nestjs-form-data.module';
import { LocationController } from './location.controller';
import { LocationService } from './location.service';
import { DatabaseService } from '../../database';
import { DatabaseModule } from '../../database/database.module';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { DocumentsModule } from '../../documents/documents.module';

@Module({
    imports: [NestjsFormDataModule, DatabaseModule, ErrorLoggerModule, DocumentsModule],
    controllers: [LocationController],
    providers: [LocationService],
    exports: [LocationService],
})
export class LocationModule {}

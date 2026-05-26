import { Module } from '@nestjs/common';
import { NczformsService } from './nczforms.service';
import { NczformsController } from './nczforms.controller';
import { DatabaseModule } from '../../database/database.module';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { DocumentsModule } from '../../documents/documents.module';

@Module({
    imports: [DatabaseModule, ErrorLoggerModule, DocumentsModule],
    controllers: [NczformsController],
    providers: [NczformsService],
    exports: [NczformsService]
})
export class NczformsModule {}

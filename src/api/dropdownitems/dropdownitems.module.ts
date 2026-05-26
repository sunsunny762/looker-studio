import { Module } from '@nestjs/common';
import { NestjsFormDataModule } from 'nestjs-form-data/dist/nestjs-form-data.module';
import { DropdownItemsController } from './dropdownitems.controller';
import { DropdownItemsService } from './dropdownitems.service';
import { DatabaseService } from '../../database';
import { DatabaseModule } from '../../database/database.module';
import { ErrorLoggerModule } from '../../error-logger/error-logger.module';
import { FirebaseAuthService } from '../../firebase/firebase-auth.service';
import { FirebaseAdminService } from '../../firebase/firebase-admin.service';

@Module({
    imports: [NestjsFormDataModule, DatabaseModule, ErrorLoggerModule],
    controllers: [DropdownItemsController],
    providers: [DropdownItemsService,FirebaseAuthService,FirebaseAdminService],
    exports: [DropdownItemsService],
})
export class DropdownItemsModule {}

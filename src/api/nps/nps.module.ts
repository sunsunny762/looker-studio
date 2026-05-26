import { Module } from '@nestjs/common';
import { NpsController } from './nps.controller';
import { NpsService } from './nps.service';
import { DatabaseModule } from '../../database/database.module';

@Module({
    imports: [DatabaseModule],
    controllers: [NpsController],
    providers: [NpsService],
})
export class NpsModule { }

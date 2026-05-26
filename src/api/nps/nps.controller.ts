import { Body, Controller, Get, Param, Post, HttpException, HttpStatus } from '@nestjs/common';
import { NpsService } from './nps.service';

@Controller('nps')
export class NpsController {

    constructor(private readonly npsService: NpsService) { }

    @Post()
    async submitNps(@Body() body: any): Promise<any> {
        try {
            const { certId, score, reason, userId } = body;
            if (certId == null || score == null) {
                throw new HttpException('certId and score are required.', HttpStatus.BAD_REQUEST);
            }
            if (score < 0 || score > 10) {
                throw new HttpException('Score must be between 0 and 10.', HttpStatus.BAD_REQUEST);
            }
            return await this.npsService.submitNps(
                parseInt(certId),
                parseInt(score),
                reason ?? null,
                userId != null ? parseInt(userId) : null,
            );
        } catch (error) {
            throw new HttpException(error.message, error.status || HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/certification/:certId')
    async getNpsByCert(@Param('certId') certId: string): Promise<any> {
        try {
            return await this.npsService.getNpsByCert(parseInt(certId));
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/ytd')
    async getNpsYtd(): Promise<any> {
        try {
            return await this.npsService.getNpsYtd();
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get()
    async getAllNpsResponses(): Promise<any> {
        try {
            return await this.npsService.getAllNpsResponses();
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}

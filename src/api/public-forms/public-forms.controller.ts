import {
    Body,
    Controller,
    Delete,
    Get,
    HttpException,
    HttpStatus,
    Param,
    ParseIntPipe,
    Post,
    Put,
    Query,
} from '@nestjs/common';
import { PublicFormsService } from './public-forms.service';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';

@Controller('public-forms')
export class PublicFormsController {
    constructor(
        private readonly publicFormsService: PublicFormsService,
        private readonly errorLoggerService: ErrorLoggerService,
    ) {}

    // ── Forms ─────────────────────────────────────────────────────────────────

    @Get()
    async getForms(): Promise<any> {
        try {
            return await this.publicFormsService.getForms();
        } catch (error) {
            await this.errorLoggerService.writeLogToDB('PublicFormsController.getForms', error);
            throw new HttpException(
                error.message || 'Failed to fetch public forms',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR,
            );
        }
    }

    // @Get(':pformId')
    // async getFormById(@Param('pformId', ParseIntPipe) pformId: number): Promise<any> {
    //     try {
    //         const form = await this.publicFormsService.getFormById(pformId);
    //         if (!form) {
    //             throw new HttpException('Form not found', HttpStatus.NOT_FOUND);
    //         }
    //         return form;
    //     } catch (error) {
    //         await this.errorLoggerService.writeLogToDB('PublicFormsController.getFormById', error);
    //         throw new HttpException(
    //             error.message || 'Failed to fetch public form',
    //             error.status || HttpStatus.INTERNAL_SERVER_ERROR,
    //         );
    //     }
    // }

    // @Post()
    // async saveForm(@Body() body: any): Promise<any> {
    //     try {
    //         const { pformId, dimFormId, displayName, displayOrder, isActive } = body;
    //         if (!pformId) {
    //             throw new HttpException('pformId is required', HttpStatus.BAD_REQUEST);
    //         }
    //         return await this.publicFormsService.saveForm(
    //             pformId, dimFormId ?? null, displayName ?? null, displayOrder ?? 0, isActive ?? false,
    //         );
    //     } catch (error) {
    //         await this.errorLoggerService.writeLogToDB('PublicFormsController.saveForm', error);
    //         throw new HttpException(
    //             error.message || 'Failed to save public form',
    //             error.status || HttpStatus.INTERNAL_SERVER_ERROR,
    //         );
    //     }
    // }

    // @Put(':pformId')
    // async updateForm(
    //     @Param('pformId', ParseIntPipe) pformId: number,
    //     @Body() body: any,
    // ): Promise<any> {
    //     try {
    //         const { dimFormId, displayName, displayOrder, isActive } = body;
    //         return await this.publicFormsService.saveForm(
    //             pformId, dimFormId ?? null, displayName ?? null, displayOrder ?? 0, isActive ?? false,
    //         );
    //     } catch (error) {
    //         await this.errorLoggerService.writeLogToDB('PublicFormsController.updateForm', error);
    //         throw new HttpException(
    //             error.message || 'Failed to update public form',
    //             error.status || HttpStatus.INTERNAL_SERVER_ERROR,
    //         );
    //     }
    // }

    // @Delete(':pformId')
    // async deleteForm(@Param('pformId', ParseIntPipe) pformId: number): Promise<any> {
    //     try {
    //         await this.publicFormsService.deleteForm(pformId);
    //         return { success: true };
    //     } catch (error) {
    //         await this.errorLoggerService.writeLogToDB('PublicFormsController.deleteForm', error);
    //         throw new HttpException(
    //             error.message || 'Failed to delete public form',
    //             error.status || HttpStatus.INTERNAL_SERVER_ERROR,
    //         );
    //     }
    // }

    // ── Submissions ───────────────────────────────────────────────────────────

    @Get(':dimFormId/submissions')
    async getSubmissions(
        @Param('dimFormId', ParseIntPipe) dimFormId: number,
        @Query('dateFrom') dateFrom: string,
        @Query('dateTo') dateTo: string,
    ): Promise<any> {
        try {
            const from = dateFrom ? new Date(dateFrom) : null;
            const to   = dateTo   ? new Date(dateTo)   : null;
            return await this.publicFormsService.getSubmissions(dimFormId, null, from, to);
        } catch (error) {
            await this.errorLoggerService.writeLogToDB('PublicFormsController.getSubmissions', error);
            throw new HttpException(
                error.message || 'Failed to fetch submissions',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR,
            );
        }
    }

    @Get(':dimFormId/submissions/:psubmissionId')
    async getSubmissionById(
        @Param('dimFormId', ParseIntPipe) dimFormId: number,
        @Param('psubmissionId', ParseIntPipe) psubmissionId: number,
    ): Promise<any> {
        try {
            const results = await this.publicFormsService.getSubmissions(dimFormId, psubmissionId);
            return results?.[0] ?? null;
        } catch (error) {
            await this.errorLoggerService.writeLogToDB('PublicFormsController.getSubmissionById', error);
            throw new HttpException(
                error.message || 'Failed to fetch submission',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR,
            );
        }
    }

    @Delete(':dimFormId/submissions/:psubmissionId')
    async deleteSubmission(
        @Param('psubmissionId', ParseIntPipe) psubmissionId: number,
        @Query('notes') notes?: string,
    ): Promise<any> {
        try {
            await this.publicFormsService.deleteSubmission(psubmissionId, notes ?? null);
            return { success: true };
        } catch (error) {
            await this.errorLoggerService.writeLogToDB('PublicFormsController.deleteSubmission', error);
            throw new HttpException(
                error.message || 'Failed to delete submission',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR,
            );
        }
    }
}

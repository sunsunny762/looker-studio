import { Controller, Get, Post, Put, Delete, Body, Param, Query, ParseIntPipe, UploadedFile, UseInterceptors, HttpException, HttpStatus, UploadedFiles, Res } from '@nestjs/common';
import { NczformsService } from './nczforms.service';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { tr } from 'date-fns/locale';

@Controller('nczforms')
export class NczformsController {

    constructor(private readonly nczformsService: NczformsService) { }

    // @Post('submission')
    // async saveFormSubmission(
    //     @Body() body: {
    //         formId: number;
    //         userId: number;
    //         responses: any;
    //         submissionData: any;
    //         isDraft?: boolean;
    //     }
    // ) {
    //     const { formId, userId, responses, submissionData, isDraft = false } = body;
    //     return await this.nczformsService.saveFormSubmission(formId, null, userId, responses, submissionData, isDraft);
    // }

    @Put('submission/:submissionId')
    async updateFormSubmission(
        @Param('submissionId', ParseIntPipe) submissionId: number,
        @Body() body: {
            formId: number;
            userId: number;
            responses: any;
            submissionData: any;
            isDraft?: boolean;
        }
    ) {
        const { formId, userId, responses, submissionData, isDraft = false } = body;
        return await this.nczformsService.saveFormSubmission(formId, submissionId, userId, responses, submissionData, isDraft);
        //return await this.nczformsService.updateFormSubmission(submissionId, submissionData, isDraft);
    }

    @Get('submission/:submissionId')
    async getFormSubmission(
        @Param('submissionId', ParseIntPipe) submissionId: number
    ) {
        return await this.nczformsService.getFormSubmission(submissionId);
    }

    // @Get('submissions/user/:userId')
    // async getFormSubmissionsByUser(
    //     @Param('userId') userId: string,
    //     @Query('formId') formId?: number
    // ) {
    //     return await this.nczformsService.getFormSubmissionsByUser(userId, formId);
    // }

    // @Get('submissions/form/:formId')
    // async getFormSubmissionsByForm(
    //     @Param('formId', ParseIntPipe) formId: number
    // ) {
    //     return await this.nczformsService.getFormSubmissionsByForm(formId);
    // }

    @Delete('submission/:submissionId')
    async deleteFormSubmission(
        @Param('submissionId', ParseIntPipe) submissionId: number
    ) {
        return await this.nczformsService.deleteFormSubmission(submissionId);
    }

    // @Post('submission/:submissionId/draft')
    // async saveDraft(
    //     @Param('submissionId', ParseIntPipe) submissionId: number,
    //     @Body() body: { submissionData: any }
    // ) {
    //     const { submissionData } = body;
    //     return await this.nczformsService.updateFormSubmission(submissionId, submissionData, true);
    // }

    // @Post('submission/:submissionId/submit')
    // async submitForm(
    //     @Param('submissionId', ParseIntPipe) submissionId: number,
    //     @Body() body: { submissionData: any }
    // ) {
    //     const { submissionData } = body;
    //     return await this.nczformsService.updateFormSubmission(submissionId, submissionData, false);
    // }

    @Get(':formId/config')
    async getFormConfiguration(@Param('formId', ParseIntPipe) formId: number) {
        return this.nczformsService.getFormConfiguration(formId);
    }

    @Get('airports/search')
    async getAirportByName(@Query('search') search: string) {
        return this.nczformsService.getAirportsByName(search);
    }

    @Get('countries/search')
    async getCountryByName(@Query('search') search: string) {
        return this.nczformsService.getCountriesByName(search);
    }

    @Get('currencies/search')
    async getCurrencyByName(@Query('search') search: string) {
        return this.nczformsService.getCurrenciesByName(search);
    }

    @Get('documents/submission/:certSubmissionId/question/:questionId')
    async getSubmissionDocumentsbyQuestion(@Param('certSubmissionId', ParseIntPipe) certSubmissionId: number, @Param('questionId', ParseIntPipe) questionId: number) {
        return this.nczformsService.getSubmissionDocumentsbyQuestion(certSubmissionId, questionId);
    }

    @Post('documents/upload')
    @UseInterceptors(FileInterceptor('file'))
    async uploadSubmissionDocument(
        @UploadedFile() file: Express.Multer.File,
        @Body() body: any
    ) {
        const result = await this.nczformsService.uploadSubmissionDocument(file, body);
        return result;
    }

    @Post('documents/upload-multiple')
    @UseInterceptors(FilesInterceptor('files'))
    async uploadSubmissionDocuments(
        @UploadedFiles() files: Express.Multer.File[],
        @Body() body: any
    ) {
        const result = await this.nczformsService.uploadSubmissionDocuments(files, body);
        return result;
    }

    @Get('documents/download/:documentId')
    async downloadFile(@Param('documentId') documentId: number, @Res() res: Response) {
        const result = await this.nczformsService.getDocumentDownload(documentId);
        if (!result) {
            res.status(404).send('Document not found');
            return;
        }
        const safeFilename = (result.title || 'document').replace(/"/g, '\\"');
        res.set({
            'Content-Disposition': `attachment; filename="${safeFilename}"`,
            'Content-Type': result.mimeType || 'application/octet-stream',
        });
        res.send(result.buffer);
    }

    @Delete('documents/:documentId') 
    async deleteSubmissionDocument(@Param('documentId') documentId: number): Promise<any> {
        try {
            return await this.nczformsService.deleteSubmissionDocument(documentId, true);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}

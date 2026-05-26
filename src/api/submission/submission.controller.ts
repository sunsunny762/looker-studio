import { Body, Controller, Get, Param, Post, Put, Delete, Req, Res, HttpException, HttpStatus, Query, ParseIntPipe } from '@nestjs/common';
import { SubmissionService } from './submission.service';
import { FormService } from '../../jotform/form.service';
import { CompanyService } from '../company/company.service';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { FirebaseAuthService } from '../../firebase/firebase-auth.service';
import { Response } from 'express';
import * as archiver from 'archiver';

@Controller('submissions')
export class SubmissionController {

    constructor(private readonly submissionService: SubmissionService,
        private readonly firebaseAuthService: FirebaseAuthService,
                private readonly companyService: CompanyService,
                private readonly formService: FormService,
                private readonly errorLoggerService: ErrorLoggerService
    ) { }

    // @Post('/search')
    // async searchSubmissions(@Req() req: any, @Body() body: any): Promise<any> {
    //     try {
    //         const {status, certYear, progId } = body;
    //         return await this.submissionService.getSubmissions(null, status, certYear, progId);
    //     } catch (error)
    //     {
    //         throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    //     }
    // }

    // @Get()
    // async getSubmissions(): Promise<any> {
    //     try {
    //         return await this.submissionService.getSubmissions(null, null, null, null);
    //     } catch (error)
    //     {
    //         throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    //     }
    // }

    @Get('/:certId')
    async getSubmission(@Param('certId', ParseIntPipe) certId: number): Promise<any> {
        return await this.submissionService.getSubmissions(certId);
    }

    @Get('/tiles/:certId/:locId?')
    async getSubmissionTiles(@Param('certId') certId: string, @Param('locId') locId: string, @Req() req: any): Promise<any> {
	const uCompanyId = await this.firebaseAuthService.getUserCompanyId(req);
	return await this.submissionService.getSubmissionTiles(parseInt(certId), parseInt(locId), uCompanyId);
}

    @Get('/all-forms/:certId')
    async getAllFormsForExport(@Param('certId', ParseIntPipe) certId: number): Promise<any> {
        return await this.submissionService.getAllForms(certId);
    }

    @Get('/documents/:certId')
    async getCertificationSubmissionDocuments(@Param('certId', ParseIntPipe) certId: number): Promise<any> {
        return await this.submissionService.getCertificationSubmissionDocuments(certId);
    }

    @Get('/documents/download/:documentKey')
    async downloadSubmissionDocument(@Param('documentKey') documentKey: string, @Res() res: Response): Promise<void> {
        const result = await this.submissionService.getSubmissionDocumentDownload(decodeURIComponent(documentKey));
        if (!result) {
            throw new HttpException('Document not found', HttpStatus.NOT_FOUND);
        }

        const filename = this.submissionService.getDownloadFileName(result.document).replace(/"/g, "'");
        res.set({
            'Content-Disposition': `attachment; filename="${filename}"`,
            'Content-Type': 'application/octet-stream',
        });
        res.send(result.buffer);
    }

    @Post('/documents/download-zip')
    async downloadSubmissionDocumentsZip(@Body() body: { documentKeys?: string[] }, @Res() res: Response): Promise<void> {
        const documentKeys = Array.isArray(body?.documentKeys)
            ? Array.from(new Set(body.documentKeys.map((key) => String(key ?? '').trim()).filter(Boolean)))
            : [];

        if (!documentKeys.length) {
            throw new HttpException('No documents selected', HttpStatus.BAD_REQUEST);
        }

        const zipEntries: Array<{ name: string; buffer: Buffer }> = [];
        const usedNames = new Set<string>();
        for (const documentKey of documentKeys) {
            const result = await this.submissionService.getSubmissionDocumentDownload(documentKey);
            if (!result) {
                continue;
            }

            zipEntries.push({
                name: this.submissionService.getZipEntryName(result.document, usedNames),
                buffer: result.buffer,
            });
        }

        if (!zipEntries.length) {
            throw new HttpException('No documents found for selected keys', HttpStatus.NOT_FOUND);
        }

        res.set({
            'Content-Disposition': 'attachment; filename="NCZ_Submission_Documents.zip"',
            'Content-Type': 'application/zip',
        });

        const archive = archiver('zip', { zlib: { level: 9 } });
        archive.on('error', () => {
            if (!res.writableEnded) {
                res.end();
            }
        });
        archive.pipe(res);

        for (const entry of zipEntries) {
            archive.append(entry.buffer, { name: entry.name });
        }

        await archive.finalize();
    }

    // @Get('/tiles/:certId/:locId?')
    // async getSubmissionTiles(@Param('certId', ParseIntPipe) certId: number, @Param('locId', ParseIntPipe) locId: number, @Req() req: any): Promise<any> {
    //     const uCompanyId = await this.firebaseAuthService.getUserCompanyId(req);
    //     return await this.submissionService.getSubmissionTiles(certId, locId, uCompanyId);
    // }

    @Get('/other-submission-tiles/:certId')
    async getOtherSubmissionTiles(@Param('certId', ParseIntPipe) certId: number, @Req() req: any): Promise<any> {
        const uCompanyId = await this.firebaseAuthService.getUserCompanyId(req);
        return await this.submissionService.getOtherSubmissionTiles(certId, uCompanyId);
    }

    @Get('/progform/:certId/:progformId/:locId?')
    async getSubmissionByProgForm(@Param('certId', ParseIntPipe) certId: number, @Param('progformId', ParseIntPipe) progFormId: number, @Param('locId') locId: string): Promise<any> {
        return await this.submissionService.getSubmissionByProgForm(certId, progFormId, parseInt(locId));
    }

     @Get('/other-progform/:certId/:progformId')
    async getOtherSubmissionByProgForm(@Param('certId', ParseIntPipe) certId: number, @Param('progformId', ParseIntPipe) progFormId: number): Promise<any> {
        return await this.submissionService.getOtherSubmissionByProgForm(certId, progFormId);
    }

    @Get('/chw/:certId')
    async getCHWSubmission(@Param('certId', ParseIntPipe) certId: number): Promise<any> {
        return await this.submissionService.getSubmissions(certId, 1);
    }

    @Get('jotform/:certsubmissionId') // Fetch Jotform submission data for View through API
    async getJotformSubmission(@Param('certsubmissionId', ParseIntPipe) certsubmissionId: number): Promise<any> {
        return await this.submissionService.getJotformSubmission(certsubmissionId);
    }

    @Get('details/:certsubmissionId')
    async getSubmissionDetails(@Param('certsubmissionId', ParseIntPipe) certsubmissionId: number, @Req() req: any): Promise<any> {
        const uCompanyId = await this.firebaseAuthService.getUserCompanyId(req);
        return await this.submissionService.getSubmissionDetails(certsubmissionId, uCompanyId);
    }

    @Get('/emission-detail/:certSubmissionId/:emissionProfileId')
        async getSubmissionEmissionDetailsApi(
        @Param('certSubmissionId', ParseIntPipe) certSubmissionId: number,
        @Param('emissionProfileId', ParseIntPipe) emissionProfileId: number,
        ) {
        return await this.submissionService.getSubmissionEmissionDetails(
            certSubmissionId,
            emissionProfileId,
        );
    }

    // @Get('/company/:companyId')
    // async getSubmissionsByCompany(@Param('companyId') companyId: string): Promise<any> {
    //     return await this.submissionService.getSubmissionsByCompany(parseInt(companyId));
    // }

    // @Get('/submissions/:certId')
    // async getCertSubmissions(@Param('certId') certId: string): Promise<any> {
    //     try {
    //         return await this.submissionService.getCertSubmissions(parseInt(certId));
    //     } catch (error)
    //     {
    //         throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    //     }
    // }

    @Post()
    async addSubmission(@Req() req: any, @Body() body: any): Promise<any> {
        try {
            const {
                certId, locationId, dimFormId, notes, userId, parentCertsubmissionId
            } = body;

            // Company Profile form, If multiple locations, create parent-child submissions
            if (Array.isArray(locationId) && locationId.length > 0) {
                let parentCSId = null; // newly added parentCertSubmissionId;
                let parentSubmissionRecord = null;
                for (const locId of locationId) {
                    const res = await this.submissionService.addSubmission(certId, locId, dimFormId, notes, userId, parentCSId);
                    if (res && res.length > 0 && !parentCSId) {
                        parentSubmissionRecord = res;
                        parentCSId = res[0].certsubmissionId;
                    }
                }
                return parentSubmissionRecord;
            }
            else
                return await this.submissionService.addSubmission(certId, locationId, dimFormId, notes, userId, parentCertsubmissionId);

        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Post('replace-cmp') // Special handling for Company Profile replacement
    async replaceCMPSubmission(@Req() req: any, @Body() body: any): Promise<any> {
        try {
            const {
                certId, locationId, dimFormId, notes, userId, parentCertsubmissionId, certsubmissionIdToReplace
            } = body;

            if (certsubmissionIdToReplace) { // For Company Profile replacement, delete the old submission
                try {
                    await this.deleteSubmission(certsubmissionIdToReplace);
                } catch (error) {
                    throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
                }
            }
            
            return await this.submissionService.addSubmission(certId, locationId, dimFormId, notes, userId, parentCertsubmissionId);

        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // @Put('/:certsubmissionId')
    // async updateSubmission(@Param('certsubmissionId') certsubmissionId: string, @Body() body: any): Promise<any> {
    //     if (certsubmissionId != body.certsubmissionId) return null;
    //     try {
    //         const {
    //             certId, companyId, progId, startDate, refNumber, status,
    //             description, clickupTaskId
    //         } = body;

    //         return await this.submissionService.updateSubmission(certId, companyId, progId, startDate, refNumber, status,
    //             description, clickupTaskId);
    //     } catch (error)
    //     {
    //         throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    //     }
    // }

    @Delete('/:certsubmissionId') 
    async deleteSubmission(@Param('certsubmissionId', ParseIntPipe) certsubmissionId: number): Promise<any> {
        try {
            return await this.submissionService.deleteSubmission(certsubmissionId);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}

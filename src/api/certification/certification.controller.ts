import { Body, Controller, Get, Param, Post, Put, Delete, Req, HttpException, HttpStatus, Query, Res, UploadedFile, UseInterceptors } from '@nestjs/common';
import { CertificationService } from './certification.service';
import { FormService } from '../../jotform/form.service';
import { CompanyService } from '../company/company.service';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { de, el } from 'date-fns/locale';
import { Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { JotformService } from '../../jotform/jotoform.service';
import { NotificationsService } from '../../notifications/notifications.service';

@Controller('certifications')
export class CertificationController {

    constructor(private readonly certificationService: CertificationService,
                private readonly companyService: CompanyService,
                private readonly formService: FormService,
                private readonly jotformService: JotformService,
                private readonly errorLoggerService: ErrorLoggerService,
                private readonly notificationsService: NotificationsService,
    ) { }

    @Post('/search')
    async searchCertifications(@Req() req: any, @Body() body: any): Promise<any> {
        try {
            const {status, certYear, progId } = body;
            return await this.certificationService.getCertifications(null, status, certYear, progId);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get()
    async getCertifications(): Promise<any> {
        try {
            return await this.certificationService.getCertifications(null, null, null, null);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/blueawards')
    async getBlueAwardCertifications(): Promise<any> {
        try {
            return await this.certificationService.getBlueAwardCertifications();
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/blueawards/:certSubmissionId')
    async getBlueAwardCertificationById(@Param('certSubmissionId') certSubmissionId: string): Promise<any> {
        try {
            const result = await this.certificationService.getBlueAwardCertificationById(parseInt(certSubmissionId));
            if (!result) {
                throw new HttpException('Blue award certification not found', HttpStatus.NOT_FOUND);
            }
            return result;
        } catch (error)
        {
            throw new HttpException(error.message, error.status || HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/blueawards/:certSubmissionId/documents')
    async getBlueAwardDocuments(@Param('certSubmissionId') certSubmissionId: string): Promise<any> {
        try {
            return await this.certificationService.getBlueAwardDocuments(parseInt(certSubmissionId));
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/blueawards/count')
    async getBlueAwardCertificationsCount(): Promise<any> {
        try {
            return await this.certificationService.getBlueAwardCertificationsCount();
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Put('/blueawards/:certSubmissionId/status')
    async updateBlueAwardStatus(@Param('certSubmissionId') certSubmissionId: string, @Body() body: any): Promise<any> {
        try {
            const { status, notes } = body;
            const result = await this.certificationService.updateBlueAwardStatus(parseInt(certSubmissionId), status, notes);
            
            // Broadcast updated count to all connected clients
            const blueAwardCount = await this.certificationService.getBlueAwardCertificationsCount();
            await this.notificationsService.broadcastBlueAwardCount(blueAwardCount);

            return result;
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Delete('/blueawards/:certSubmissionId')
    async deleteBlueAwardCertification(@Param('certSubmissionId') certSubmissionId: string): Promise<any> {
        try {
            const result = await this.certificationService.deleteBlueAwardCertification(parseInt(certSubmissionId));
            
            // Broadcast updated count to all connected clients
            const blueAwardCount = await this.certificationService.getBlueAwardCertificationsCount();
            await this.notificationsService.broadcastBlueAwardCount(blueAwardCount);

            return result;

        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/company/:companyId')
    async getCertificationsByCompany(@Param('companyId') companyId: string): Promise<any> {
        return await this.certificationService.getCertificationsByCompany(parseInt(companyId));
    }

    @Get('/:certId')
    async getCertification(@Param('certId') certId: string): Promise<any> {
        return await this.certificationService.getCertifications(parseInt(certId), null, null, null);
    }
 
    @Get('/documents/:certId')
    async getCertificationDocuments(@Param('certId') certId: string): Promise<any> {
        return await this.certificationService.getCertificationDocuments(parseInt(certId));
    }

    @Get('/documents/standard/:progId/:certId')
    async getCertStandardDocuments(@Param('progId') progId: string, @Param('certId') certId: string): Promise<any> {
        return await this.certificationService.getCertStandardDocuments( parseInt(progId), parseInt(certId));
    }

    @Get('documents/download/:documentId')
    async downloadFile(@Param('documentId') documentId: number, @Res() res: Response) {
        const fileBuffer = await this.certificationService.getDocumentDownload(documentId);
        res.set({
        'Content-Disposition': `attachment; filename="myFile.pdf"`,
        'Content-Type': 'application/octet-stream',
        });
        res.send(fileBuffer);
    }
    
    @Get('/documents/view/:documentId')
    async getDocumentViewUrl(@Param('documentId') documentId: number): Promise<any> {
        try {
            return await this.certificationService.getDocumentUrl(documentId);
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    // @Get('/submissions/:certId')
    // async getCertSubmissions(@Param('certId') certId: string): Promise<any> {
    //     try {
    //         return await this.certificationService.getCertSubmissions(parseInt(certId));
    //     } catch (error)
    //     {
    //         throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
    //     }
    // }

    @Post()
    async addCertification(@Req() req: any, @Body() body: any): Promise<any> {
        try {
            const {
                companyId, progId, startDate, status,
                description, certificationTaskId, refNumber, createTask, documentIds,
                emissionProfileId, revenue, headCount
            } = body;

            const res = await this.companyService.getCompanies(companyId, null);
            const company = res[0];

            let newCompanyTaskId = company.companyTaskId;
            let newPersonTaskId = company.personTaskId;
            let newCertificationTaskId = certificationTaskId;

            const taskResult: any = {
                companyTaskId: newCompanyTaskId,
                personTaskId: newPersonTaskId,
                certTaskId: newCertificationTaskId,
                tasks: [],
                certTaskCreated: false,
            };

            const parsedStartDate = new Date(startDate);
            const buildDate = parsedStartDate.getTime();

            if (createTask) {
                if (!newCompanyTaskId) {
                    const companyTaskData = {
                        BAQ_CompanyName: company.companyName,
                        BAQ_CompanyDescription: company.description || 'Certification company entry',
                        BAQ_CompanyIndustry: company.industryTypeStr,
                        BAQ_CompanyWebsite: company.website,
                        BAQ_Phone: company.phone || '',
                    };

                    const companyTaskResponse = await this.jotformService._createCompanyTask(
                        'Company',
                        companyTaskData,
                        buildDate
                    );

                    if (companyTaskResponse?.id) {
                        newCompanyTaskId = companyTaskResponse.id;
                        taskResult.companyTaskId = newCompanyTaskId;
                    }
                } else {
                    taskResult.companyTaskId = newCompanyTaskId;
                }
                if (!newPersonTaskId) {
                    const personTaskData = {
                        BAQ_YourName: company.contactName,
                        BAQ_Email: company.email,
                        BAQ_Phone: company.phone || '',
                        BAQ_CompanyName: company.companyName,
                        BAQ_JobTitle: company.jobTitle,
                    };
                    const personTaskResponse = await this.jotformService._createPersonTask(
                        'People',
                        personTaskData,
                        newCompanyTaskId ?? '',
                        buildDate
                    );

                    if (personTaskResponse?.id) {
                        newPersonTaskId = personTaskResponse.id;
                        taskResult.personTaskId = newPersonTaskId;
                    }
                } else {
                    taskResult.personTaskId = newPersonTaskId;
                }
                const resClickupTask = await this.formService._createPortalCertificationTask(
                    progId,
                    company.companyName,
                    refNumber,
                    company.phone,
                    company.email,
                    company.contactName,
                    company.jobTitle,
                    buildDate
                );

                if (!resClickupTask.success) {
                    throw new HttpException(resClickupTask.message, HttpStatus.INTERNAL_SERVER_ERROR);
                } else {
                    newCertificationTaskId = resClickupTask.data.id;
                    taskResult.certTaskId = newCertificationTaskId;
                    taskResult.certTaskCreated = true;
                }

                if (!company.companyTaskId || !company.personTaskId) {
                    await this.certificationService.updateCompanyTaskIds(
                        company.companyId,
                        newCompanyTaskId,
                        newPersonTaskId
                    );
                }
            } else {
                taskResult.certTaskCreated = true;
            }

            if (newCertificationTaskId) {
                const results = await this.certificationService.addCertification(
                    companyId,
                    progId,
                    startDate,
                    refNumber,
                    status,
                    description,
                    newCertificationTaskId,
                    emissionProfileId,
                    revenue,
                    headCount ?? null
                );
                const certId = results[0].certId;
                if (documentIds && documentIds.length > 0) {
                    for (const documentId of documentIds) {
                        await this.certificationService.addCertificationDocument(certId, documentId, null);
                    }
                }

                const jsonObj = {
                    BAQ_CompanyName: company.companyName,
                    BAQ_CompanyDescription: company.description || 'Certification company entry',
                };

                await this.formService.createRelationships(taskResult, jsonObj);

                return results;
            }
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Put('/:certId')
    async updateCertification(@Param('certId') paramCertId: string, @Body() body: any): Promise<any> {
        if (paramCertId != body.certId) return null;
        try {
            const {
                certId, companyId, progId, startDate, refNumber, status,
                description, certificationTaskId, emissionProfileId, revenue, headCount, documentIds
            } = body;

            const results = await this.certificationService.updateCertification(certId, companyId, progId, startDate, refNumber, status,
                description, certificationTaskId, emissionProfileId, revenue, headCount ?? null);
            if (documentIds && documentIds.length > 0) {
                for (const documentId of documentIds) {
                    await this.certificationService.addCertificationDocument(certId, documentId, null);
                }
            }
            return results;
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Delete('/:certId') 
    async deleteCertification(@Param('certId') certId: string): Promise<any> {
        try {
            return await this.certificationService.deleteCertification(parseInt(certId));
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Post('/documents/upload')
    @UseInterceptors(FileInterceptor('file'))
    async uploadCertificationDocument(
        @UploadedFile() file: Express.Multer.File,
        @Body() body: any
    ) {
        try {
            const result = await this.certificationService.uploadCertificationDocument(file, body);
            return result;
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Post('/blueawards/documents/upload')
    @UseInterceptors(FileInterceptor('file'))
    async uploadBlueAwardDocument(
        @UploadedFile() file: Express.Multer.File,
        @Body() body: any
    ) {
        try {
            return await this.certificationService.uploadBlueAwardDocument(file, body);
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Post('/documents/add')
    async addCertificationDocument(@Body() body: any): Promise<any> {
        try {
            for (const documentId of body.documentIds) {
                await this.certificationService.addCertificationDocument(body.certId, documentId, null);
            }
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Delete('/documents/deleteFile/:certId/:documentId')// To delete Certification specific Document and its file
    async deleteCertificationDocumentFile(@Param('certId') certId: number, @Param('documentId') documentId: number): Promise<any> {
        try {
            return await this.certificationService.deleteCertificationDocument(certId, documentId, true);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    @Delete('/documents/delete/:certId/:documentId') // To delete Certification Document attached from ProgDocuments
    async deleteCertificationDocument(@Param('certId') certId: number, @Param('documentId') documentId: number): Promise<any> {
        try {
            return await this.certificationService.deleteCertificationDocument(certId, documentId, false);
        } catch (error)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Put('/documents/:certId/:documentId/mark-certification')
    async markCertificationDocument(
        @Param('certId') certId: string,
        @Param('documentId') documentId: string
    ): Promise<any> {
        try {
            return await this.certificationService.markCertificationDocument(
                parseInt(certId),
                parseInt(documentId)
            );
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Delete('/documents/:certId/:documentId/mark-certification')
    async unmarkCertificationDocument(
        @Param('certId') certId: string,
        @Param('documentId') documentId: string
    ): Promise<any> {
        try {
            return await this.certificationService.unmarkCertificationDocument(
                parseInt(certId),
                parseInt(documentId)
            );
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Delete('/blueawards/:certSubmissionId/documents/deleteFile/:documentId')
    async deleteBlueAwardDocumentFile(
        @Param('certSubmissionId') certSubmissionId: number,
        @Param('documentId') documentId: number
    ): Promise<any> {
        try {
            return await this.certificationService.deleteBlueAwardDocument(certSubmissionId, documentId, true);
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/chw-tokens/:certId')
    async getCHWTokens(@Param('certId') certId: string): Promise<any> {
        try {
            return await this.certificationService.getCHWTokens(parseInt(certId));
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/headcount/:certId')
    async getCertificationHeadCount(@Param('certId') certId: string): Promise<any> {
        try {
            return await this.certificationService.getCertificationHeadCount(parseInt(certId));
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Post('/headcount/:certId')
    async saveCertificationHeadCount(@Param('certId') certId: string, @Body() body: any): Promise<any> {
        try {
            const { headCount, revenue, locations } = body;
            return await this.certificationService.saveCertificationHeadCount(
                parseInt(certId),
                headCount ?? null,
                revenue ?? null,
                locations || []
            );
        } catch (error) {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}

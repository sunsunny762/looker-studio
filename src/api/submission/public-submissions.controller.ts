import { Body, Controller, Get, Param, Post, HttpException, HttpStatus, UseGuards, Req, Put, ParseIntPipe, Query, Delete, Res, UploadedFile, UploadedFiles, UseInterceptors } from '@nestjs/common';
import { SubmissionService } from './submission.service';
import { NczformsService } from '../nczforms/nczforms.service';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { TokenAuthGuard } from '../token/guards/token-auth.guard';
import { FileInterceptor, FilesInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { NotificationsService } from '../../notifications/notifications.service';
import { CertificationService } from '../certification/certification.service';
import { TokenService } from '../token/token.service';
import { CompanyService } from '../company/company.service';
import { CartService } from '../cart/cart.service';
import { ValidateCouponDto, CreateCheckoutSessionDto } from '../cart/cart.dto';
import 'multer';

@Controller('public')
@UseGuards(TokenAuthGuard)
export class PublicSubmissionsController {

    constructor(
        private readonly submissionService: SubmissionService,
        private readonly nczformsService: NczformsService,
        private readonly errorLoggerService: ErrorLoggerService,
        private readonly notificationsService: NotificationsService,
        private readonly certificationService: CertificationService,
        private readonly tokenService: TokenService,
        private readonly companyService: CompanyService,
        private readonly cartService: CartService
    ) { }

    
    @Get('/submissions/details/:certsubmissionId')
    async getSubmissionDetails(
        @Param('certsubmissionId', ParseIntPipe) certsubmissionId: number
    ): Promise<any> {
        try {
            return await this.submissionService.getSubmissionDetails(certsubmissionId, null);
        } catch (error: any) {
            await this.errorLoggerService.writeLogToDB(
                'PublicSubmissionsController.getSubmissionDetails',
                error
            );
            throw new HttpException(
                error.message || 'Failed to get submission details',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    // @Get('/chw/:certId')
    // async getCHWSubmission(
    //     @Param('certId', ParseIntPipe) certId: number
    // ): Promise<any> {
    //     try {
    //         return await this.submissionService.getSubmissions(certId, 1);
    //     } catch (error) {
    //         await this.errorLoggerService.writeLogToDB(
    //             'PublicSubmissionsController.getCHWSubmission',
    //             error
    //         );
    //         throw new HttpException(
    //             error.message || 'Failed to get CHW submission',
    //             error.status || HttpStatus.INTERNAL_SERVER_ERROR
    //         );
    //     }
    // }

    @Post('/submissions')
    async addSubmission( // Add Cert Submission Before Form Load
        @Body() body: any
    ): Promise<any> {
        try {

            const { certId, locationId, dimFormId, notes, userId, parentCertsubmissionId } = body;

            if (!certId || !locationId || !dimFormId) {
                throw new HttpException(
                    'Missing required fields',
                    HttpStatus.BAD_REQUEST
                );
            }

            let resSubmission = await this.submissionService.addSubmission(
                certId,
                locationId,
                dimFormId,
                notes || null,
                userId || null,
                parentCertsubmissionId || null
            );

            const submissionDetails = await this.submissionService.getSubmissionDetails(resSubmission[0].certsubmissionId, null);
            return submissionDetails.length > 0 ? submissionDetails[0] : submissionDetails;
        } catch (error: any) {
            await this.errorLoggerService.writeLogToDB(
                'PublicSubmissionsController.addSubmission',
                error
            );
            throw new HttpException(
                error.message || 'Failed to add submission',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    @Post('/submissions/nczdirectory-supplier')
    async addNCZDirectorySupplier(@Req() req: any, @Body() body: any): Promise<any> { // on NCZ Partner Form Submission, add entry to NCZ Directory Supplier table
        try {
            const { submissionId } = body;

            return await this.companyService.addNCZDirectorySupplier( submissionId );
        } catch (error: any) {
            await this.errorLoggerService.writeLogToDB(
                'PublicSubmissionsController.addNCZDirectorySupplier',
                error
            );
            throw new HttpException(
                error.message || 'Failed to add NCZ directory supplier',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    @Post('/submissions/blueaward')
    async addBlueAwardSubmission(@Req() req: any, @Body() body: any): Promise<any> { // Add Blue Award Certification After Form Submitted
        try {
            const {
                dimFormId, submissionId
            } = body;

            const results = await this.submissionService.addBlueAwardCertification(dimFormId, submissionId);

            // Broadcast updated count to all connected clients
            const blueAwardCount = await this.certificationService.getBlueAwardCertificationsCount();
            await this.notificationsService.broadcastBlueAwardCount(blueAwardCount);

            return results;
        } catch (error: any)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Post('/submissions/chw')
    async addChwSubmission(@Req() req: any, @Body() body: any): Promise<any> { // Add Cert Submission Before Form Load
        try {
            const {
                certId, locationId, dimFormId, email
            } = body;

            const results = await this.submissionService.checkCHWFormSubmission(certId, locationId, dimFormId, email);
            let certSubmissionId;
            if (results && results.length > 0) { // Existing submission found
                certSubmissionId = results[0].certsubmissionId;
            }
            else {
                const { certId, locationId, dimFormId, notes, userId, parentCertsubmissionId } = body;
                if (!certId || !locationId || !dimFormId) {
                    throw new HttpException(
                        'Missing required fields',
                        HttpStatus.BAD_REQUEST
                    );
                }

                let resSubmission = await this.submissionService.addSubmission(
                    certId,
                    locationId,
                    dimFormId,
                    notes || null,
                    userId || null,
                    parentCertsubmissionId || null
                );
                
                certSubmissionId = resSubmission[0].certsubmissionId;
            }

            const submissionDetails = await this.submissionService.getSubmissionDetails(certSubmissionId, null);
            return submissionDetails.length > 0 ? submissionDetails[0] : submissionDetails;
        } catch (error: any)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }


    @Post('/nczforms/submission')
    async createFormSubmission(
        @Body() body: {
            formId: number;
            userId: number;
            responses: any;
            submissionData: any;
            isDraft?: boolean;
        }
    ) {
        const { formId, userId, responses, submissionData, isDraft = false } = body;
        return await this.nczformsService.saveFormSubmission(formId, null, userId, responses, submissionData, isDraft);
    }

    @Put('/nczforms/submission/:submissionId')
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
    }

    @Get('/nczforms/submission/:submissionId')
    async getFormSubmission(
        @Param('submissionId', ParseIntPipe) submissionId: number
    ) {
        return await this.nczformsService.getFormSubmission(submissionId);
    }

    @Get('/nczforms/:formId/config')
    async getFormConfiguration(@Param('formId', ParseIntPipe) formId: number) {
        return this.nczformsService.getFormConfiguration(formId);
    }

    @Get('/nczforms/dimform/:dimFormId')
    async getDimFormDetails(@Param('dimFormId', ParseIntPipe) dimFormId: number) {
        return this.submissionService.getDimFormDetails(dimFormId);
    }
    
    @Get('/nczforms/countries/search')
    async getCountryByName(@Query('search') search: string) {
        return this.nczformsService.getCountriesByName(search);
    }

    @Get('/nczforms/currencies/search')
    async getCurrencyByName(@Query('search') search: string) {
        return this.nczformsService.getCurrenciesByName(search);
    }

    @Get('/nczforms/documents/submission/:certSubmissionId/question/:questionId')
    async getSubmissionDocumentsbyQuestion(@Param('certSubmissionId', ParseIntPipe) certSubmissionId: number, @Param('questionId', ParseIntPipe) questionId: number) {
        return this.nczformsService.getSubmissionDocumentsbyQuestion(certSubmissionId, questionId);
    }

    @Post('/nczforms/documents/upload')
    @UseInterceptors(FileInterceptor('file'))
    async uploadSubmissionDocument(
        @UploadedFile() file: Express.Multer.File,
        @Body() body: any
    ) {
        const result = await this.nczformsService.uploadSubmissionDocument(file, body);
        return result;
    }

    @Post('/nczforms/documents/upload-multiple')
    @UseInterceptors(FilesInterceptor('files'))
    async uploadSubmissionDocuments(
        @UploadedFiles() files: Express.Multer.File[],
        @Body() body: any
    ) {
        const result = await this.nczformsService.uploadSubmissionDocuments(files, body);
        return result;
    }

    @Get('/nczforms/documents/download/:documentId')
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

    /**
     * Download a blue award certificate document
     * Requires token authentication
     * NOTE: This route must come BEFORE /blueawards/:certSubmissionId to avoid route collision
     */
    @Get('/blueawards/download/:documentId')
    async downloadBlueAwardDocument(
        @Param('documentId') documentId: number,
        @Res() res: Response
    ): Promise<void> {
        try {
            const fileBuffer = await this.certificationService.getDocumentDownload(documentId);
            
            if (!fileBuffer) {
                throw new HttpException('Document not found', HttpStatus.NOT_FOUND);
            }
            
            res.set({
                'Content-Disposition': `attachment; filename="Blue-Award-Certificate.pdf"`,
                'Content-Type': 'application/pdf',
            });
            res.send(fileBuffer);
        } catch (error: any) {
            await this.errorLoggerService.writeLogToDB(
                'PublicSubmissionsController.downloadBlueAwardDocument',
                error
            );
            throw new HttpException(
                error.message || 'Failed to download certificate',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    /**
     * Get a specific blue award certification by certSubmissionId
     * Requires token authentication
     */
    @Get('/blueawards/:certSubmissionId')
    async getBlueAwardCertificationById(
        @Param('certSubmissionId') certSubmissionId: string,
        @Req() req: any
    ): Promise<any> {
        try {
            const result = await this.certificationService.getBlueAwardCertificationById(parseInt(certSubmissionId));
            
            if (!result) {
                throw new HttpException('Blue award certification not found', HttpStatus.NOT_FOUND);
            }
            
            return result;
        } catch (error: any) {
            await this.errorLoggerService.writeLogToDB(
                'PublicSubmissionsController.getBlueAwardCertificationById',
                error
            );
            throw new HttpException(
                error.message || 'Failed to get blue award certification',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR
            );
        }
    }

    @Delete('/nczforms/documents/:documentId') 
    async deleteSubmissionDocument(@Param('documentId') documentId: number): Promise<any> {
        try {
            return await this.nczformsService.deleteSubmissionDocument(documentId, true);
        } catch (error: any)
        {
            throw new HttpException(error.message, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ── Cart (guest checkout) ─────────────────────────────────────────────────

    @Post('/cart/validate-coupon')
    async validateCoupon(@Body() dto: ValidateCouponDto): Promise<any> {
        try {
            return await this.cartService.validateCoupon(dto);
        } catch (error: any) {
            await this.errorLoggerService.writeLogToDB('PublicSubmissionsController.validateCoupon', error);
            throw new HttpException(
                error.message || 'Failed to validate coupon',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR,
            );
        }
    }

    @Get('/cart/config/:cartConfigId')
    async getCartConfig(@Param('cartConfigId', ParseIntPipe) cartConfigId: number): Promise<any> {
        try {
            return await this.cartService.getCartConfig(cartConfigId);
        } catch (error: any) {
            await this.errorLoggerService.writeLogToDB('PublicSubmissionsController.getCartConfig', error);
            throw new HttpException(
                error.message || 'Failed to get cart config',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR,
            );
        }
    }

    @Post('/cart/checkout-session')
    async createCheckoutSession(@Body() dto: CreateCheckoutSessionDto): Promise<any> {
        try {
            return await this.cartService.createCheckoutSession(dto);
        } catch (error: any) {
            await this.errorLoggerService.writeLogToDB('PublicSubmissionsController.createCheckoutSession', error);
            throw new HttpException(
                error.message || 'Failed to create checkout session',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR,
            );
        }
    }

    @Get('/cart/session/:sessionId/verify')
    async verifyCartSession(@Param('sessionId') sessionId: string): Promise<any> {
        try {
            return await this.cartService.verifySession(sessionId);
        } catch (error: any) {
            await this.errorLoggerService.writeLogToDB('PublicSubmissionsController.verifyCartSession', error);
            throw new HttpException(
                error.message || 'Failed to verify session',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR,
            );
        }
    }
}

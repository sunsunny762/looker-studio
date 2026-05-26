import { Body, Controller, Post, HttpException, HttpStatus, UseGuards } from '@nestjs/common';
import { PublicFormsService } from './public-forms.service';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { TokenAuthGuard } from '../token/guards/token-auth.guard';

/**
 * Handles public (token-authenticated) form submissions from external customers.
 * The customer receives a URL with a token, opens the form in their browser,
 * and POSTs their answers here.
 */
@Controller('public/form-submissions')
@UseGuards(TokenAuthGuard)
export class PublicFormTokenController {
    constructor(
        private readonly publicFormsService: PublicFormsService,
        private readonly errorLoggerService: ErrorLoggerService,
    ) {}

    @Post()
    async submitForm(@Body() body: any): Promise<any> {
        try {
            const { dimFormId, submissionId, certId, notes, properties } = body;

            if (!dimFormId) {
                throw new HttpException('dimFormId is required', HttpStatus.BAD_REQUEST);
            }

            const propertiesStr =
                properties && typeof properties !== 'string'
                    ? JSON.stringify(properties)
                    : properties ?? null;

            const result = await this.publicFormsService.saveSubmission(
                dimFormId,
                submissionId ?? null,
                certId ?? null,
                notes ?? null,
                propertiesStr,
            );

            return { success: true, psubmissionId: result?.psubmissionId };
        } catch (error) {
            await this.errorLoggerService.writeLogToDB('PublicFormTokenController.submitForm', error);
            throw new HttpException(
                error.message || 'Failed to save form submission',
                error.status || HttpStatus.INTERNAL_SERVER_ERROR,
            );
        }
    }
}

import { BadRequestException, Body, Controller, Get, HttpException, HttpStatus, Param, Post, Query, Req, Res } from '@nestjs/common';
import { Response } from 'express';
// import { ReportAdminService } from './report-admin.service';
import { ReportService } from './report.service';

@Controller('report')
export class ReportController {
    constructor(
        private readonly reportService: ReportService,
        //private readonly reportAdminService: ReportAdminService,
    ) { }

    private buildDownloadFileName(fileName: string | undefined, defaultBaseName: string, contentType: string): string {
        const safeBaseName = (fileName || defaultBaseName).replace(/[^a-zA-Z0-9._-]/g, '_');
        const isPdf = contentType.toLowerCase().includes('application/pdf');
        const extension = isPdf ? '.pdf' : '.bin';
        return safeBaseName.toLowerCase().endsWith(extension) ? safeBaseName : `${safeBaseName}${extension}`;
    }

    @Get('/week-status-report')
    @Get('/week-status-report/:companyId')
    async getCertificationWeekStatusReport(
        @Param('companyId') companyId?: string,
    ): Promise<any> {
        const id = companyId ? parseInt(companyId) : 0;
        return await this.reportService.getCertificationWeekStatusReport(id);
    }

    @Get('/certification-report-data')
    async getCertificationReportData() {
        return await this.reportService.getCertificationReportData();
    }

    @Get('/report-issued-data')
    async getReportIssuedData() {
        return await this.reportService.getReportIssuedData();
    }

    @Get('/supplier-report-data')
    async getSupplierReportData() {
        return await this.reportService.getSupplierReportData();
    }

    @Get('/certification-all-status-report')
    getCertificationAllStatusReportNoId() {
        return this.reportService.getCertificationAllStatusReport(0);
    }

    @Get('/certification-all-status-report/:companyId')
    getCertificationAllWeekStatusReport(@Param('companyId') companyId: string) {
        return this.reportService.getCertificationAllStatusReport(parseInt(companyId));
    }

    @Get('/supplier-week-status-report')
    getSupplierWeekStatusReportNoId() {
        return this.reportService.getSupplierWeekStatusReport(0);
    }

    @Get('/supplier-week-status-report/:companyId')
    getSupplierWeekStatusReport(@Param('companyId') companyId: string) {
        return this.reportService.getSupplierWeekStatusReport(parseInt(companyId));
    }

    @Get('/report-issued-week-status-report')
    @Get('/report-issued-week-status-report/:companyId')
    async getReportIssuedWeekStatusReport(
        @Param('companyId') companyId?: string,
    ): Promise<any> {
        const id = companyId ? parseInt(companyId) : 0;
        return await this.reportService.getReportIssuedWeekStatusReport(id);
    }

    @Post('/blue-award/send-email')
    async sendBlueAwardEmail(@Req() req: any, @Body() body: { certSubmissionId: number }): Promise<any> {
        try {
            return await this.reportService.queueBlueAwardReportEmail(
                Number(body?.certSubmissionId),
                {
                    uid: String(req?.user?.uid ?? '').trim() || undefined,
                    email: String(req?.user?.email ?? '').trim() || undefined,
                },
            );
        } catch (error) {
            throw new HttpException(error.message, error.status || HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @Get('/looker-studio/blue-award/merged-download')
    async downloadMergedBlueAwardLookerStudioReport(
        @Query('submissionId') submissionId: string,
        @Query('p_submission_id') pSubmissionId: string | undefined,
        @Query('companyName') companyName: string | undefined,
        @Query('reportUrl') reportUrl: string | undefined,
        @Query('fileName') fileName: string | undefined,
        @Res() res: Response
    ): Promise<void> {
        const submissionIdValue = submissionId || pSubmissionId;
        if (!submissionIdValue) {
            throw new BadRequestException('submissionId (or p_submission_id) query parameter is required');
        }

        const parsedSubmissionId = parseInt(submissionIdValue, 10);
        if (!Number.isInteger(parsedSubmissionId) || parsedSubmissionId <= 0) {
            throw new BadRequestException('submissionId must be a positive integer');
        }

        const pageUrls = reportUrl ? [reportUrl] : undefined;
        const buffer = await this.reportService.downloadMergedBlueAwardLookerStudioPdf(parsedSubmissionId, pageUrls, companyName);
        const resolvedFileName = this.buildDownloadFileName(
            fileName,
            `blue-award-${parsedSubmissionId}`,
            'application/pdf'
        );

        res.set({
            'Content-Disposition': `attachment; filename="${resolvedFileName}"`,
            'Content-Type': 'application/pdf',
            'Content-Length': buffer.length
        });

        res.send(buffer);
    }
}

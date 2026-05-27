import { BadGatewayException, BadRequestException, Injectable } from '@nestjs/common';
import * as fs from 'fs';
import * as mssql from 'mssql';
import * as os from 'os';
import * as path from 'path';
import { PDFDocument } from 'pdf-lib';
import { DatabaseService } from '../../database';
import { DocumentsService } from '../../documents/documents.service';
import { FileUploadRequest } from '../../documents/model/file-upload-request';
import { EmailService } from '../../email/email.service';
import { EmailTemplates } from '../../email/model/emailTemplates';
export enum CertificationStatus {
    DataCollectionComplete = 2,
    ReportUnderProcess = 3,
    ReportGenerated = 4,
    CertificateIssued = 5,
}


@Injectable()
export class ReportService {
    private readonly blueAwardReportConfig = this.loadBlueAwardReportConfig();
    private readonly lookerStudioSubmissionUrlParamKey = this.blueAwardReportConfig.lookerStudioSubmissionUrlParamKey;
    private readonly lookerCaptureReadyTimeoutMs = this.blueAwardReportConfig.lookerCaptureReadyTimeoutMs;
    private readonly lookerPostLoadDelayMs = this.blueAwardReportConfig.lookerPostLoadDelayMs;
    private readonly defaultBlueAwardPageUrls = this.blueAwardReportConfig.defaultBlueAwardPageUrls;
    // private readonly baseUrl = process.env.FRONTEND_URL;

    constructor(
        private readonly databaseService: DatabaseService,
        private readonly emailService: EmailService,
        private readonly documentsService: DocumentsService,
    ) { }

    public async queueBlueAwardReportEmail(
        certSubmissionId: number,
        currentUser?: { uid?: string; email?: string },
        documentId?: number | null,
    ): Promise<any> {
        if (!Number.isInteger(certSubmissionId) || certSubmissionId <= 0) {
            throw new BadRequestException('certSubmissionId must be a positive integer');
        }

        const blueAward = await this.databaseService.execute('portal.spCertificationBlueAward_Get', [
            { name: 'certSubmissionId', type: mssql.TYPES.Int, value: certSubmissionId },
        ]);
        const record = blueAward?.results?.[0];

        if (!record) {
            throw new BadRequestException('Blue award certification not found');
        }

        const recipient = String(record.email || '').trim();
        if (!recipient) {
            throw new BadRequestException('Blue award recipient email not found');
        }

        const tokenResult = await this.createTokenForCertSubmission(certSubmissionId);
        const tokenKey = tokenResult?.tokenKey;
        if (!tokenKey) {
            throw new BadRequestException('Failed to create Blue Award token');
        }

        const submissionId = Number(record.submissionId);
        const templateData = {
            fullName: record.fullName || '',
            companyName: record.companyName || '',
            submissionId,
            certSubmissionId,
            documentId: documentId ?? null,
        };

        await this.queueBlueAwardDownloadEmail(recipient, tokenKey, templateData, currentUser);

        await this.databaseService.execute('[portal].[spCertificationBlueAwardStatus_Update]', [
            { name: 'certSubmissionId', type: mssql.TYPES.Int, value: certSubmissionId },
            { name: 'status', type: mssql.TYPES.Int, value: CertificationStatus.CertificateIssued },
            { name: 'notes', type: mssql.TYPES.NVarChar, value: 'Blue Award report download link emailed' },
            { name: 'documentId', type: mssql.TYPES.Int, value: documentId ?? null },
        ]);

        return {
            success: true,
            certSubmissionId,
            email: recipient,
            message: 'Blue Award email sent successfully',
        };
    }

    public async generateBlueAwardReport() {
        try {
            console.log('Generating Blue Award Reports...');
            const query = await this.databaseService.execute("[Reports].[spBlueCertificationCompletedData]");
            const responses = query.results || [];
            console.log(`Found ${responses.length} completed Blue Award certifications to process.`);

            for (const row of responses) {
                const submissionId = row?.submissionId;
                const certSubmissionId = row?.certSubmissionId;

                if (!submissionId || !certSubmissionId) {
                    continue;
                }

                try {
                    const fileName = `blue-award-report-${submissionId}`;
                    const uploadResult = await this.downloadAndStoreBlueAwardReport(submissionId, fileName);
                    const documentId = uploadResult?.id ?? uploadResult?.documentId ?? null;
                    console.log(`Report generated and stored for submissionId: ${submissionId}, documentId: ${documentId}`);
                    await this.databaseService.execute('[portal].[spCertificationBlueAwardStatus_Update]', [
                        { name: 'certSubmissionId', type: mssql.TYPES.Int, value: certSubmissionId },
                        { name: 'status', type: mssql.TYPES.Int, value: CertificationStatus.ReportGenerated },
                        { name: 'notes', type: mssql.TYPES.NVarChar, value: 'Blue Award report generated' },
                        { name: 'documentId', type: mssql.TYPES.Int, value: documentId },
                    ]);

                } catch (error) {
                    console.error(`Failed to generate/store report for submissionId: ${submissionId}`, error);
                }
            }

        } catch (error) {
            console.error('generateBlueAwardReport', error);
            return 0;
        }
    }

    public async queueGeneratedBlueAwardReportEmails() {
        try {
            const emailQuery = await this.databaseService.execute("[Reports].[spBlueCertificationReportGeneratedData]");
            const emailResponses = emailQuery.results || [];
            console.log(`Found ${emailResponses.length} generated Blue Award reports to email.`);

            for (const row of emailResponses) {
                const certSubmissionId = row?.certSubmissionId;
                const documentId = row?.documentId ?? null;
                const submissionId = row?.submissionId;

                if (!certSubmissionId) {
                    console.warn('Skipping generated Blue Award report email because certSubmissionId is missing.', row);
                    continue;
                }

                try {
                    await this.queueBlueAwardReportEmail(certSubmissionId, undefined, documentId);
                } catch (error) {
                    console.error(`Failed to queue Blue Award report email for certSubmissionId: ${certSubmissionId}, submissionId: ${submissionId}`, error);
                }
            }
        } catch (error) {
            console.error('queueGeneratedBlueAwardReportEmails', error);
            return 0;
        }
    }

    public async downloadAndStoreBlueAwardReport(submissionId: number, fileName: string): Promise<any> {
        const buffer = await this.downloadMergedBlueAwardLookerStudioPdf(submissionId);

        const file: any = {
            buffer: buffer,
            mimetype: 'application/pdf',
            originalname: fileName,
            fieldname: 'file',
            size: buffer.length,
            filename: fileName,
        };

        const request: FileUploadRequest = {
            id: null,
            parentEntityId: submissionId,
            parentEntityType: 'blue-award-report',
            customerId: 0,
            container: 'blue-award-report',
            blobName: fileName,
            title: fileName,
            singleInstance: false,
            canEmbed: false,
            modifiedDate: Date.now(),
            mimeType: 'application/pdf',
            size: buffer.length
        };

        return await this.documentsService.uploadBuffer(file, request);
    }

    private loadBlueAwardReportConfig() {
        const filePath = './config/blue-award-report.json';
        const fileContents = fs.readFileSync(filePath, 'utf-8');
        const parsed = JSON.parse(fileContents);
        const requiredPaths = [
            'lookerStudioSubmissionUrlParamKey',
            'defaultBlueAwardPageUrls',
            'lookerCaptureReadyTimeoutMs',
            'lookerPostLoadDelayMs',
            'viewport.width',
            'viewport.height',
            'viewport.deviceScaleFactor',
            'trims.left',
            'trims.top',
            'trims.right',
            'trims.bottom',
            'pdfLimits.maxWidth',
            'pdfLimits.maxHeight',
            'urlParams.submissionAliasKey',
            'urlParams.dashboardFilterKey',
            'urlParams.dashboardFilterTemplate',
            'urlParams.renderModeKey',
            'urlParams.renderModeValue',
            'render.gotoWaitUntil',
            'render.emulateMediaType',
            'behavior.lookerAllowedHosts',
            'behavior.minVisualCount',
            'behavior.minRichTextLength',
            'behavior.minIframeWidth',
            'behavior.minIframeHeight',
            'behavior.navigationTimeoutMs',
            'behavior.maxAttempts',
            'behavior.retryDelayMs',
            'behavior.horizontalPadding',
            'behavior.verticalPadding',
            'behavior.browserHeadless',
            'behavior.browserArgs'
        ];
        for (const pathKey of requiredPaths) {
            const value = pathKey.split('.').reduce((acc: any, key: string) => acc?.[key], parsed);
            if (value === undefined || value === null) {
                throw new Error(`Missing required blue-award-report config: ${pathKey}`);
            }
        }
        const navigationTimeoutOverride = Number(process.env.LOOKER_NAVIGATION_TIMEOUT_MS);
        if (Number.isFinite(navigationTimeoutOverride) && navigationTimeoutOverride > 0) {
            parsed.behavior.navigationTimeoutMs = navigationTimeoutOverride;
        }
        const postLoadDelayOverride = Number(process.env.LOOKER_POST_LOAD_DELAY_MS);
        if (Number.isFinite(postLoadDelayOverride) && postLoadDelayOverride >= 0) {
            parsed.lookerPostLoadDelayMs = postLoadDelayOverride;
        }
        const maxAttemptsOverride = Number(process.env.LOOKER_MAX_ATTEMPTS);
        if (Number.isInteger(maxAttemptsOverride) && maxAttemptsOverride > 0) {
            parsed.behavior.maxAttempts = maxAttemptsOverride;
        }
        const captureConcurrencyOverride = Number(process.env.LOOKER_CAPTURE_CONCURRENCY);
        if (Number.isInteger(captureConcurrencyOverride) && captureConcurrencyOverride > 0) {
            parsed.behavior.captureConcurrency = captureConcurrencyOverride;
        }
        const actionTimeoutOverride = Number(process.env.LOOKER_ACTION_TIMEOUT_MS);
        if (Number.isFinite(actionTimeoutOverride) && actionTimeoutOverride > 0) {
            parsed.behavior.actionTimeoutMs = actionTimeoutOverride;
        }
        return parsed;
    }

    private async resolvePuppeteerExecutablePath(chromium: any): Promise<{ executablePath?: string; isSparticuz: boolean }> {
        const candidatePaths = [
            process.env.LOOKER_PUPPETEER_EXECUTABLE_PATH,
            process.env.PUPPETEER_EXECUTABLE_PATH,
            '/usr/bin/chromium',
            '/usr/bin/chromium-browser',
            '/usr/bin/google-chrome',
            '/usr/bin/google-chrome-stable',
            '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
            '/Applications/Chromium.app/Contents/MacOS/Chromium',
            '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'
        ];

        const executablePath = candidatePaths.find((candidatePath) => {
            return !!candidatePath && fs.existsSync(candidatePath);
        });

        if (executablePath) {
            return { executablePath, isSparticuz: false };
        }

        return { executablePath: await chromium.executablePath(), isSparticuz: true };
    }

    private async sleep(ms: number): Promise<void> {
        await new Promise((resolve) => setTimeout(resolve, ms));
    }

    private async createLookerCapturePage(browser: any): Promise<any> {
        const page = await browser.newPage();
        const navigationTimeoutMs = this.blueAwardReportConfig.behavior.navigationTimeoutMs;
        page.setDefaultNavigationTimeout(navigationTimeoutMs);
        page.setDefaultTimeout(Math.max(navigationTimeoutMs, this.lookerCaptureReadyTimeoutMs));
        await page.setViewport({
            width: this.blueAwardReportConfig.viewport.width,
            height: this.blueAwardReportConfig.viewport.height,
            deviceScaleFactor: this.blueAwardReportConfig.viewport.deviceScaleFactor
        });
        await page.setExtraHTTPHeaders({
            'Accept-Language': 'en-US,en;q=0.9'
        });
        return page;
    }

    private isRetryableLookerCaptureError(error: any): boolean {
        const message = String(error?.message || error || '').toLowerCase();
        return (
            message.includes('navigation timeout') ||
            message.includes('detached frame') ||
            message.includes('frame was detached') ||
            message.includes('target closed') ||
            message.includes('execution context was destroyed') ||
            message.includes('navigating frame was detached') ||
            message.includes('net::err_socket_not_connected') ||
            message.includes('net::err_connection_reset') ||
            message.includes('net::err_connection_closed') ||
            message.includes('net::err_connection_timed_out') ||
            message.includes('net::err_timed_out') ||
            message.includes('net::err_network_changed') ||
            message.includes('net::err_internet_disconnected') ||
            message.includes('timed out after waiting')
        );
    }

    private isPuppeteerActionTimeout(error: any): boolean {
        return String(error?.message || error || '').toLowerCase().includes('timed out after waiting');
    }

    private async captureLookerPageAsPdf(page: any): Promise<Buffer> {
        const screenshot = await page.screenshot({
            type: 'png',
            fullPage: false,
            timeout: this.blueAwardReportConfig.behavior.actionTimeoutMs || 60000
        });
        const imageBytes = Buffer.from(screenshot);
        if (!imageBytes || imageBytes.length < 50000) {
            throw new Error(`Captured Looker Studio screenshot is smaller than expected: ${imageBytes?.length || 0} bytes`);
        }

        const pdf = await PDFDocument.create();
        const image = await pdf.embedPng(imageBytes);
        const imageWidth = image.width;
        const imageHeight = image.height;
        const leftTrimPx = Math.max(0, this.blueAwardReportConfig.trims.left);
        const topTrimPx = Math.max(0, this.blueAwardReportConfig.trims.top);
        const rightTrimPx = Math.max(0, this.blueAwardReportConfig.trims.right);
        const bottomTrimPx = Math.max(0, this.blueAwardReportConfig.trims.bottom);
        const croppedWidth = Math.max(1, imageWidth - leftTrimPx - rightTrimPx);
        const croppedHeight = Math.max(1, imageHeight - topTrimPx - bottomTrimPx);
        const pdfWidth = Math.min(croppedWidth, this.blueAwardReportConfig.pdfLimits.maxWidth);
        const pdfHeight = Math.min(croppedHeight, this.blueAwardReportConfig.pdfLimits.maxHeight);
        const pdfPage = pdf.addPage([pdfWidth, pdfHeight]);

        pdfPage.drawImage(image, {
            x: -leftTrimPx,
            y: -(imageHeight - croppedHeight - topTrimPx),
            width: imageWidth,
            height: imageHeight
        });

        return Buffer.from(await pdf.save());
    }

    private getLookerCaptureConcurrency(pageCount: number): number {
        const configured = Number(this.blueAwardReportConfig.behavior.captureConcurrency || 1);
        const safeConfigured = Number.isFinite(configured) ? Math.max(1, Math.floor(configured)) : 1;
        return Math.min(pageCount, safeConfigured);
    }

    private async waitForReportContent(page: any): Promise<boolean> {
        const behavior = this.blueAwardReportConfig.behavior;
        try {
            await page.waitForFunction((b: any) => {
                const body = document.body;
                if (!body) return false;
                const bodyText = (body.innerText || '').toLowerCase();
                if (bodyText.includes('captcha') || bodyText.includes('recaptcha')) return false;
                if (bodyText.includes('sign in') || bodyText.includes('log in')) return false;
                if (bodyText.includes('access denied') || bodyText.includes('request access')) return false;
                const visuals = document.querySelectorAll('canvas, svg, img');
                const reportIframe = Array.from(document.querySelectorAll('iframe')).find((frame) => {
                    const src = (frame.getAttribute('src') || '').toLowerCase();
                    const title = (frame.getAttribute('title') || '').toLowerCase();
                    if (src.includes('recaptcha') || title.includes('recaptcha')) return false;
                    const rect = frame.getBoundingClientRect();
                    return rect.width > b.minIframeWidth && rect.height > b.minIframeHeight;
                });
                const richText = bodyText.replace(/\s+/g, ' ').trim();
                return visuals.length >= b.minVisualCount && richText.length > b.minRichTextLength && !!reportIframe;
            }, { timeout: this.lookerCaptureReadyTimeoutMs }, behavior);
            return true;
        } catch {
            return false;
        }
    }

    private async detectAccessIssue(page: any): Promise<string | null> {
        return await page.evaluate(() => {
            const text = (document.body?.innerText || '').toLowerCase();
            if (text.includes('recaptcha') || text.includes('captcha')) return 'captcha_challenge';
            if (text.includes('sign in') || text.includes('log in')) return 'google_login_required';
            if (text.includes('request access') || text.includes('access denied')) return 'report_access_denied';
            return null;
        });
    }

    private async getRenderSummary(page: any): Promise<{
        title: string;
        bodyTextLength: number;
        canvasCount: number;
        svgCount: number;
        imgCount: number;
        iframeCount: number;
        largeVisualCount: number;
        largeIframeCount: number;
        scrollWidth: number;
        scrollHeight: number;
        hasBlueAwardText: boolean;
        hasNoDataReportText: boolean;
    }> {
        return await page.evaluate(() => {
            const bodyText = (document.body?.innerText || '').replace(/\s+/g, ' ').trim();
            const normalizedBodyText = bodyText.toLowerCase();
            const visuals = Array.from(document.querySelectorAll('canvas, svg, img'));
            const iframes = Array.from(document.querySelectorAll('iframe'));
            const largeVisualCount = visuals.filter((node) => {
                const rect = (node as Element).getBoundingClientRect();
                return rect.width >= 200 && rect.height >= 120;
            }).length;
            const largeIframeCount = iframes.filter((node) => {
                const rect = (node as Element).getBoundingClientRect();
                return rect.width >= 600 && rect.height >= 600;
            }).length;

            return {
                title: document.title || '',
                bodyTextLength: bodyText.length,
                canvasCount: document.querySelectorAll('canvas').length,
                svgCount: document.querySelectorAll('svg').length,
                imgCount: document.querySelectorAll('img').length,
                iframeCount: iframes.length,
                largeVisualCount,
                largeIframeCount,
                hasBlueAwardText: normalizedBodyText.includes('blue award'),
                hasNoDataReportText:
                    normalizedBodyText.includes('no data') &&
                    normalizedBodyText.includes('organisational carbon footprint report'),
                scrollWidth: Math.max(
                    document.documentElement?.scrollWidth || 0,
                    document.body?.scrollWidth || 0
                ),
                scrollHeight: Math.max(
                    document.documentElement?.scrollHeight || 0,
                    document.body?.scrollHeight || 0
                )
            };
        });
    }

    private async writeDebugScreenshot(page: any, submissionId: number, pageIndex: number, attempt: number): Promise<string> {
        const filePath = path.join(
            os.tmpdir(),
            `blue-award-${submissionId}-page-${pageIndex + 1}-attempt-${attempt}.png`
        );
        await page.screenshot({
            path: filePath,
            fullPage: true,
            timeout: this.blueAwardReportConfig.behavior.actionTimeoutMs || 60000
        });
        return filePath;
    }

    public buildLookerStudioPageUrlWithSubmissionId(pageUrl: string, submissionId: number, companyName?: string): string {
       // submissionId = 12659;
        let parsedUrl: URL;
        try {
            parsedUrl = new URL(pageUrl);
        } catch {
            throw new BadRequestException('Invalid page URL');
        }

        const allowedHosts = new Set(this.blueAwardReportConfig.behavior.lookerAllowedHosts);
        if (parsedUrl.protocol !== 'https:' || !allowedHosts.has(parsedUrl.hostname)) {
            throw new BadRequestException('Page URL must be a valid https Looker Studio URL');
        }

        const rawParams = parsedUrl.searchParams.get('params');
        let paramsObj: Record<string, any> = {};
        if (rawParams) {
            try {
                paramsObj = JSON.parse(rawParams);
            } catch {
                paramsObj = {};
            }
        }

        paramsObj[this.lookerStudioSubmissionUrlParamKey] = submissionId;
        paramsObj.p_submission_id = submissionId;
        paramsObj[this.blueAwardReportConfig.urlParams.submissionAliasKey] = submissionId;
        if (companyName && companyName.trim()) {
            paramsObj.df8 = `include%EE%80%800%EE%80%80IN%EE%80%80${encodeURIComponent(companyName.trim())}`;
        } else {
            paramsObj[this.blueAwardReportConfig.urlParams.dashboardFilterKey] =
                this.blueAwardReportConfig.urlParams.dashboardFilterTemplate.replace('{{submissionId}}', String(submissionId));
        }
        parsedUrl.searchParams.set('params', JSON.stringify(paramsObj));
        parsedUrl.searchParams.set(
            this.blueAwardReportConfig.urlParams.renderModeKey,
            this.blueAwardReportConfig.urlParams.renderModeValue
        );
        return parsedUrl.toString();
    }

    private async captureBlueAwardLookerPagePdf(
        browser: any,
        pageUrl: string,
        submissionId: number,
        reportCompanyName: string | undefined,
        pageIndex: number
    ): Promise<Buffer> {
        const urlWithParams = this.buildLookerStudioPageUrlWithSubmissionId(pageUrl, submissionId, reportCompanyName);
        let lastError: any;
        for (let attempt = 1; attempt <= this.blueAwardReportConfig.behavior.maxAttempts; attempt++) {
            let page: any;
            const attemptStartedAt = Date.now();
            try {
                console.log(`Blue Award capture loading submissionId=${submissionId}, page=${pageIndex + 1}, attempt=${attempt}`);
                page = await this.createLookerCapturePage(browser);
                await page.goto(urlWithParams, {
                    waitUntil: this.blueAwardReportConfig.render.gotoWaitUntil as any,
                    timeout: this.blueAwardReportConfig.behavior.navigationTimeoutMs
                });
                const accessIssue = await this.detectAccessIssue(page);
                if (accessIssue) {
                    throw new Error(`Access blocked: ${accessIssue}`);
                }
                await this.waitForReportContent(page);
                await page.evaluate(() => window.scrollTo(0, 0));
                await this.sleep(this.lookerPostLoadDelayMs);
                await page.emulateMediaType(this.blueAwardReportConfig.render.emulateMediaType as any);

                try {
                    const renderSummary = await this.getRenderSummary(page);
                    const renderedEnough =
                        renderSummary.largeIframeCount > 0 &&
                        (renderSummary.largeVisualCount > 0 || renderSummary.bodyTextLength >= this.blueAwardReportConfig.behavior.minRichTextLength);
                    const renderedNoDataReport =
                        renderSummary.bodyTextLength > 50 &&
                        renderSummary.bodyTextLength < this.blueAwardReportConfig.behavior.minRichTextLength &&
                        renderSummary.hasBlueAwardText &&
                        renderSummary.hasNoDataReportText;
                    if (!renderedEnough && !renderedNoDataReport) {
                        console.warn(
                            `Looker report readiness heuristics were not satisfied for submissionId=${submissionId}, page=${pageIndex + 1}, attempt=${attempt}; continuing with screenshot PDF capture.`,
                            {
                                url: urlWithParams,
                                renderSummary
                            }
                        );
                    }
                } catch (summaryError: any) {
                    console.warn(
                        `Could not inspect Looker report readiness for submissionId=${submissionId}, page=${pageIndex + 1}, attempt=${attempt}; continuing with screenshot PDF capture: ${summaryError?.message || summaryError}`
                    );
                }

                const rawPdf = await this.captureLookerPageAsPdf(page);
                if (!rawPdf || rawPdf.length < 50000) {
                    const screenshotPath = await this.writeDebugScreenshot(page, submissionId, pageIndex, attempt);
                    console.warn(
                        `Generated PDF is smaller than expected for submissionId=${submissionId}, page=${pageIndex + 1}, attempt=${attempt}; continuing because Looker rendered a capturable screenshot.`,
                        {
                            url: urlWithParams,
                            rawPdfLength: rawPdf?.length || 0,
                            screenshotPath
                        }
                    );
                }

                console.log(`Blue Award capture completed submissionId=${submissionId}, page=${pageIndex + 1}, attempt=${attempt}, durationMs=${Date.now() - attemptStartedAt}`);
                return Buffer.from(rawPdf);
            } catch (error: any) {
                lastError = error;
                const retryable = this.isRetryableLookerCaptureError(error);
                if (retryable && !this.isPuppeteerActionTimeout(error) && page && !page.isClosed()) {
                    try {
                        await this.sleep(1000);
                        const fallbackPdf = await this.captureLookerPageAsPdf(page);
                        console.warn(
                            `Captured Looker Studio screenshot PDF after retryable error for submissionId=${submissionId}, page=${pageIndex + 1}, attempt=${attempt}, durationMs=${Date.now() - attemptStartedAt}: ${error?.message || error}`
                        );
                        return fallbackPdf;
                    } catch (fallbackError: any) {
                        lastError = fallbackError;
                    }
                }
                if (attempt === this.blueAwardReportConfig.behavior.maxAttempts) {
                    throw lastError || error;
                }
                if (!retryable) {
                    throw error;
                }
                console.warn(
                    `Retrying Looker Studio capture for submissionId=${submissionId}, page=${pageIndex + 1}, attempt=${attempt} after retryable error: ${error?.message || error}`
                );
                await this.sleep(this.blueAwardReportConfig.behavior.retryDelayMs);
            } finally {
                if (page) {
                    await page.close().catch(() => undefined);
                }
            }
        }
        throw lastError;
    }

    public async downloadMergedBlueAwardLookerStudioPdf(submissionId: number, pageUrls?: string[], companyName?: string): Promise<Buffer> {
        if (!Number.isInteger(submissionId) || submissionId <= 0) {
            throw new BadRequestException('submissionId must be a positive integer');
        }

        const pages = (pageUrls && pageUrls.length > 0) ? pageUrls : this.defaultBlueAwardPageUrls;
        const reportCompanyName = String(companyName || '').trim() || await this.resolveBlueAwardCompanyName(submissionId);
        let browser: any;
        const reportStartedAt = Date.now();
        try {
            // Runtime-load puppeteer so deploys fail at request time with a clear message if the browser is missing.
            // eslint-disable-next-line @typescript-eslint/no-var-requires
            const puppeteer = require('puppeteer-core');
            // eslint-disable-next-line @typescript-eslint/no-var-requires
            const chromium = require('@sparticuz/chromium');
            const { executablePath, isSparticuz } = await this.resolvePuppeteerExecutablePath(chromium);
            const browserArgs = Array.from(new Set([
                ...(isSparticuz ? chromium.args : []),
                ...this.blueAwardReportConfig.behavior.browserArgs
            ]));
            const launchTimeoutMs = Number(process.env.LOOKER_PUPPETEER_LAUNCH_TIMEOUT_MS || 180000);
            browser = await puppeteer.launch({
                headless: this.blueAwardReportConfig.behavior.browserHeadless ?? chromium.headless,
                timeout: launchTimeoutMs,
                protocolTimeout: launchTimeoutMs,
                ...(executablePath ? { executablePath } : {}),
                args: browserArgs
            });
        } catch (error) {
            console.error('Failed to launch Puppeteer for Blue Award report generation.', error);
            const errorMessage = error instanceof Error ? error.message : String(error);
            throw new BadGatewayException(`Puppeteer browser is unavailable: ${errorMessage}`);
        }

        try {
            const pagePdfBuffers = new Array<Buffer>(pages.length);
            const concurrency = this.getLookerCaptureConcurrency(pages.length);
            console.log(`Blue Award capture started submissionId=${submissionId}, pages=${pages.length}, concurrency=${concurrency}`);
            let nextPageIndex = 0;
            const workers = Array.from({ length: concurrency }, async () => {
                while (nextPageIndex < pages.length) {
                    const pageIndex = nextPageIndex++;
                    pagePdfBuffers[pageIndex] = await this.captureBlueAwardLookerPagePdf(
                        browser,
                        pages[pageIndex],
                        submissionId,
                        reportCompanyName,
                        pageIndex
                    );
                }
            });
            await Promise.all(workers);

            const mergedPdf = await PDFDocument.create();
            for (const pagePdfBuffer of pagePdfBuffers) {
                const srcPdf = await PDFDocument.load(pagePdfBuffer);
                const copiedPages = await mergedPdf.copyPages(srcPdf, srcPdf.getPageIndices());
                for (const copiedPage of copiedPages) {
                    mergedPdf.addPage(copiedPage);
                }
            }
            const mergedBuffer = Buffer.from(await mergedPdf.save());
            console.log(`Blue Award capture merged submissionId=${submissionId}, pages=${pages.length}, durationMs=${Date.now() - reportStartedAt}, bytes=${mergedBuffer.length}`);
            return mergedBuffer;
        } catch (error: any) {
            throw new BadGatewayException(`Failed to generate merged Looker Studio PDF: ${error?.message || 'unknown error'}`);
        } finally {
            if (browser) {
                await browser.close();
            }
        }
    }

    private async resolveBlueAwardCompanyName(submissionId: number): Promise<string | undefined> {
        try {
            const query = await this.databaseService.execute('portal.spCertificationBlueAward_Get', []);
            const record = (query?.results || []).find((item: any) => Number(item?.submissionId) === submissionId);
            const companyName = String(record?.companyName || '').trim();
            return companyName || undefined;
        } catch {
            return undefined;
        }
    }

    public async getCertificationWeekStatusReport(companyId?: number): Promise<any> {

        const params = companyId && companyId > 0
            ? [{ name: 'companyId', type: mssql.TYPES.Int, value: companyId }]
            : [];

        const query = await this.databaseService.execute(
            '[portal].[spCertificationWeekStatusReport]',
            params
        );

        return query.results;
    }

    public async getCertificationAllStatusReport(companyId?: number): Promise<any> {

        const params = companyId && companyId > 0
            ? [{ name: 'companyId', type: mssql.TYPES.Int, value: companyId }]
            : [];

        const query = await this.databaseService.execute(
            '[portal].[spCertificationAllStatusReport]',
            params
        );

        return query.results;
    }

    public async getSupplierWeekStatusReport(companyId?: number): Promise<any> {

        const params = companyId && companyId > 0
            ? [{ name: 'companyId', type: mssql.TYPES.Int, value: companyId }]
            : [];

        const query = await this.databaseService.execute(
            '[portal].[spSupplierWeekStatusReport]',
            params
        );

        return query.results;
    }

    public async getReportIssuedWeekStatusReport(companyId?: number): Promise<any> {

        const params = companyId && companyId > 0
            ? [{ name: 'companyId', type: mssql.TYPES.Int, value: companyId }]
            : [];

        const query = await this.databaseService.execute(
            '[portal].[spReportIssuedWeekStatusReport]',
            params
        );

        return query.results;
    }

    public async getCertificationReportData(companyId?: number): Promise<any> {

        const query = await this.databaseService.execute(
            '[portal].[spCertificationReportDetail]'
        );

        return query.results;
    }

    public async getReportIssuedData(): Promise<any> {

        const query = await this.databaseService.execute(
            '[portal].[spReportIssuedDetail]'
        );

        return query.results;
    }

    public async getSupplierReportData(): Promise<any> {

        const query = await this.databaseService.execute(
            '[portal].[spSupplierReportDetail]'
        );

        return query.results;
    }

    private async createTokenForCertSubmission(certSubmissionId: number): Promise<any> {
        const properties = JSON.stringify({ certSubmissionId });
        const params = [
            { name: 'tokenId', type: mssql.TYPES.Int, value: null },
            { name: 'certId', type: mssql.TYPES.Int, value: null },
            { name: 'locationId', type: mssql.TYPES.Int, value: null },
            { name: 'dimFormId', type: mssql.TYPES.Int, value: null },
            { name: 'activeTo', type: mssql.TYPES.DateTime2, value: null },
            { name: 'isActive', type: mssql.TYPES.Bit, value: 1 },
            { name: 'tokenType', type: mssql.TYPES.NVarChar, value: 'blueaward' },
            { name: 'properties', type: mssql.TYPES.NVarChar, value: properties }
        ];
        const res = await this.databaseService.execute('[portal].[spToken_Save]', params);
        return res?.results?.[0] || null;
    }

    private async queueBlueAwardDownloadEmail(
        recipient: string,
        tokenKey: string,
        templateData: Record<string, any>,
        currentUser?: { uid?: string; email?: string },
    ): Promise<void> {
        const base = process.env.FRONTEND_URL || 'http://localhost:4200';
        const link = `${base.replace(/\/$/, '')}/certification/blue-award?token=${encodeURIComponent(tokenKey)}`;
        const data = Object.assign({}, templateData || {}, {
            downloadLink: link
        });
        const fromEmail = await this.resolveCurrentUserFromEmail(currentUser);

        await this.emailService.queueEmail(
            recipient,
            EmailTemplates.BLUE_AWARD_REPORT_DOWNLOAD_EMAIL,
            data,
            fromEmail,
        );
    }

    private async resolveCurrentUserFromEmail(currentUser?: { uid?: string; email?: string }): Promise<string | undefined> {
        const email = String(currentUser?.email ?? '').trim();
        const uid = String(currentUser?.uid ?? '').trim();

        if (!uid) {
            return email || undefined;
        }
       
        const query = await this.databaseService.execute('[portal].[spUser_GetbyUId]', [
            { name: 'uId', type: mssql.TYPES.NVarChar, value: uid },
        ]);
        const profile = query?.results?.[0] ?? query?.recordsets?.[0]?.[0] ?? null;
        const fullName = String(profile?.displayName ?? '').trim();

        if (fullName && email) {
            return `${fullName} <${email}>`;
        }

        return email || undefined;
    }
}

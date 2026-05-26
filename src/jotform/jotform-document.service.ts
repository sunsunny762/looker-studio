import { Injectable, Logger } from '@nestjs/common';
import fetch from 'node-fetch';
import * as mimeTypes from 'mime-types';
import { DocumentsService } from '../documents/documents.service';
import { DatabaseService } from '../database';

const CONTAINER = 'jotform-submission-docs';

@Injectable()
export class JotformDocumentService {
    private readonly logger = new Logger(JotformDocumentService.name);

    constructor(
        private readonly databaseService: DatabaseService,
        private readonly documentsService: DocumentsService,
    ) {}

    public async getFile(submissionId: string, fileName: string): Promise<Buffer> {
        const blobName = `${submissionId}/${fileName}`;
        return this.documentsService.downloadFile(blobName, CONTAINER);
    }

    public async ingestDocuments(
        certsubmissionId: string,
    ): Promise<{ submissionId: string; fileName: string; success: boolean; error?: string }[]> {
        const jotformSubmissionId = await this.resolveJotformSubmissionId(certsubmissionId);
        if (!jotformSubmissionId) {
            throw new Error(`No jotform submission found for certsubmissionId ${certsubmissionId}`);
        }

        const fileUrls = await this.fetchJotformFileUrls(jotformSubmissionId);
        if (!fileUrls.length) {
            this.logger.log(`No file uploads found for jotform submission ${jotformSubmissionId}`);
            return [];
        }

        const results: { submissionId: string; fileName: string; success: boolean; error?: string }[] = [];

        for (const fileUrl of fileUrls) {
            const { submissionId, fileName } = this.extractBlobPath(fileUrl);
            try {
                const buffer = await this.fetchRemoteFile(fileUrl);
                const mimeType = mimeTypes.lookup(fileName) || 'application/octet-stream';
                await this.documentsService.uploadBufferAtPath(buffer, `${submissionId}/${fileName}`, CONTAINER, mimeType);
                results.push({ submissionId, fileName, success: true });
            } catch (err: any) {
                this.logger.error(`Failed to ingest ${fileUrl}: ${err?.message}`);
                results.push({ submissionId, fileName, success: false, error: err?.message });
            }
        }

        return results;
    }

    private async resolveJotformSubmissionId(certsubmissionId: string): Promise<string | null> {
        const query = await this.databaseService.execute('[portal].[spSubmission_GetDetails]', [
            { name: 'certsubmissionId', type: require('mssql').TYPES.Int, value: parseInt(certsubmissionId, 10) },
            { name: 'uCompanyId', type: require('mssql').TYPES.Int, value: null },
        ]);
        const row = query.results?.[0];
        return row?.submissionId ? String(row.submissionId) : null;
    }

    private async fetchJotformFileUrls(jotformSubmissionId: string): Promise<string[]> {
        const apiUrl = process.env.JOTFORM_API_URL;
        const apiKey = process.env.JOTFORM_APIKEY;
        const res = await fetch(`${apiUrl}/submission/${jotformSubmissionId}?apiKey=${apiKey}`);
        if (!res.ok) {
            throw new Error(`JotForm API error: ${res.status} ${res.statusText}`);
        }

        const json: any = await res.json();
        const answers: Record<string, any> = json?.content?.answers ?? {};
        const fileUrls: string[] = [];

        for (const answer of Object.values(answers)) {
            const type: string = String(answer?.type ?? '');
            if (!type.includes('fileupload') && !type.includes('control_fileupload')) {
                continue;
            }
            const answerValue = answer?.answer;
            if (!answerValue) continue;

            const values: string[] = Array.isArray(answerValue)
                ? answerValue
                : typeof answerValue === 'string'
                ? [answerValue]
                : [];

            for (const v of values) {
                const urlStr = String(v ?? '').trim();
                if (urlStr.startsWith('http')) {
                    fileUrls.push(urlStr);
                }
            }
        }

        return fileUrls;
    }

    private extractBlobPath(fileUrl: string): { submissionId: string; fileName: string } {
        const segments = fileUrl.split('/').filter((s) => s.length > 0);
        const fileName = segments[segments.length - 1];
        const submissionId = segments[segments.length - 2];
        return { submissionId, fileName };
    }

    private async fetchRemoteFile(url: string): Promise<Buffer> {
        const res = await fetch(url);
        if (!res.ok) {
            throw new Error(`Failed to fetch file from ${url}: ${res.status} ${res.statusText}`);
        }
        const arrayBuffer = await res.arrayBuffer();
        return Buffer.from(arrayBuffer);
    }
}

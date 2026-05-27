import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { DocumentsService } from '../../documents/documents.service';

export interface PublicFormSubmissionDocumentDownloadItem {
    documentKey: string;
    psubmissionId: number;
    dimFormId: number;
    submissionId: number;
    formName: string;
    question: string;
    documentName: string;
    documentId: number;
    container: string;
    blobName: string;
}

@Injectable()
export class PublicFormsService {
    constructor(
        private readonly databaseService: DatabaseService,
        private readonly errorLoggerService: ErrorLoggerService,
        private readonly documentsService: DocumentsService,
    ) {}

    // ── Forms ────────────────────────────────────────────────────────────────

    async getForms(): Promise<any[]> {
        const query = await this.databaseService.execute('[portal].[spPublicForm_Get]', [
            { name: 'pformId',    type: mssql.TYPES.Int, value: null }
        ]);
        return query.results ?? [];
    }

    async getFormById(pformId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spPublicForm_Get]', [
            { name: 'pformId',    type: mssql.TYPES.Int, value: pformId }
        ]);
        return query.results?.[0] ?? null;
    }

    async saveForm(
        pformId: number,
        dimFormId: number | null,
        displayName: string | null,
        displayOrder: number,
        isActive: boolean,
    ): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spPublicForm_Save]', [
            { name: 'pformId',      type: mssql.TYPES.Int,      value: pformId },
            { name: 'dimFormId',    type: mssql.TYPES.Int,      value: dimFormId },
            { name: 'displayName',  type: mssql.TYPES.NVarChar, value: displayName },
            { name: 'displayOrder', type: mssql.TYPES.SmallInt, value: displayOrder },
            { name: 'isActive',     type: mssql.TYPES.Bit,      value: isActive ? 1 : 0 },
        ]);
        return query.results?.[0] ?? null;
    }

    async deleteForm(pformId: number): Promise<void> {
        await this.databaseService.execute('[portal].[spPublicForm_Delete]', [
            { name: 'pformId', type: mssql.TYPES.Int, value: pformId },
        ]);
    }

    // ── Submissions ──────────────────────────────────────────────────────────

    async getSubmissions(
        dimFormId: number,
        psubmissionId: number | null = null,
        dateFrom: Date | null = null,
        dateTo: Date | null = null,
    ): Promise<any[]> {
        const query = await this.databaseService.execute('[portal].[spPublicFormSubmission_Get]', [
            { name: 'dimFormId',      type: mssql.TYPES.Int,       value: dimFormId },
            { name: 'psubmissionId',  type: mssql.TYPES.Int,       value: psubmissionId },
            { name: 'dateFrom',       type: mssql.TYPES.DateTime2, value: dateFrom },
            { name: 'dateTo',         type: mssql.TYPES.DateTime2, value: dateTo },
        ]);
        return query.results ?? [];
    }

    async saveSubmission(
        dimFormId: number,
        submissionId: number | null,
        certId: number | null,
        notes: string | null,
        properties: string | null,
    ): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spPublicFormSubmission_Save]', [
            { name: 'dimFormId',    type: mssql.TYPES.Int,      value: dimFormId },
            { name: 'submissionId', type: mssql.TYPES.BigInt,   value: submissionId },
            { name: 'certId',       type: mssql.TYPES.Int,      value: certId },
            { name: 'notes',        type: mssql.TYPES.NVarChar, value: notes },
            { name: 'properties',   type: mssql.TYPES.NVarChar, value: properties },
        ]);
        return query.results?.[0] ?? null;
    }

    async deleteSubmission(psubmissionId: number, deleteNotes: string | null = null): Promise<void> {
        await this.databaseService.execute('[portal].[spPublicFormSubmission_Delete]', [
            { name: 'psubmissionId', type: mssql.TYPES.Int,      value: psubmissionId },
            { name: 'deleteNotes',   type: mssql.TYPES.NVarChar, value: deleteNotes },
        ]);
    }

    async getSubmissionDocuments(dimFormId: number, psubmissionId: number): Promise<PublicFormSubmissionDocumentDownloadItem[]> {
        const query = await this.databaseService.execute('[portal].[spPublicFormSubmissionDocuments_Get]', [
            { name: 'dimFormId', type: mssql.TYPES.Int, value: dimFormId },
            { name: 'psubmissionId', type: mssql.TYPES.Int, value: psubmissionId },
        ]);

        return (query.results || []).map((item: any) => {
            const normalizedDimFormId = Number(item.dimFormId);
            const normalizedSubmissionId = Number(item.psubmissionId);
            const normalizedDocumentId = Number(item.documentId);
            return {
                documentKey: `PUBLIC:${normalizedDimFormId}:${normalizedSubmissionId}:${normalizedDocumentId}`,
                psubmissionId: normalizedSubmissionId,
                dimFormId: normalizedDimFormId,
                submissionId: Number(item.submissionId),
                formName: String(item.formName ?? ''),
                question: String(item.question ?? ''),
                documentName: String(item.documentName ?? ''),
                documentId: normalizedDocumentId,
                container: String(item.container ?? ''),
                blobName: String(item.blobName ?? ''),
            } as PublicFormSubmissionDocumentDownloadItem;
        }).filter((item) => Boolean(item.documentId && item.container && item.blobName));
    }

    async getSubmissionDocumentsForZip(dimFormId: number, psubmissionIds: number[]): Promise<PublicFormSubmissionDocumentDownloadItem[]> {
        const uniqueSubmissionIds = Array.from(
            new Set(
                (psubmissionIds || [])
                    .map((value) => Number(value))
                    .filter((value) => Number.isInteger(value) && value > 0),
            ),
        );

        const documents: PublicFormSubmissionDocumentDownloadItem[] = [];
        for (const psubmissionId of uniqueSubmissionIds) {
            const submissionDocuments = await this.getSubmissionDocuments(dimFormId, psubmissionId);
            documents.push(...submissionDocuments);
        }

        return documents;
    }

    async downloadSubmissionDocument(document: PublicFormSubmissionDocumentDownloadItem): Promise<Buffer> {
        return this.documentsService.downloadFile(document.blobName, document.container);
    }

    getZipEntryName(document: PublicFormSubmissionDocumentDownloadItem, usedNames: Set<string>): string {
        const parts = [
            document.formName,
            `submission-${document.psubmissionId}`,
            document.question,
            this.getDownloadFileName(document),
        ]
            .map((part) => this.sanitizeZipPathSegment(part))
            .filter((part) => Boolean(part));

        const fallbackName = this.sanitizeZipPathSegment(this.getDownloadFileName(document)) || 'document';
        const baseName = parts.length ? parts.join('/') : fallbackName;
        let candidate = baseName;
        let index = 2;

        while (usedNames.has(candidate)) {
            candidate = `${baseName}-${index}`;
            index += 1;
        }

        usedNames.add(candidate);
        return candidate;
    }

    private getDownloadFileName(document: PublicFormSubmissionDocumentDownloadItem): string {
        const documentName = String(document?.documentName ?? '').trim();
        return documentName || `document-${document.documentId}`;
    }

    private sanitizeZipPathSegment(value: string): string {
        return String(value ?? '')
            .replace(/[<>:"/\\|?*\x00-\x1F]/g, '_')
            .replace(/\s+/g, ' ')
            .trim();
    }
}


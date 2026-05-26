import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { get } from 'http';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { DocumentsService } from '../../documents/documents.service';
import { promises as fs } from 'fs';
import * as path from 'path';

export interface SubmissionDocumentDownloadItem {
    documentKey: string;
    certsubmissionId: number;
    locationName: string;
    formName: string;
    question: string;
    documentName: string;
    sourceType: string;
    container: string;
    blobName: string;
}

@Injectable()
export class SubmissionService {

    constructor(private readonly databaseService: DatabaseService, 
        private readonly errorLoggerService: ErrorLoggerService,
        private readonly documentsService?: DocumentsService
    ) { }

    public async getSubmissions(certId: number | null, listCHW: number=0): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spSubmission_Get]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "listCHW", type: mssql.TYPES.Bit, value: listCHW },
        ]);
        const results = query.results;
        return results;
    }

    public async getSubmissionTiles(certId: number, locId: number, uCompanyId: number | null = null): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spSubmission_GetTiles]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "locationId", type: mssql.TYPES.Int, value: locId },
            { name: "uCompanyId", type: mssql.TYPES.Int, value: uCompanyId }
        ]);
        const results = query.results;
        return results;
    }

    public async getAllForms(certId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCertification_GetSubmissions]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
        ]);
        const results = query.results;
        return results;
    }

    public async getCertificationSubmissionDocuments(certId: number): Promise<SubmissionDocumentDownloadItem[]> {
        const query = await this.databaseService.execute('[portal].[spCertificationSubmissionDocuments_Get]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
        ]);

        return (query.results || []).map((item: any) => ({
            documentKey: String(item.documentKey ?? ''),
            certsubmissionId: Number(item.certsubmissionId),
            locationName: String(item.locationName ?? ''),
            formName: String(item.formName ?? ''),
            question: String(item.question ?? ''),
            documentName: String(item.documentName ?? ''),
            sourceType: String(item.sourceType ?? ''),
            container: String(item.container ?? ''),
            blobName: String(item.blobName ?? ''),
        })).filter((item) => Boolean(item.documentKey && item.container && item.blobName));
    }

    private getCertIdFromDocumentKey(documentKey: string): number | null {
        const parts = String(documentKey ?? '').split(':');
        const certId = Number(parts[1]);
        return Number.isInteger(certId) && certId > 0 ? certId : null;
    }

    public async getSubmissionDocumentByKey(documentKey: string): Promise<SubmissionDocumentDownloadItem | null> {
        const certId = this.getCertIdFromDocumentKey(documentKey);
        if (!certId) {
            return null;
        }

        const documents = await this.getCertificationSubmissionDocuments(certId);
        return documents.find((document) => document.documentKey === documentKey) ?? null;
    }

    public async getSubmissionDocumentDownload(documentKey: string): Promise<{ document: SubmissionDocumentDownloadItem; buffer: Buffer } | null> {
        const document = await this.getSubmissionDocumentByKey(documentKey);
        if (!document) {
            return null;
        }

        if (!this.documentsService) {
            throw new Error('Documents service is not available');
        }

        try {
            const buffer = await this.documentsService.downloadFile(document.blobName, document.container);
            return { document, buffer };
        } catch (error) {
            const statusCode = (error as any)?.statusCode ?? (error as any)?.status;
            const errorCode = (error as any)?.details?.errorCode ?? (error as any)?.code;
            const message = error instanceof Error ? error.message : String(error);
            const isNotFound =
                statusCode === 404 ||
                errorCode === 'BlobNotFound' ||
                /blob does not exist/i.test(message);

            if (isNotFound) {
                const container = String(document.container ?? '').trim();
                const sourceType = String(document.sourceType ?? '').trim().toLowerCase();
                const isJotformContainer = container.toLowerCase() === 'jotform-submission-docs';
                const isJotformSource = sourceType.includes('jotform');
                const downloadName = this.getDownloadFileName(document);

                // Fallback: Jotform blobs are stored as: jotform-submission-docs/<submissionId>/<fileName>
                if ((isJotformContainer || isJotformSource) && container && downloadName) {
                    const submissionId = await this.getSubmissionIdForCertSubmission(document.certsubmissionId);
                    if (submissionId) {
                        const fallbackBlobName = `${submissionId}/${downloadName}`;
                        if (fallbackBlobName !== document.blobName) {
                            try {
                                const buffer = await this.documentsService.downloadFile(fallbackBlobName, container);
                                return {
                                    document: { ...document, blobName: fallbackBlobName },
                                    buffer,
                                };
                            } catch (fallbackError) {
                                const fallbackMessage =
                                    fallbackError instanceof Error ? fallbackError.message : String(fallbackError);
                                const fallbackStatusCode =
                                    (fallbackError as any)?.statusCode ?? (fallbackError as any)?.status;
                                const fallbackErrorCode =
                                    (fallbackError as any)?.details?.errorCode ?? (fallbackError as any)?.code;
                                const fallbackIsNotFound =
                                    fallbackStatusCode === 404 ||
                                    fallbackErrorCode === 'BlobNotFound' ||
                                    /blob does not exist/i.test(fallbackMessage);

                                if (fallbackIsNotFound) {
                                    return null;
                                }

                                throw fallbackError;
                            }
                        }
                    }
                }

                return null;
            }

            throw error;
        }
    }

    private async getSubmissionIdForCertSubmission(certsubmissionId: number): Promise<string | null> {
        if (!Number.isFinite(certsubmissionId) || certsubmissionId <= 0) {
            return null;
        }

        const query = await this.databaseService.execute('[portal].[spSubmission_GetDetails]', [
            { name: "certsubmissionId", type: mssql.TYPES.Int, value: certsubmissionId },
            { name: "uCompanyId", type: mssql.TYPES.Int, value: null }
        ]);

        const submissionId = query?.results?.[0]?.submissionId;
        if (submissionId == null) {
            return null;
        }

        const normalized = String(submissionId).trim();
        return normalized ? normalized : null;
    }

    public getDownloadFileName(document: SubmissionDocumentDownloadItem): string {
        const documentName = String(document?.documentName ?? '').trim();
        return documentName || 'submission-document';
    }

    public getZipEntryName(document: SubmissionDocumentDownloadItem, usedNames: Set<string>): string {
        const parts = [
            document.locationName,
            document.formName,
            String(document.certsubmissionId ?? ''),
            this.getDownloadFileName(document),
        ]
            .map((part) => this.sanitizeZipPathSegment(part))
            .filter((part) => Boolean(part));

        const fallbackName = this.sanitizeZipPathSegment(this.getDownloadFileName(document)) || 'submission-document';
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

    private sanitizeZipPathSegment(value: string): string {
        return String(value ?? '')
            .replace(/[<>:"/\\|?*\x00-\x1F]/g, '_')
            .replace(/\s+/g, ' ')
            .trim();
    }

    public async getOtherSubmissionTiles(certId: number, uCompanyId: number | null = null): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spOtherSubmission_GetTiles]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "uCompanyId", type: mssql.TYPES.Int, value: uCompanyId }
        ]);
        const results = query.results;
        return results;
    }

    public async getSubmissionByProgForm(certId: number, progFormId: number, locId: number): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spSubmission_GetByProgFormId]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "progformId", type: mssql.TYPES.Int, value: progFormId },
            { name: "locationId", type: mssql.TYPES.Int, value: locId },
        ]);
        const results = query.results;
        return results;
    }

    public async getOtherSubmissionByProgForm(certId: number, progFormId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spOtherSubmission_GetByProgFormId]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "progformId", type: mssql.TYPES.Int, value: progFormId },
        ]);
        const results = query.results;
        return results;
    }

    public async getSubmissionsByCompany(companyId: number): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spSubmission_GetbyCompany]', [
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
        ]);
        const results = query.results;
        return results;
    }
    public async getCertSubmissions(certId: number): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spSubmission_GetSubmissions]', [
            { name: "certId", type:mssql.TYPES.Int, value: certId}
        ]);
        const results = query.results;
        return results;
    }

    public async addSubmission(certId: number, locationId: number, dimFormId: number, notes: string, userId: number,
                    parentCertsubmissionId: number = null): Promise<any> { // Add Cert Submission Before Form Load

        const query = await this.databaseService.execute('[portal].[spSubmission_Save]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "locationId", type: mssql.TYPES.Int, value: locationId },
            { name: "dimFormId", type: mssql.TYPES.Int, value: dimFormId },
            { name: "notes", type: mssql.TYPES.NVarChar, value: notes },
            { name: "userId", type: mssql.TYPES.Int, value: userId },
            { name: "parentCertsubmissionId", type: mssql.TYPES.Int, value: parentCertsubmissionId },
        ]);
        
        const results = query.results;
        return results;
    }

    public async addBlueAwardCertification(dimFormId: number, submissionId: number): Promise<any> { 

        const query = await this.databaseService.execute('[portal].[spCertificationBlueAward_Save]', [
            { name: "submissionId", type: mssql.TYPES.Int, value: submissionId },
            { name: "dimFormId", type: mssql.TYPES.Int, value: dimFormId },
        ]);
        
        const results = query.results;
        if (!results || results.length === 0) {
            return null;
        }
        
        // For Blue Award (dimFormId = 29), retrieve the certSubmissionId that was created
        const certSubmissionId = results[0].certSubmissionId;
        return certSubmissionId;
    }
    // public async addPublicFormSubmission(dimFormId: number, submissionId: number): Promise<any> { // Add Cert Submission After Form Submitted

    //     const query = await this.databaseService.execute('[portal].[spSubmissionPublicForm_Save]', [
    //         { name: "submissionId", type: mssql.TYPES.Int, value: submissionId },
    //         { name: "dimFormId", type: mssql.TYPES.Int, value: dimFormId },
    //     ]);
        
    //     const results = query.results;
    //     return results;
    // }

    public async checkCHWFormSubmission(certId: number, locationId: number, dimFormId: number, email: string): Promise<any> { // Add Cert Submission Before Form Load

        const query = await this.databaseService.execute('[portal].[spSubmissionCHWForm_Get]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "locationId", type: mssql.TYPES.Int, value: locationId },
            { name: "dimFormId", type: mssql.TYPES.Int, value: dimFormId },
            //{ name: "name", type: mssql.TYPES.NVarChar, value: name },
            { name: "email", type: mssql.TYPES.NVarChar, value: email },
        ]);
        
        const results = query.results;
        return results;
    }
    
    // public async updateSubmission(certId: number, companyId: number, progId: number, startDate: string, refNumber: string, status: number,
    //     description: string, clickupTaskId: string): Promise<any> {

    //     const query = await this.databaseService.execute('[portal].[spSubmission_Save]', [
    //         { name: "certId", type: mssql.TYPES.Int, value: certId },
    //         { name: "companyId", type: mssql.TYPES.Int, value: companyId },
    //         { name: "progId", type: mssql.TYPES.Int, value: progId },
    //         { name: "startDate", type: mssql.TYPES.NVarChar, value: startDate },
    //         { name: "refNumber", type: mssql.TYPES.NVarChar, value: refNumber },
    //         { name: "status", type: mssql.TYPES.Int, value: status },
    //         { name: "description", type: mssql.TYPES.NVarChar, value: description },
    //         { name: "clickupTaskId", type: mssql.TYPES.NVarChar, value: clickupTaskId },
    //     ]);
        
    //     const results = query.results;
    //     return results;
    // }

    public async deleteSubmission(certsubmissionId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spSubmission_Delete]', [
            { name: "certsubmissionId", type: mssql.TYPES.Int, value: certsubmissionId },
        ]);
        
        const results = query.results;
        return results;
    }

    public async getJotformSubmission(certsubmissionId: number): Promise<any> {
        const submissionData = await this.getSubmissionDetails(certsubmissionId);
        if (submissionData.length == 0) return null;

        const submissionId = submissionData[0].submissionId;
        if (String(process.env.JOTFORM_SUBMISSION_API_ACTIVE).toLowerCase() === 'true') {
            const res = await fetch(`${process.env.JOTFORM_API_URL}/submission/${submissionId}?apiKey=${process.env.JOTFORM_APIKEY}`);
            if (!res.ok) {
                throw new Error(`Failed to fetch the submission. Status: ${res.status} ${res.statusText}`);
            }

            return await res.json();
        }

        const jotformViewDetail = await this.getJotformViewDetail(submissionId);

        if (!jotformViewDetail?.jotformViewResponse) {
            return null;
        }

        if (typeof jotformViewDetail.jotformViewResponse !== 'string') {
            return jotformViewDetail.jotformViewResponse;
        }

        try {
            return JSON.parse(jotformViewDetail.jotformViewResponse);
        } catch (error) {
            throw new Error(`Failed to parse stored Jotform view response for submissionId ${submissionId}`);
        }
    }

    public async getJotformViewDetail(submissionId: string | number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spJotformViewDetails_Get]', [
            { name: "submissionId", type: mssql.TYPES.BigInt, value: submissionId },
        ]);

        return query.results?.[0] ?? null;
    }

    public async getSubmissionDetails(certsubmissionId: number, uCompanyId: number | null = null): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spSubmission_GetDetails]', [
            { name: "certsubmissionId", type: mssql.TYPES.Int, value: certsubmissionId },
            { name: "uCompanyId", type: mssql.TYPES.Int, value: uCompanyId }
        ]);
        
        const results = query.results;
        return results;
    }

   public async getSubmissionEmissionDetails(certsubmissionId: number, emissionProfileId: number): Promise<any> {
        const query = await this.databaseService.execute(
            '[portal].[spSubmission_GetEmissions]',
            [
                { name: "certsubmissionId", type: mssql.TYPES.Int, value: certsubmissionId },
                { name: "emissionProfileId", type: mssql.TYPES.Int, value: emissionProfileId},
            ]
        );
        return query.results;
    }

    public async getDimFormDetails(dimFormId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spForm_GetByDimFormId]', [
            { name: "dimFormId", type: mssql.TYPES.Int, value: dimFormId }
        ]);
        
        const results = query.results;
        return results[0];
    }
}

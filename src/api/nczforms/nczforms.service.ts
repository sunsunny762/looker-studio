import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { DocumentsService } from '../../documents/documents.service';
import { FileUploadRequest } from '../../documents/model';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';

@Injectable()
export class NczformsService {

    constructor(
        private readonly databaseService: DatabaseService, 
        private readonly errorLoggerService: ErrorLoggerService,
        private readonly documentsService: DocumentsService
    ) { }

    public async saveFormSubmission(formId: number, submissionId: number, userId: number, responses: any, submissionData: any, isDraft: boolean = false): Promise<any> {
        try {
            const submissionJson = JSON.stringify(submissionData);
            const responsesJson = JSON.stringify(responses);
            const status = isDraft ? 0 : 1;
            
            const query = await this.databaseService.execute('[portal].[spFormSubmission_Save]', [
                { name: "formId", type: mssql.TYPES.Int, value: formId ?? null },
                { name: "submissionId", type: mssql.TYPES.Int, value: submissionId ?? null },
                { name: "userId", type: mssql.TYPES.Int, value: userId },
                { name: "responses", type: mssql.TYPES.NVarChar, value: responsesJson },
                { name: "submissionData", type: mssql.TYPES.NVarChar, value: submissionJson },
                { name: "status", type: mssql.TYPES.Int, value: status },
            ]);
            
            const results = query.singleResult;
            return results;
        } catch (error) {
            console.error('saveFormSubmission', error);
            throw error;
        }
    }

    // public async updateFormSubmission(submissionId: number, submissionData: any, isDraft: boolean = false): Promise<any> {
    //     try {
    //         const submissionJson = JSON.stringify(submissionData);
    //         const status = isDraft ? 'draft' : 'submitted';
            
    //         const query = await this.databaseService.execute('[portal].[spFormSubmission_Update]', [
    //             { name: "submissionId", type: mssql.TYPES.Int, value: submissionId },
    //             { name: "submissionData", type: mssql.TYPES.NVarChar, value: submissionJson },
    //             { name: "status", type: mssql.TYPES.NVarChar, value: status },
    //         ]);
            
    //         const results = query.singleResult;
    //         return results;
    //     } catch (error) {
    //         console.error('updateFormSubmission', error);
    //         throw error;
    //     }
    // }

    public async getFormSubmission(submissionId: number): Promise<any> {
        try {
            const query = await this.databaseService.execute('[portal].[spFormSubmission_Get]', [
                { name: "submissionId", type: mssql.TYPES.Int, value: submissionId },
            ]);
            
            const results = query.results;
            return results[0];
        } catch (error) {
            console.error('getFormSubmission', error);
            throw error;
        }
    }

    // public async getFormSubmissionsByUser(userId: string, formId?: number): Promise<any> {
    //     try {
    //         const query = await this.databaseService.execute('[portal].[spFormSubmission_GetByUser]', [
    //             { name: "userId", type: mssql.TYPES.NVarChar, value: userId },
    //             { name: "formId", type: mssql.TYPES.Int, value: formId || null },
    //         ]);
            
    //         const results = query.results;
    //         return results;
    //     } catch (error) {
    //         console.error('getFormSubmissionsByUser', error);
    //         throw error;
    //     }
    // }

    // public async getFormSubmissionsByForm(formId: number): Promise<any> {
    //     try {
    //         const query = await this.databaseService.execute('[portal].[spFormSubmission_GetByForm]', [
    //             { name: "formId", type: mssql.TYPES.Int, value: formId },
    //         ]);
            
    //         const results = query.results;
    //         return results;
    //     } catch (error) {
    //         console.error('getFormSubmissionsByForm', error);
    //         throw error;
    //     }
    // }

    public async deleteFormSubmission(submissionId: number): Promise<any> {
        try {
            const query = await this.databaseService.execute('[portal].[spFormSubmission_Delete]', [
                { name: "submissionId", type: mssql.TYPES.Int, value: submissionId },
            ]);
            
            const results = query.results;
            return results;
        } catch (error) {
            console.error('deleteFormSubmission', error);
            throw error;
        }
    }

    public async getFormConfiguration(formId: number): Promise<any> {
        try {
            const query = await this.databaseService.execute('[portal].[spFormConfigurationJSON_Get]', [
                { name: "formId", type: mssql.TYPES.Int, value: formId },
            ]);
            
            const results = query.results;
            return results.length > 0 ? results[0]["FormConfiguration"] : results;
        } catch (error) {
            console.error('getFormConfiguration', error);
            throw error;
        }
    }

    public async getAirportsByName(search: string): Promise<any> {
        try {
            const query = await this.databaseService.execute('Emissions.spAirport_Search', [
                { name: "keyword", type: mssql.TYPES.NVarChar, value: search },
            ]);
            
            const results = query.results;
            return results;
        } catch (error) {
            console.error('getAirportsByName', error);
            throw error;
        }
    }
    public async getCountriesByName(search: string): Promise<any> {
        try {
            const query = await this.databaseService.execute('Emissions.spCountry_Search', [
                { name: "keyword", type: mssql.TYPES.NVarChar, value: search },
            ]);
            
            const results = query.results;
            return results;
        } catch (error) {
            console.error('getCountriesByName', error);
            throw error;
        }
    }
    public async getCurrenciesByName(search: string): Promise<any> {
        try {
            const query = await this.databaseService.execute('Emissions.spCurrency_Search', [
                { name: "keyword", type: mssql.TYPES.NVarChar, value: search },
            ]);
            
            const results = query.results;
            return results;
        } catch (error) {
            console.error('getCurrenciesByName', error);
            throw error;
        }
    }
    
    public async getSubmissionDocumentsbyQuestion(submissionId: number, questionId: number): Promise<any> {
        try {
            const query = await this.databaseService.execute('[portal].[spFormSubmissionDocument_Get]', [
                { name: "submissionId", type: mssql.TYPES.Int, value: submissionId },
                { name: "questionId", type: mssql.TYPES.Int, value: questionId },
            ]);
            
            const results = query.results;
            return results;
        } catch (error) {
            console.error('getSubmissionDocumentsbyQuestion', error);
            throw error;
        }
    }

    public async uploadSubmissionDocument(
        file: Express.Multer.File,
        body: any,
    ): Promise<any> {

        if (body.isPublicFile === 'true' || body.isPublicFile === true) { // For publically accessible files like company logos, return the file URL instead of saving record in portal.CertDocument
            const result = await this.documentsService.uploadToPublicContainer(
                file,
                'company-logo'
            );
            return { url: result.url };
        }
        else {
            // Get file extension from original filename
            const fileExtension = file.originalname.split('.').pop();
            // Add extension to title if missing
            const title = file.originalname; //body.title.includes(`.${fileExtension}`) ? body.title : `${body.title}.${fileExtension}`;
            const request: FileUploadRequest = {
                id: null,
                parentEntityId: body.submissionId,
                parentEntityType: 'nczform-submission',
                customerId: 0, // body.companyId,
                title: title,
                container: 'nczform-submission-docs', //'certification-submission-docs',
                mimeType: file.mimetype,
                size: file.size,
                blobName: file.originalname,
                singleInstance: false,
                canEmbed: false,
                modifiedDate: Date.now()
            };
            const result = await this.documentsService.uploadBuffer(file, request);

            if (result && result.id) { // Add record in portal.CertDocument
                const query = await this.databaseService.execute('[portal].[spFormSubmissionDocument_Save]', [
                    { name: "submissionId", type: mssql.TYPES.Int, value: body.submissionId },
                    { name: "documentId", type: mssql.TYPES.Int, value: result.id },
                    { name: "formId", type: mssql.TYPES.Int, value: body.formId },
                    { name: "questionId", type: mssql.TYPES.Int, value: body.questionId },
                    { name: "displayName", type: mssql.TYPES.NVarChar, value: title },
                ]);
            
                const results = query.results;
                return results[0]; // Return the saved document record
            }
        }
        return null;
    }

    public async uploadSubmissionDocuments(
        files: Express.Multer.File[],
        body: any,
    ): Promise<any[]> {
        const results: any[] = [];
        
        try {
            for (const file of files) {
                // Get file extension from original filename
                const fileExtension = file.originalname.split('.').pop();
                // Add extension to title if missing
                const title = file.originalname;
                
                const request: FileUploadRequest = {
                    id: null, 
                    parentEntityId: body.submissionId,
                    parentEntityType: 'nczform-submission',
                    customerId: 0, //body.companyId,
                    title: title,
                    container: 'nczform-submission-docs', //'certification-submission-docs',
                    mimeType: file.mimetype,
                    size: file.size,
                    blobName: file.originalname,
                    singleInstance: false, 
                    canEmbed: false,
                    modifiedDate: Date.now()
                };
                
                const uploadResult = await this.documentsService.uploadBuffer(file, request);

                if (uploadResult && uploadResult.id) {
                    // Add record in portal.CertDocument
                    const query = await this.databaseService.execute('[portal].[spFormSubmissionDocument_Save]', [
                        { name: "submissionId", type: mssql.TYPES.Int, value: body.submissionId },
                        { name: "documentId", type: mssql.TYPES.Int, value: uploadResult.id },
                        { name: "formId", type: mssql.TYPES.Int, value: body.formId },
                        { name: "questionId", type: mssql.TYPES.Int, value: body.questionId },
                        { name: "displayName", type: mssql.TYPES.NVarChar, value: title },
                    ]);
                    
                    const dbResults = query.results;
                    results.push(dbResults[0]);
                }
            }
            
            return results;
        } catch (error) {
            console.error('uploadSubmissionDocuments', error);
            throw error;
        }
    }

    public async getDocumentDownload(documentId: number): Promise<any> {
        const query = await this.databaseService.execute('[documents].[spDocument_Get]', [
            { name: "documentId", type:mssql.TYPES.Int, value: documentId}
        ]);
        const results = query.singleResult;
        if (results)
        {
            const buffer = await this.documentsService.downloadFile(results.blobName, results.container);
            return { buffer, title: results.title, mimeType: results.mimeType };
        }
        else
        {
            return null;
        }
    }

    public async deleteSubmissionDocument(documentId: number, deleteFile: boolean=false): Promise<any> {
        // Delete record in portal.CertDocument
        const query = await this.databaseService.execute('[portal].[spFormSubmissionDocument_Delete]', [
            { name: "documentId", type: mssql.TYPES.Int, value: documentId },
        ]);
        const results = query.results;

        if (deleteFile && results.length>0) { // Delete file from storage
            return this.documentsService.deleteDocument(results[0]);
        }
    }
}

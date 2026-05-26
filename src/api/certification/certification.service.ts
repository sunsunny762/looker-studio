import { Injectable, StreamableFile } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { DocumentsService } from '../../documents/documents.service';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { Readable } from 'stream';
import { Express } from 'express'; 
import { FileUploadRequest } from '../../documents/model'; // Add this import

@Injectable()
export class CertificationService {

    constructor(private readonly databaseService: DatabaseService, 
        private readonly errorLoggerService: ErrorLoggerService,
        private readonly documentsService: DocumentsService
    ) { }

    public async getCertifications(certId: number | null, status: number | null, certYear: number | null, progId: number | null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCertification_Get]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "status", type: mssql.TYPES.Int, value: status },
            { name: "certYear", type: mssql.TYPES.Int, value: certYear },
            { name: "progId", type: mssql.TYPES.Int, value: progId },
        ]);
        const results = query.results;
        return results;
    }
    public async getBlueAwardCertifications(): Promise<any> {

        const query = await this.databaseService.execute('portal.spCertificationBlueAward_Get', [
        ]);
        const results = query.results;
        return results;
    }

    public async getBlueAwardCertificationById(certSubmissionId: number): Promise<any> {

        const query = await this.databaseService.execute('portal.spCertificationBlueAward_Get', [
            { name: "certSubmissionId", type: mssql.TYPES.Int, value: certSubmissionId },
        ]);
        const result = query.results && query.results.length > 0 ? query.results[0] : null;
        return result;
    }
    
    public async getBlueAwardCertificationsCount(): Promise<any> {

        const query = await this.databaseService.execute('portal.spCertificationBlueAwardCount_Get', [
        ]);
        const results = query.results[0]?.cnt;
        return results;
    }
    
    public async getCertificationsByCompany(companyId: number): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCertification_GetbyCompany]', [
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
        ]);
        const results = query.results;
        return results;
    }
    public async getCertificationDocuments(certId: number): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCertificationDocument_Get]', [
            { name: "certId", type:mssql.TYPES.Int, value: certId}
        ]);
        const results = query.results;
        return results;
    }

    public async getBlueAwardDocuments(certSubmissionId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCertificationBlueAward_Get]', [
            { name: 'certSubmissionId', type: mssql.TYPES.Int, value: certSubmissionId }
        ]);
        const record = query.results && query.results.length > 0 ? query.results[0] : null;
        const documentId = Number(record?.documentId || 0);

        if (!documentId) {
            return [];
        }

        const documentQuery = await this.databaseService.execute('[documents].[spDocument_Get]', [
            { name: 'documentId', type: mssql.TYPES.Int, value: documentId }
        ]);
        const document = documentQuery.singleResult;

        if (!document) {
            return [];
        }

        return [{
            certId: certSubmissionId,
            documentId,
            progId: record?.progId || 1,
            displayName: document.title,
            mimeType: document.mimeType,
            title: document.title,
            parentEntityType: 'blue-award'
        }];
    }

    public async getCertStandardDocuments(progId: number, certId: number): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCertificationProgDocument_Get]', [
            { name: "progId", type:mssql.TYPES.Int, value: progId},
            { name: "certId", type:mssql.TYPES.Int, value: certId}
        ]);
        const results = query.results;
        return results;
    }

    public async addCertificationDocument(certId: number, documentId: number, displayName: string): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCertificationDocument_Save]', [
            { name: "certId",                  type: mssql.TYPES.Int,      value: certId },
            { name: "documentId",              type: mssql.TYPES.Int,      value: documentId },
            { name: "displayName",             type: mssql.TYPES.NVarChar, value: displayName },
            { name: "isCertificationDocument", type: mssql.TYPES.Bit,      value: 0 },
        ]);
        const results = query.results;
        return results;
    }

    public async markCertificationDocument(certId: number, documentId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCertificationDocument_Save]', [
            { name: "certId",                  type: mssql.TYPES.Int,      value: certId },
            { name: "documentId",              type: mssql.TYPES.Int,      value: documentId },
            { name: "displayName",             type: mssql.TYPES.NVarChar, value: null },
            { name: "isCertificationDocument", type: mssql.TYPES.Bit,      value: 1 },
        ]);
        return query.results;
    }

    public async unmarkCertificationDocument(certId: number, documentId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCertificationDocument_Save]', [
            { name: "certId",                  type: mssql.TYPES.Int,      value: certId },
            { name: "documentId",              type: mssql.TYPES.Int,      value: documentId },
            { name: "displayName",             type: mssql.TYPES.NVarChar, value: null },
            { name: "isCertificationDocument", type: mssql.TYPES.Bit,      value: 0 },
        ]);
        return query.results;
    }

    public async getDocumentUrl(documentId: number): Promise<any> {

        const query = await this.databaseService.execute('[documents].[spDocument_Get]', [
            { name: "documentId", type:mssql.TYPES.Int, value: documentId}
        ]);
        const results = query.singleResult;
        if (results)
        {
            const res = await this.documentsService.getSASUrlforView(results.title, results.container, results.blobName);
            return {
                documentId: documentId,
                displayName: results.title,
                mimeType: results.mimeType,
                url: res.url
            };
        }
        else
        {
            return null;
        }
    }

    public async getDocumentDownload(documentId: number): Promise<any> {
        const query = await this.databaseService.execute('[documents].[spDocument_Get]', [
            { name: "documentId", type:mssql.TYPES.Int, value: documentId}
        ]);
        const results = query.singleResult;
        if (results)
        {
            return await this.documentsService.downloadFile(results.blobName, results.container);
        }
        else
        {
            return null;
        }
    }

    
    // public async getCertSubmissions(certId: number): Promise<any> {

    //     const query = await this.databaseService.execute('[portal].[spCertification_GetSubmissions]', [
    //         { name: "certId", type:mssql.TYPES.Int, value: certId}
    //     ]);
    //     const results = query.results;
    //     return results;
    // }

    public async addCertification(companyId: number, progId: number, startDate: string, refNumber: string, status: number,
                                    description: string, certificationTaskId: string,
                                    emissionProfileId: number, revenue: number, headCount: number | null = null
                    ): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCertification_Save]', [
            { name: "certId", type: mssql.TYPES.Int, value: null },
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "progId", type: mssql.TYPES.Int, value: progId },
            { name: "startDate", type: mssql.TYPES.NVarChar, value: startDate },
            { name: "refNumber", type: mssql.TYPES.NVarChar, value: refNumber },
            { name: "status", type: mssql.TYPES.Int, value: status },
            { name: "description", type: mssql.TYPES.NVarChar, value: description },
            { name: "certificationTaskId", type: mssql.TYPES.NVarChar, value: certificationTaskId },
            { name: "emissionProfileId", type: mssql.TYPES.Int, value: emissionProfileId }, 
            { name: "revenue", type: mssql.TYPES.Decimal, value: revenue },
            { name: "headCount", type: mssql.TYPES.Int, value: headCount },
        ]);
        
        const results = query.results;
        return results;
    }
    public async updateCertification(certId: number, companyId: number, progId: number, startDate: string, refNumber: string, status: number,
                                    description: string, certificationTaskId: string,
                                    emissionProfileId: number, revenue: number, headCount: number | null = null
                    ): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCertification_Save]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "progId", type: mssql.TYPES.Int, value: progId },
            { name: "startDate", type: mssql.TYPES.NVarChar, value: startDate },
            { name: "refNumber", type: mssql.TYPES.NVarChar, value: refNumber },
            { name: "status", type: mssql.TYPES.Int, value: status },
            { name: "description", type: mssql.TYPES.NVarChar, value: description },
            { name: "certificationTaskId", type: mssql.TYPES.NVarChar, value: certificationTaskId },
            { name: "emissionProfileId", type: mssql.TYPES.Int, value: emissionProfileId }, 
            { name: "revenue", type: mssql.TYPES.Decimal, value: revenue },
            { name: "headCount", type: mssql.TYPES.Int, value: headCount },
        ]);
        
        const results = query.results;
        return results;
    }

    public async deleteCertification(certId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCertification_Delete]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
        ]);
        
        const results = query.results;
        return results;
    }

    public async uploadCertificationDocument(
        file: Express.Multer.File,
        body: any,
    ): Promise<any> {
        try {
            // Get file extension from original filename
            const fileExtension = file.originalname.split('.').pop();
            // Add extension to title if missing
            const title = body.title.includes(`.${fileExtension}`) ? body.title : `${body.title}.${fileExtension}`;
            const request: FileUploadRequest = {
                id: null, 
                parentEntityId: parseInt(body.certId), // body.certId,
                parentEntityType: 'certification',
                customerId: parseInt(body.companyId), // body.companyId,
                title: title,
                container: 'certifications',
                mimeType: file.mimetype,
                size: file.size,
                blobName: file.originalname,
                singleInstance: false, 
                canEmbed: false,
                modifiedDate: Date.now()
            };
            const result = await this.documentsService.uploadBuffer(file, request);

            if (result && result.id) { // Add record in portal.CertDocument
                const query = await this.databaseService.execute('[portal].[spCertificationDocument_Save]', [
                    { name: "certId",                  type: mssql.TYPES.Int,      value: parseInt(body.certId) },
                    { name: "documentId",              type: mssql.TYPES.Int,      value: result.id },
                    { name: "displayName",             type: mssql.TYPES.NVarChar, value: body.title },
                    { name: "isCertificationDocument", type: mssql.TYPES.Bit,      value: 0 },
                ]);
                
                const results = query.results;
            }
            return result;
        } catch (error) {
            console.error('uploadCertificationDocument', error);
            //this.errorLoggerService.error('uploadCertificationDocument', error, { body });
            throw error;
        }
    }

    public async uploadBlueAwardDocument(
        file: Express.Multer.File,
        body: any,
    ): Promise<any> {
        try {
            const fileExtension = file.originalname.split('.').pop();
            const title = body.title.includes(`.${fileExtension}`) ? body.title : `${body.title}.${fileExtension}`;
            const certSubmissionId = parseInt(body.certSubmissionId, 10);
            const companyId = parseInt(body.companyId, 10) || 0;
            const blueAwardQuery = await this.databaseService.execute('[portal].[spCertificationBlueAward_Get]', [
                { name: 'certSubmissionId', type: mssql.TYPES.Int, value: certSubmissionId }
            ]);
            const blueAward = blueAwardQuery.results && blueAwardQuery.results.length > 0 ? blueAwardQuery.results[0] : null;

            if (!blueAward) {
                throw new Error('Blue award certification not found');
            }

            const request: FileUploadRequest = {
                id: null,
                parentEntityId: certSubmissionId,
                parentEntityType: 'blue-award',
                customerId: companyId,
                title,
                container: 'blue-award-report',
                mimeType: file.mimetype,
                size: file.size,
                blobName: file.originalname,
                singleInstance: false,
                canEmbed: false,
                modifiedDate: Date.now()
            };

            const result = await this.documentsService.uploadBuffer(file, request);

            if (result?.id) {
                await this.databaseService.execute('[portal].[spCertificationBlueAwardStatus_Update]', [
                    { name: 'certSubmissionId', type: mssql.TYPES.Int, value: certSubmissionId },
                    { name: 'status', type: mssql.TYPES.Int, value: blueAward.statusId },
                    { name: 'notes', type: mssql.TYPES.NVarChar, value: blueAward.notes || null },
                    { name: 'documentId', type: mssql.TYPES.Int, value: result.id },
                ]);
            }

            return result;
        } catch (error) {
            console.error('uploadBlueAwardDocument', error);
            throw error;
        }
    }
    

    public async deleteCertificationDocument(certId: number, documentId: number, deleteFile: boolean=false): Promise<any> {
        // Delete record in portal.CertDocument
        const query = await this.databaseService.execute('[portal].[spCertificationDocument_Delete]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "documentId", type: mssql.TYPES.Int, value: documentId },
        ]);
        const results = query.results;

        if (deleteFile && results.length>0) { // Delete file from storage
            return this.documentsService.deleteDocument(results[0]);
        }
    }

    public async deleteBlueAwardDocument(certSubmissionId: number, documentId: number, deleteFile: boolean = false): Promise<any> {
        await this.databaseService.query(`
            UPDATE portal.BlueAwardCertification
            SET documentId = NULL,
                dateUpdated = GETDATE()
            WHERE certSubmissionId = ${certSubmissionId}
              AND documentId = ${documentId}
        `);

        const query = await this.databaseService.execute('[documents].[spDocument_Get]', [
            { name: 'documentId', type: mssql.TYPES.Int, value: documentId },
        ]);
        const document = query.singleResult;

        if (deleteFile && document) {
            return this.documentsService.deleteDocument(document);
        }

        return null;
    }

    public async updateCompanyTaskIds(companyId: number, companyTaskId: string, personTaskId: string): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCompany_UpdateTaskIds]', [
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "companyTaskId", type: mssql.TYPES.NVarChar, value: companyTaskId },
            { name: "personTaskId", type: mssql.TYPES.NVarChar, value: personTaskId },
        ]);

        return query.results;
    }

    public async getCHWTokens(certId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCertCHWTokens_Get]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
        ]);
        const results = query.results;
        return results;
    }

    public async updateBlueAwardStatus(certSubmissionId: number, status: number, notes: string): Promise<any> {
        // Update the status & Get return the full updated record
        const query = await this.databaseService.execute('[portal].[spCertificationBlueAwardStatus_Update]', [
            { name: "certSubmissionId", type: mssql.TYPES.Int, value: certSubmissionId },
            { name: "status", type: mssql.TYPES.Int, value: status },
            { name: "notes", type: mssql.TYPES.NVarChar, value: notes },
        ]);
        
        // // Get and return the full updated record
        // const query = await this.databaseService.execute('[portal].[spCertificationBlueAward_Get]', [
        //     { name: "certSubmissionId", type: mssql.TYPES.Int, value: certSubmissionId },
        // ]);
        
        return query.results && query.results.length > 0 ? query.results[0] : null;
    }

    public async deleteBlueAwardCertification(certSubmissionId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCertificationBlueAward_Delete]', [
            { name: "certSubmissionId", type: mssql.TYPES.Int, value: certSubmissionId },
        ]);
        return query.results;
    }

    public async getCertificationHeadCount(certId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCertificationHeadCount_Get]', [
            { name: 'certId', type: mssql.TYPES.Int, value: certId },
        ]);
        return {
            certData: query.recordsets[0]?.[0] || null,
            locations: query.recordsets[1] || [],
        };
    }

    public async saveCertificationHeadCount(
        certId: number,
        headCount: number | null,
        revenue: number | null,
        locations: Array<{ locationId: number; headCount: number | null; revenue: number | null }>
    ): Promise<any> {
        // Update certification-level totals
        await this.databaseService.execute('[portal].[spCertificationHeadCount_Save]', [
            { name: 'certId',    type: mssql.TYPES.Int,     value: certId },
            { name: 'headCount', type: mssql.TYPES.Int,     value: headCount },
            { name: 'revenue',   type: mssql.TYPES.Decimal, value: revenue },
        ]);

        // Upsert per-location rows
        for (const loc of locations) {
            await this.databaseService.execute('[portal].[spCertificationHeadCount_Save]', [
                { name: 'certId',       type: mssql.TYPES.Int,     value: certId },
                { name: 'locationId',   type: mssql.TYPES.Int,     value: loc.locationId },
                { name: 'locHeadCount', type: mssql.TYPES.Int,     value: loc.headCount },
                { name: 'locRevenue',   type: mssql.TYPES.Decimal, value: loc.revenue },
            ]);
        }

        return { success: true };
    }

}

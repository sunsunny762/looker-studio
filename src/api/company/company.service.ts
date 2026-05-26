import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { th } from 'date-fns/locale';

@Injectable()
export class CompanyService {

    constructor(private readonly databaseService: DatabaseService, 
        private readonly errorLoggerService: ErrorLoggerService
    ) { }

    public async getCompanies(companyId: number | null, status: number | null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCompany_Get]', [
            { name: "status", type: mssql.TYPES.Int, value: status },
            { name: "companyId", type:mssql.TYPES.Int, value: companyId}
        ]);
        const results = query.results;
        return results;
    }
    public async getNCZDirectory(dirItemId: number | null, showAll: boolean): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spNCZDirectory_Get]', [
            { name: "showAll", type: mssql.TYPES.Bit, value: showAll },
            { name: "dirItemId", type: mssql.TYPES.Int, value: dirItemId },
        ]);
        const results = query.results;
        return results;
    }

    public async updateNCZDirectory(dirItemId: number, companyName: string, certTaskId: string, customerReference: string,
                                    isVisible: number, isArchive: number, co2PerRevenue: string
                                    ): Promise<any> {

       const query = await this.databaseService.execute('[portal].[spNCZDirectory_Save]', [
        { name: "dirItemId", type: mssql.TYPES.Int, value: dirItemId },
        { name: "customerReference", type: mssql.TYPES.NVarChar, value: customerReference || null },
        { name: "certTaskId", type: mssql.TYPES.NVarChar, value: certTaskId || null },
        { name: "companyName", type: mssql.TYPES.NVarChar, value: companyName || null },
        { name: "isVisible", type: mssql.TYPES.Int, value: isVisible },
        { name: "isArchive", type: mssql.TYPES.Int, value: isArchive },
        { name: "co2PerRevenue", type: mssql.TYPES.NVarChar, value: co2PerRevenue },
    ]);
        
        const results = query.results;
        return results;
    }
    // public async getCustomerDirectory(userCompanyId: number): Promise<any> {

    //     const query = await this.databaseService.execute('[portal].[spCompany_GetCustDirectory]', [
    //         { name: "userCompanyId", type:mssql.TYPES.Int, value: userCompanyId}
    //     ]);
    //     const results = query.results;
    //     return results;
    // }
    public async addCompany(companyName: string, email: string, registrationNumber: string, phone: string, address: string,
        industryType: number, industryTypeOther: string, website: string, contactName: string, jobTitle: string, status: number, locationCnt: number,
        companyTaskId: string, personTaskId: string,
        description: string): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCompany_Save]', [
            { name: "companyId", type: mssql.TYPES.Int, value: null },
            { name: "companyName", type: mssql.TYPES.NVarChar, value: companyName },
            { name: "email", type: mssql.TYPES.NVarChar, value: email },
            { name: "registrationNumber", type: mssql.TYPES.NVarChar, value: registrationNumber },
            { name: "phone", type: mssql.TYPES.NVarChar, value: phone },
            { name: "address", type: mssql.TYPES.NVarChar, value: address },
            { name: "industryType", type: mssql.TYPES.Int, value: industryType },
            { name: "industryTypeOther", type: mssql.TYPES.NVarChar, value: industryTypeOther },
            { name: "website", type: mssql.TYPES.NVarChar, value: website },
            { name: "contactName", type: mssql.TYPES.NVarChar, value: contactName },
            { name: "jobTitle", type: mssql.TYPES.NVarChar, value: jobTitle },
            { name: "status", type: mssql.TYPES.Int, value: status },
            { name: "locationCnt", type: mssql.TYPES.Int, value: locationCnt },
            { name: "companyTaskId", type: mssql.TYPES.NVarChar, value: companyTaskId },
            { name: "personTaskId", type: mssql.TYPES.NVarChar, value: personTaskId },
            { name: "description", type: mssql.TYPES.NVarChar, value: description },
        ]);
        
        const results = query.results;
        return results;
    }
    public async updateCompany(companyId: number, companyName: string, email: string, registrationNumber: string, phone: string, address: string,
        industryType: number, industryTypeOther: string, website: string, contactName: string, jobTitle: string, status: number, locationCnt:number,
        companyTaskId: string, personTaskId: string,
        description: string): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCompany_Save]', [
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "companyName", type: mssql.TYPES.NVarChar, value: companyName },
            { name: "email", type: mssql.TYPES.NVarChar, value: email },
            { name: "registrationNumber", type: mssql.TYPES.NVarChar, value: registrationNumber },
            { name: "phone", type: mssql.TYPES.NVarChar, value: phone },
            { name: "address", type: mssql.TYPES.NVarChar, value: address },
            { name: "industryType", type: mssql.TYPES.Int, value: industryType },
            { name: "industryTypeOther", type: mssql.TYPES.NVarChar, value: industryTypeOther },
            { name: "website", type: mssql.TYPES.NVarChar, value: website },
            { name: "contactName", type: mssql.TYPES.NVarChar, value: contactName },
            { name: "jobTitle", type: mssql.TYPES.NVarChar, value: jobTitle },
            { name: "status", type: mssql.TYPES.Int, value: status },
            { name: "locationCnt", type: mssql.TYPES.Int, value: locationCnt },
            { name: "companyTaskId", type: mssql.TYPES.NVarChar, value: companyTaskId },
            { name: "personTaskId", type: mssql.TYPES.NVarChar, value: personTaskId },
            { name: "description", type: mssql.TYPES.NVarChar, value: description },
        ]);
        
        const results = query.results;
        return results;
    }

    public async deleteCompany(companyId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spCompany_Delete]', [
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
        ]);
        
        const results = query.results;
        return results;
    }

    public async addDirectoryForm(
        companyId: number, salesName: string, salesEmail: string, salesPhone: string,
        esgName: string, esgEmail: string, esgPhone: string, website: string,
        linkedinPage: string, facebookPage: string, instagramPage: string, emissionOffset:string,
        companyDescription: string, offersDiscounts: string, certId: number | null
    ): Promise<any> {
        const query = await this.databaseService.execute("[portal].[spNCZDirectory_SaveForm]", [
            { name: "dirItemId", type: mssql.TYPES.Int, value: null },
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "salesName", type: mssql.TYPES.NVarChar, value: salesName },
            { name: "salesEmail", type: mssql.TYPES.NVarChar, value: salesEmail },
            { name: "salesPhone", type: mssql.TYPES.NVarChar, value: salesPhone },
            { name: "esgName", type: mssql.TYPES.NVarChar, value: esgName },
            { name: "esgEmail", type: mssql.TYPES.NVarChar, value: esgEmail },
            { name: "esgPhone", type: mssql.TYPES.NVarChar, value: esgPhone },
            { name: "website", type: mssql.TYPES.NVarChar, value: website },
            { name: "linkedinPage", type: mssql.TYPES.NVarChar, value: linkedinPage },
            { name: "facebookPage", type: mssql.TYPES.NVarChar, value: facebookPage },
            { name: "instagramPage", type: mssql.TYPES.NVarChar, value: instagramPage },
            { name: "emissionOffset", type: mssql.TYPES.NVarChar, value: emissionOffset },
            { name: "companyDescription", type: mssql.TYPES.NVarChar, value: companyDescription },
            { name: "offersDiscounts", type: mssql.TYPES.NVarChar, value: offersDiscounts },
            { name: "certId", type: mssql.TYPES.Int, value: certId }
        ]);
        return query.results;
    }

    public async addNCZDirectorySupplier( submissionId:number ): Promise<any> {
        const query = await this.databaseService.execute("[portal].[spNCZDirectorySupplier_Save]", [
            { name: "submissionId", type: mssql.TYPES.Int, value: submissionId }
        ]);
        return query.results;
    }
}
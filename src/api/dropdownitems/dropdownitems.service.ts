import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';

@Injectable()
export class DropdownItemsService {

    constructor(private readonly databaseService: DatabaseService, 
        private readonly errorLoggerService: ErrorLoggerService
    ) { }

    public async getDropdownItems(groupId: number | null, itemId: number | null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spDropdownItems_GetDDL]', [
            { name: "groupId", type: mssql.TYPES.Int, value: groupId },
            { name: "itemId", type: mssql.TYPES.Int, value: itemId },
        ]);
        const results = query.results;
        return results;
    }

    public async getCompanyDropdown(companyId: number | null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCompany_GetDDL]', [
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
        ]);
        const results = query.results;
        return results;
    }
    public async getCountryDropdown(): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCountry_GetDDL]', [
        ]);
        const results = query.results;
        return results;
    }
    public async getCurrencyDropdown(): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spCurrency_GetDDL]', [
        ]);
        const results = query.results;
        return results;
    }
    public async getProgDropdown(progId: number | null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spProgramme_GetDDL]', [
            { name: "progId", type: mssql.TYPES.Int, value: progId },
        ]);
        const results = query.results;
        return results;
    }

    public async getFormDropdown(certId: number | null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spProgrammeForms_GetDDL]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId }
        ]);
        const results = query.results;
        return results;
    }

    public async getRoleDropdown( companyId: number, roleId: number | null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spUserRole_GetDDL]', [
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "roleId", type: mssql.TYPES.Int, value: roleId },
        ]);
        const results = query.results;
        return results;
    }
    public async getLocationDropdown( certId: number, uCompanyId: number | null = null, forCMP: number = 0): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spLocation_GetDDL]', [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "forCMP", type: mssql.TYPES.Bit, value: forCMP },
            { name: "uCompanyId", type: mssql.TYPES.Int, value: uCompanyId }
        ]);
        const results = query.results;
        return results;
    }

    public async addDropdownItems(groupId: number, itemValue: string): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spDropdownItems_Save]', [
            { name: "itemId", type: mssql.TYPES.Int, value: null },
            { name: "groupId", type: mssql.TYPES.Int, value: groupId },
            { name: "itemValue", type: mssql.TYPES.NVarChar, value: itemValue },
        ]);
        
        const results = query.results;
        return results;
    }
    public async updateDropdownItems(itemId: number, groupId: number, itemValue: string): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spDropdownItems_Save]', [
            { name: "itemId", type: mssql.TYPES.Int, value: itemId },
            { name: "groupId", type: mssql.TYPES.Int, value: groupId },
            { name: "itemValue", type: mssql.TYPES.NVarChar, value: itemValue },
        ]);
        
        const results = query.results;
        return results;
    }

    public async deleteDropdownItems(itemId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spDropdownItems_Delete]', [
            { name: "itemId", type: mssql.TYPES.Int, value: itemId },
        ]);
        
        const results = query.results;
        return results;
    }

    public async getEmissionProfileDropdown( emissionProfileId: number = null): Promise<any> {
        const query = await this.databaseService.execute('[Emissions].[spEmissionProfile_Get]', [
            { name: "emissionProfileId", type: mssql.TYPES.Int, value: emissionProfileId },
        ]);
        
        const results = query.results;
        return results;
    }
}
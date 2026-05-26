import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';
import { th } from 'date-fns/locale';

@Injectable()
export class LocationService {

    constructor(private readonly databaseService: DatabaseService, 
        private readonly errorLoggerService: ErrorLoggerService
    ) { }

    public async getLocations( companyId: number | null, locationId: number | null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spLocation_Get]', [
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "locationId", type:mssql.TYPES.Int, value: locationId}
        ]);
        const results = query.results;
        return results;
    }

    public async addLocation(locationName: string, companyId: number, currency: string, countryId: number, logo: string | null = null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spLocation_Save]', [
            { name: "locationId", type: mssql.TYPES.Int, value: null },
            { name: "locationName", type: mssql.TYPES.NVarChar, value: locationName },
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "currency", type: mssql.TYPES.NVarChar, value: currency },
            { name: "countryId", type: mssql.TYPES.Int, value: countryId },
            { name: "logo", type: mssql.TYPES.NVarChar, value: logo },
        ]);
        
        const results = query.results;
        return results;
    }
    public async updateLocation(locationId: number, locationName: string, currency: string, countryId: number, logo: string | null = null): Promise<any> {

        const query = await this.databaseService.execute('[portal].[spLocation_Save]', [
            { name: "locationId", type: mssql.TYPES.Int, value: locationId },
            { name: "locationName", type: mssql.TYPES.NVarChar, value: locationName },
            { name: "companyId", type: mssql.TYPES.Int, value: null },
            { name: "currency", type: mssql.TYPES.NVarChar, value: currency },
            { name: "countryId", type: mssql.TYPES.Int, value: countryId },
            { name: "logo", type: mssql.TYPES.NVarChar, value: logo },
        ]);
        
        const results = query.results;
        return results;
    }

    public async deleteLocation(locationId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spLocation_Delete]', [
            { name: "locationId", type: mssql.TYPES.Int, value: locationId },
        ]);
        
        const results = query.results;
        return results;
    }
}
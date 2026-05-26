import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../../database/database.service';
import * as mssql from 'mssql';

@Injectable()
export class TokenService {
  constructor(private readonly databaseService: DatabaseService) {}

  async validateToken(tokenKey: string, tokenType: string) {
    const result = await this.databaseService.execute('[portal].[spToken_Validate]', [
      { name: 'tokenType', type: mssql.TYPES.NVarChar, value: tokenType },
      { name: 'tokenKey', type: mssql.TYPES.NVarChar, value: tokenKey },
    ]);
    
    if (result.results && result.results.length > 0) {
      const tokenData = result.results[0];
      
      // Parse properties JSON if it exists and add certSubmissionId to the response
      if (tokenData.properties) {
        try {
          const properties = JSON.parse(tokenData.properties);
          if (properties.certSubmissionId) {
            tokenData.certSubmissionId = properties.certSubmissionId;
          }
        } catch (error) {
          console.error('Error parsing token properties:', error);
        }
      }
      
      return tokenData;
    }
    
    return null;
  }

  async getTokens(dimFormId: number, tokenType: string | null, activeOnly: boolean): Promise<any[]> {
    const result = await this.databaseService.execute('[portal].[spToken_Get]', [
      { name: 'dimFormId',  type: mssql.TYPES.Int,      value: dimFormId },
      { name: 'tokenType',  type: mssql.TYPES.NVarChar, value: tokenType },
      { name: 'activeOnly', type: mssql.TYPES.Bit,      value: activeOnly ? 1 : 0 },
    ]);
    return result.results ?? [];
  }

  async createToken(certId: number, locationId: number, dimFormId: number, activeTo: Date, isActive: boolean, tokenType?: string, properties?: string) {
    const result = await this.databaseService.execute('[portal].[spToken_Save]', [
      { name: 'certId', type: mssql.TYPES.Int, value: certId },
      { name: 'locationId', type: mssql.TYPES.Int, value: locationId },
      { name: 'dimFormId', type: mssql.TYPES.Int, value: dimFormId },
      { name: 'activeTo', type: mssql.TYPES.DateTime2, value: activeTo },
      { name: 'isActive', type: mssql.TYPES.Bit, value: isActive },
      { name: 'tokenType', type: mssql.TYPES.NVarChar, value: tokenType || null },
      { name: 'properties', type: mssql.TYPES.NVarChar, value: properties || null },
    ]);
    return result.results && result.results.length > 0 ? result.results[0] : null;
  }

  async updateToken(
    tokenId: number,
    certId: number,
    locationId: number,
    dimFormId: number,
    activeTo: Date,
    isActive: boolean,
    tokenType?: string,
    properties?: string
  ) {
    const result = await this.databaseService.execute('[portal].[spToken_Save]', [
      { name: 'tokenId', type: mssql.TYPES.Int, value: tokenId },
      { name: 'certId', type: mssql.TYPES.Int, value: certId },
      { name: 'locationId', type: mssql.TYPES.Int, value: locationId },
      { name: 'dimFormId', type: mssql.TYPES.Int, value: dimFormId },
      { name: 'activeTo', type: mssql.TYPES.DateTime2, value: activeTo },
      { name: 'isActive', type: mssql.TYPES.Bit, value: isActive },
      { name: 'tokenType', type: mssql.TYPES.NVarChar, value: tokenType || null },
      { name: 'properties', type: mssql.TYPES.NVarChar, value: properties || null },
    ]);
    return result.results && result.results.length > 0 ? result.results[0] : null;
  }

}

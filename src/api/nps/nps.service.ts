import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';

@Injectable()
export class NpsService {

    constructor(private readonly databaseService: DatabaseService) { }

    public async submitNps(certId: number, score: number, reason: string | null, userId: number | null): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spNPS_Save]', [
            { name: 'certId', type: mssql.TYPES.Int,     value: certId },
            { name: 'score',  type: mssql.TYPES.Int,     value: score },
            { name: 'reason', type: mssql.TYPES.NVarChar, value: reason ?? null },
            { name: 'userId', type: mssql.TYPES.Int,     value: userId ?? null },
        ]);
        return query.results;
    }

    public async getNpsByCert(certId: number): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spNPS_GetByCert]', [
            { name: 'certId', type: mssql.TYPES.Int, value: certId },
        ]);
        const row = query.singleResult;
        return { submitted: !!row };
    }

    public async getNpsYtd(): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spNPS_GetYTD]', []);
        return query.singleResult ?? {
            totalResponses: 0,
            promoters: 0,
            passives: 0,
            detractors: 0,
            npsScore: null,
            year: new Date().getFullYear(),
        };
    }

    public async getAllNpsResponses(): Promise<any> {
        const query = await this.databaseService.execute('[portal].[spNPS_GetAll]', []);
        return query.results;
    }
}

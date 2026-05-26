import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database';
import { ErrorLoggerService } from '../../error-logger/error-logger.service';

@Injectable()
export class PublicFormsService {
    constructor(
        private readonly databaseService: DatabaseService,
        private readonly errorLoggerService: ErrorLoggerService,
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
}


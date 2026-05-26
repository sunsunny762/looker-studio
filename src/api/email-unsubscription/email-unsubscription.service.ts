import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../../database/database.service';
import { EmailUnsubscription } from './email-unsubscription.model';

@Injectable()
export class EmailUnsubscriptionService {
  constructor(private readonly databaseService: DatabaseService) {}

  async createUnsubscription(
    email: string,
    reason: string,
    details: string | null = null,
  ): Promise<EmailUnsubscription> {
    const result = await this.databaseService.execute('[portal].[spEmailUnsubscription_Save]', [
      { name: 'Email',   type: mssql.TYPES.NVarChar, value: email },
      { name: 'Reason',  type: mssql.TYPES.NVarChar, value: reason },
      { name: 'Details', type: mssql.TYPES.NVarChar, value: details ?? null },
    ]);
    return result.results?.[0] ?? null;
  }

  async getUnsubscriptions(): Promise<EmailUnsubscription[]> {
    const result = await this.databaseService.execute('[portal].[spEmailUnsubscription_Get]', [
      { name: 'Email', type: mssql.TYPES.NVarChar, value: null },
    ]);
    return result.results ?? [];
  }

  async checkUnsubscription(email: string): Promise<EmailUnsubscription | null> {
    const result = await this.databaseService.execute('[portal].[spEmailUnsubscription_Get]', [
      { name: 'Email', type: mssql.TYPES.NVarChar, value: email },
    ]);
    return result.results?.[0] ?? null;
  }

  async resubscribe(email: string): Promise<EmailUnsubscription | null> {
    const result = await this.databaseService.execute('[portal].[spEmailUnsubscription_Resubscribe]', [
      { name: 'Email', type: mssql.TYPES.NVarChar, value: email },
    ]);
    return result.results?.[0] ?? null;
  }

  /** Returns a Set of email addresses that are currently unsubscribed. */
  async getUnsubscribedEmails(): Promise<Set<string>> {
    const rows = await this.getUnsubscriptions();
    return new Set(
      rows.filter((r) => r.isUnsubscribed).map((r) => r.email.toLowerCase()),
    );
  }
}

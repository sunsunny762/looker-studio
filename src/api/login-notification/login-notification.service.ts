import { Injectable } from '@nestjs/common';
import { DatabaseService } from '../../database';
import * as mssql from 'mssql';

@Injectable()
export class LoginNotificationService {

    constructor(private readonly databaseService: DatabaseService) {}

    /**
     * Checks whether the renewal alert dialog should be shown for this user this week.
     * Returns showDialog flag and the last certification end date.
     */
    public async checkRenewalAlert(uid: string): Promise<{ showDialog: boolean }> {
        const query = await this.databaseService.execute('[portal].[spRenewalAlertCheck]', [
            { name: 'uid',       type: mssql.TYPES.NVarChar, value: uid }
        ]);

        const result = query.results?.[0];
        return {
            showDialog: result?.showDialog === true || result?.showDialog === 1
        };
    }

    /**
     * Records that the renewal alert dialog was shown to the user this week.
     */
    public async dismissRenewalAlert(uid: string): Promise<void> {
        await this.databaseService.execute('[portal].[spRenewalAlertDismiss]', [
            { name: 'uid',       type: mssql.TYPES.NVarChar, value: uid }
        ]);
    }
}

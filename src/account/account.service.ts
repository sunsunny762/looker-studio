import { Injectable, Logger } from '@nestjs/common';
import { DatabaseService } from '../database';
import { ErrorLoggerService } from '../error-logger/error-logger.service';
import { FirebaseAuthService } from '../firebase/firebase-auth.service';
import * as mssql from 'mssql';

@Injectable()
export class AccountService {
  private readonly logger = new Logger(AccountService.name);

  constructor(
    private readonly databaseService: DatabaseService,
    private readonly errorLoggerService: ErrorLoggerService,
    private readonly firebaseAuthService: FirebaseAuthService,
  ) {}

  /**
   * Returns the user profile and ensures Firebase claims are up to date
   */
  public async me(user: any): Promise<any> {
    try {
      // 1️⃣ Fetch user profile from SQL
      const query = await this.databaseService.execute('portal.spUser_GetbyUId', [
        { name: 'uId', type: mssql.TYPES.NVarChar, value: user.uid },
      ]);

      const results = query.recordsets;
      const profile = results[0]?.[0];
      const permissions = results[1] || [];

      if (!profile) {
        this.logger.warn(`User not found for uid=${user.uid}`);
        return { error: 'User not found' };
      }

      const claims = {
        cId: profile.companyId,
      };

      // 3️⃣ Update Firebase custom claims
      await this.firebaseAuthService.setUserClaims(user.uid, claims);

      // 4️⃣ Return enriched profile data
      return {
        ...profile,
        options: permissions,
        claims,
      };
    } catch (error) {
      this.logger.error(`Error in AccountService.me: ${error.message}`);
      throw error;
    }
  }
}

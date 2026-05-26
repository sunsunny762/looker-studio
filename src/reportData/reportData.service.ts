import { Injectable } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from "../database/database.service";

enum CertificationStatus {
  DataCollectionComplete = 2,
  ReportUnderProcess = 3,
  ReportGenerated = 4
}

@Injectable()
export class ReportDataService {
  constructor(
       private readonly databaseService: DatabaseService,
  ) {}

  public async insertSilverReportData() {
    try {
      console.log('Inserting Silver Report Data...');
      const query = await this.databaseService.execute("[Reports].[spSilverCertificationCompletedData]");
      const responses = query.results;
      if (responses.length == 0) return 0;

      const dataInsert = 1;

      for (const row of responses) {
        const certId = row?.certId;
        const companyId = row?.companyId;
        const emissionProfileIdRaw = Number(row?.emissionProfileId);
        const emissionProfileId = Number.isInteger(emissionProfileIdRaw) && emissionProfileIdRaw > 0 ? emissionProfileIdRaw : 9;
        if (!certId) {
          continue;
        }
        
        try {
          await this.databaseService.execute("[DataModel].[spSilver_DataOutputDetailedWrapper_Portal]", [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "emissionProfileId", type: mssql.TYPES.Int, value: emissionProfileId },
            { name: "dataInsert", type: mssql.TYPES.Int, value: dataInsert }
          ]);
        } catch (error) {
          console.error(`spSilver_DataOutputDetailedWrapper_Portal failed for certId: ${certId}, companyId: ${companyId}`, error);
          continue;
        }

        try {
          await this.databaseService.execute("[DataModel].[spSilver_DataOutputWrapper_Portal]", [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "emissionProfileId", type: mssql.TYPES.Int, value: emissionProfileId },
            { name: "dataInsert", type: mssql.TYPES.Int, value: dataInsert }
          ]);
        } catch (error) {
          console.error(`spSilver_DataOutputWrapper_Portal failed for certId: ${certId}, companyId: ${companyId}`, error);
          continue;
        }

        if ([CertificationStatus.DataCollectionComplete, CertificationStatus.ReportUnderProcess].includes(row?.status)) {
          await this.databaseService.execute("[portal].[spCertification_UpdateStatus]", [
            { name: "certId", type: mssql.TYPES.Int, value: certId },
            { name: "companyId", type: mssql.TYPES.Int, value: companyId },
            { name: "status", type: mssql.TYPES.Int, value: CertificationStatus.ReportGenerated }
          ]);
        }
      }
    } catch (error) {
      console.error('insertSilverReportData', error);
      return 0;
    }
  }
}

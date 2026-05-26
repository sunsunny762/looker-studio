import { Injectable } from '@nestjs/common';
import fetch from 'node-fetch';
import qs from 'qs';
import * as fs from 'fs';
//import { ErrorLoggerService } from "../error-logger/error-logger.service";
import * as mssql from 'mssql';
import { DatabaseService } from "../database/database.service";
import { EmailService } from '../email/email.service';
import { DocumentsService } from '../documents/documents.service';
import { v4 as uuidv4 } from 'uuid';
import * as moment from 'moment';

@Injectable()
export class PowerbiService {
  constructor(
    //private readonly errorLoggerService: ErrorLoggerService,
    private readonly emailService: EmailService,
    private readonly databaseService: DatabaseService,
    private readonly documentsService: DocumentsService
  ) {}

  private tenantId = process.env.POWERBI_TENANT_ID;
  private clientId = process.env.POWERBI_CLIENT_ID;
  private clientSecret = process.env.POWERBI_CLIENT_SECRET;
  private groupId = process.env.POWERBI_WORKSPACE_ID;
  private token = ''; tokenExpiry = null;

  public async exportPowerBIReports() {
    try {
      const query = await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_GetList]");
      const responses = query.results;
      if(responses.length==0) return 0;

      await this.getToken();
      for (let response of responses) {
        try {
          const reportId = this.getReportId(response.productName);
          switch(response.status) {
            case 0: // Pending to be requested status
              await this.powerBIReportRequest(response.submissionId, reportId, response.companyName);
              break;
            case 2: // Requested status
              await this.powerBIReportStatus(response.exportId, response.submissionId, reportId);
              break;
            case 3: // Generated status
              await this.powerBIReportDownload(response.resourceLocation, response.submissionId, response.reportPDFFileName);
              break;
            case 4: // Downloaded status
              await this.powerBIReportUpload(response.customerId, response.Id, response.submissionId, response.reportPDFFileName);
              break;
            case 5: // Uploaded status
              await this.powerBIReportEmail(response.emailTo, response.submissionId, response.documentId, response.productName);
              break;
          }
        }
        catch (error) {
          console.error('exportPowerBIReports', error);
        }
      }
    } catch (error) {
      console.error('exportRequestQueue', error);
      return 0;
    }
  }
  
  getReportId (productName: string): string { 
    switch(productName.toUpperCase()) {
      case 'BLUE':
        return process.env.POWERBI_BLUE_REPORT_ID;
        break;
      case 'SILVER':
        return process.env.POWERBI_SILVER_REPORT_ID;
        break;
      case 'GOLD':
        return process.env.POWERBI_GOLD_REPORT_ID;
        break;
      default:
        return "";
    }
  }

  async getToken(): Promise<void> {
    if (this.token=='' || new Date().getTime() >= this.tokenExpiry) {
      this.token = await this.authenticate();
    }
    if (this.token=='') {
      //wait for 30 seconds and try again
      await new Promise(resolve => setTimeout(resolve, 30000));
      await this.getToken();
    }
  }

  async authenticate(): Promise<string> {
      const tokenUrl = `https://login.microsoftonline.com/${this.tenantId}/oauth2/v2.0/token`;
      
      const data = new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: this.clientId,
        client_secret: this.clientSecret,
        scope: 'https://analysis.windows.net/powerbi/api/.default',
      });
    
      try {
        const response = await fetch(tokenUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
          body: data.toString(), 
        });

        if (!response.ok) {
          console.error(`Authentication failed: ${response.statusText}`);
          return '';
        }

        const authResponse = await response.json();
        this.tokenExpiry = new Date().getTime() + authResponse.expires_in * 1000;
        return authResponse.access_token;
      } catch (error) {
        console.error('Error authenticating:', error);
        return '';
      }
  }

  async powerBIReportRequest(submissionId: string, reportId: string, companyName: string): Promise<void> {
    const exportUrl = `https://api.powerbi.com/v1.0/myorg/groups/${this.groupId}/reports/${reportId}/ExportTo`; 
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.token}`,
    };
    let body = {};
    if(reportId == process.env.POWERBI_BLUE_REPORT_ID) { // Blue Report filter based on submissionId
      body = {
        'format': 'PDF',
        'powerBIReportConfiguration': {
          'reportLevelFilters': [
              {'filter': `SubmissionDetails/submissionId eq '${submissionId}'`} 
          ]
        }
      };
    }
    else if(reportId == process.env.POWERBI_SILVER_REPORT_ID) { // Silver Report filter based on companyName
      body = {
        'format': 'PDF',
        'powerBIReportConfiguration': {
          'reportLevelFilters': [
              {'filter': `'[Silver Output]'/Company eq '${companyName}'`} 
          ]
        }
      };
    }

    try {
      const response = await fetch(exportUrl, {
        method: 'POST',
        headers: headers,
        body: JSON.stringify(body),
      });

      if (!response.ok) {
        console.error('powerBIReportRequest1', response.statusText);
        await this.powerBIReportError(submissionId, response);
      }
      else {
        const result = await response.json();
        if(result.id) { // ExportId for the report request
          await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_Requested]",
            [
              { name: "submissionId", type: mssql.TYPES.NVarChar, value: submissionId }, 
              { name: "exportId", type: mssql.TYPES.NVarChar, value: result.id } 
            ]
          );
        }
      }
    } catch (error) {
      console.error('powerBIReportRequest2', error);
      await this.powerBIReportError(submissionId, error);
    }
  }
  async powerBIReportStatus(exportId: string, submissionId: string, reportId: string): Promise<any> {
    const exportUrl = `https://api.powerbi.com/v1.0/myorg/groups/${this.groupId}/reports/${reportId}/exports/${exportId}`;
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.token}`,
    };

    try {
      const response = await fetch(exportUrl, {
        method: 'GET',
        headers: headers,
      });

      if (!response.ok) {
        console.error('powerBIReportStatus1', response.statusText);
        await this.powerBIReportError(submissionId, response);
        return null;
      }
      else {
        const result = await response.json();
        if (result.status == "Succeeded") 
        {
           const query = await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_Generated]",
              [
                { name: "submissionId", type: mssql.TYPES.NVarChar, value: submissionId }, 
                { name: "resourceLocation", type: mssql.TYPES.NVarChar, value: result.resourceLocation } 
              ]
            );
          return query.results;
        }
      }
    } catch (error) {
      console.error('powerBIReportStatus2', error);
      await this.powerBIReportError(submissionId, error);
      return null;
    }
  }


  async powerBIReportDownload(resourceLocation: string, submissionId: string, reportFileName: string): Promise<boolean> {
    const headers = {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${this.token}`,
    };

    try {
      const response = await fetch(resourceLocation, {
        method: 'GET',
        headers: headers,
      });

      if (!response.ok) {
        console.error('powerBIReportDownload1', response.statusText);
        await this.powerBIReportError(submissionId, response);
        return false;
      }
      else {
        const saved = await this.savePDF(Buffer.from(await response.arrayBuffer()), reportFileName);
        if(saved)
        {   
            await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_Downloaded]",
              [
                { name: "submissionId", type: mssql.TYPES.NVarChar, value: submissionId }
              ]
            );
          return true;
        }
        else
          return false;
      }
    } catch (error) {
      console.error('powerBIReportDownload2', error);
      await this.powerBIReportError(submissionId, error);
      return false;
    }
  }

  async powerBIReportUpload(customerId: number, powerBIExportId: number, submissionId: string, reportFileName: string): Promise<boolean> {

    try {

      const date = new Date();
      const request = {
          id: null,
          parentEntityId: powerBIExportId,
          parentEntityType: 'powerbi',
          customerId: customerId,
          container: 'powerbi-reports',
          blobName: 'powerbi_' + uuidv4(),
          title: reportFileName, // 'customecode_BAQ_23.01.2024.pdf',
          singleInstance: false,
          canEmbed: false,
          modifiedDate: date.getTime(), // 17123456468, //current datetime seconds
          mimeType: 'application/pdf'
      };
      
      const result = await this.documentsService.uploadLocalFile(reportFileName, request);

      if (result) {
        await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_Uploaded]",
              [
                { name: "submissionId", type: mssql.TYPES.NVarChar, value: submissionId },
                { name: "documentId", type: mssql.TYPES.NVarChar, value: result.id }
              ]
            );
      }
      
    } catch (error) {
      console.error('powerBIReportDownload2', error);
      await this.powerBIReportError(submissionId, error);
      return false;
    }
  }
  
  async powerBIReportEmail(emailTo: string, submissionId: string, documentId: number, productName: string): Promise<boolean> {
    try{
        let email = [];
        const configration = await this.databaseService.execute('[email].[spEmailConfigration_Select]',  [
            { name: "name", type: mssql.TYPES.NVarChar, value: 'Blue Report Emails' },
        ]);
        
        if (configration.results || configration.results.length > 0) {
            configration.results.map( (row) => {
                email = JSON.parse(row.recipient).To;
                //template = row.template;
            })
        }

        email.push(...emailTo.split(',').map(values => {
          return {
            emailAddress: values.trim(),
          }
        }));

        // Attach Report file to email is PENDING
        const queued = await this.emailService.queueEmailProcess("Blue Award Report", "PFA attached report", email, null, null, null, documentId);
        if(queued)
        { 
            await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_Completed]",
              [
                { name: "submissionId", type: mssql.TYPES.NVarChar, value: submissionId }
              ]
            );
          return true;
        }
        else
          return false;
      }
      catch(error){
        console.error('powerBIReportEmail', error);
        await this.powerBIReportError(submissionId, error);
        return false;
      }
  }

  async powerBIReportError(submissionId: string, errorObj: any): Promise<void> {
    try {
      await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_Error]",
        [
          { name: "submissionId", type: mssql.TYPES.NVarChar, value: submissionId },
          { name: "errorDetails", type: mssql.TYPES.NVarChar, value: errorObj.toString() }
        ]
      );
    } catch (error) {
      console.error('powerBIReportError', error);
    }
  }

  async savePDF(data: Buffer, filename: string): Promise<boolean> {
    try {
      fs.writeFileSync('./data/'+filename, data);
      return true;
    } catch (error) {
      console.error('savePDF', error);
      return false;
    }
  }

  // public async exportRequestQueue(productName: string, responses): Promise<number> {
  //   // Get all submissions from PowerBI Export Queue for given product
  //   try { 
  //         const query = await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_GetList]",
  //           [
  //             { name: "productName", type: mssql.TYPES.NVarChar, value: productName }, 
  //             { name: "status", type: mssql.TYPES.Int, value: 0 } // Pending to be requested status
  //           ]
  //         );
  //         const responses = query.results;
  //         if(responses.length==0) return 0;
  //         await this.getToken();
  //         //console.log(`Total submissions to process : ${responses.length}`)
  //         const reportId = this.getReportId(productName);
          
  //         for (let response of responses) {
  //           try {
  //             // Submit Export requests in first loop
  //             await this.powerBIReportRequest(response.submissionId, reportId); 
  //           }
  //           catch (error) {
  //             console.error('exportRequestQueue1', error);
  //           }
  //         }
  //         return responses.length;
  //   } catch (error) {
  //     console.error('exportRequestQueue2', error);
  //     return 0;
  //   }
  // }

  // public async exportStatusQueue(productName: string) {
  //   // Get all submissions from PowerBI Export Queue for given product
  //   try { 
  //         const query = await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_GetList]",
  //           [
  //             { name: "productName", type: mssql.TYPES.NVarChar, value: productName }, 
  //             { name: "status", type: mssql.TYPES.Int, value: 2 } // Requested status
  //           ]
  //         );
  //         const responses = query.results;
  //         if(responses.length==0) return;
  //         await this.getToken();
  //         const reportId = this.getReportId(productName);
          
  //         for (let response of responses) {
  //           try {
  //             // Get Export status in second loop, based on above export requests, if successful download report and do further actions
  //             const generated = await this.powerBIReportStatus(response.exportId, response.submissionId, reportId);
  //             if(generated) { // download report
  //               const downloaded = await this.powerBIReportDownload(generated[0].resourceLocation, response.submissionId, generated[0].reportPDFFileName);
  //               if(downloaded) { // email report
  //                 await this.powerBIReportEmail(generated[0].emailTo, response.submissionId, generated[0].reportPDFFileName);
  //               }
  //             }
  //           }
  //           catch (error) {
  //             console.error('exportStatusQueue1', error);
  //           }
  //         }
  //   } catch (error) {
  //     console.error('exportStatusQueue2', error);
  //   }
  // }

  // public async exportDownloadQueue(productName: string) {
  //   // Get all submissions from PowerBI Export Queue for given product
  //   try { 
  //         const query = await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_GetList]",
  //           [
  //             { name: "productName", type: mssql.TYPES.NVarChar, value: productName }, 
  //             { name: "status", type: mssql.TYPES.Int, value: 3 } // Generated status
  //           ]
  //         );
  //         const responses = query.results;
  //         if(responses.length==0) return;
  //         await this.getToken();
  //         for (let response of responses) {
  //           try {
  //             // Get Export status in second loop, based on above export requests, if successful download report and do further actions
  //             const downloaded = await this.powerBIReportDownload(response.resourceLocation, response.submissionId, response.reportPDFFileName);
  //             if(downloaded) { // email report
  //               await this.powerBIReportEmail(response.emailTo, response.submissionId, response.reportPDFFileName);
  //             }
  //           }
  //           catch (error) {
  //             console.error('exportDownloadQueue1', error);
  //           }
  //         }
  //   } catch (error) {
  //     console.error('exportDownloadQueue2', error);
  //   }
  // }

  // public async exportEmailQueue(productName: string) {
  //   // Get all submissions from PowerBI Export Queue for given product
  //   try { 
  //         const query = await this.databaseService.execute("[PowerBI].[spPowerBIExportQueue_GetList]",
  //           [
  //             { name: "productName", type: mssql.TYPES.NVarChar, value: productName }, 
  //             { name: "status", type: mssql.TYPES.Int, value: 4 } // Downloaded status
  //           ]
  //         );
  //         const responses = query.results;

  //         for (let response of responses) {
  //           try {
  //             await this.powerBIReportEmail(response.emailTo, response.submissionId, response.reportPDFFileName);
  //           }
  //           catch (error) {
  //             console.error('exportEmailQueue1', error);
  //           }
  //         }
  //   } catch (error) {
  //     console.error('exportEmailQueue2', error);
  //   }
  // }
}

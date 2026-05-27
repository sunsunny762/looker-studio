import { Injectable } from "@nestjs/common";
import { DatabaseService } from "../database";
import * as mssql from "mssql";
import { QuestionType, EmissionActivity } from "./model";
import { ReportingFrequency } from "./model/reporting-frequency";
import { ConversionInfo, ConversionOutput, Question, QuestionResponse } from "./model/question";
import { ClickUpService } from "../clickup/clickup.service";
import { ProcessingResponse } from "./model/response";
import { FormCategory } from "./model/form-category";
import { CustomFieldsConstants } from "../clickup/customfields-constants";
import { CustomFieldsConstantTypes } from "../clickup/customfields-constant-types";
import { ErrorLoggerService } from "../error-logger/error-logger.service";
import { el, th } from "date-fns/locale";
import { AwardConfig, AwardType, TaskResult } from "./interfaces/award.interface";
import e, { raw } from "express";
import { parse } from "path";
import { format } from "date-fns";
import { CompanyService } from "../api/company/company.service";
import { UserService } from "../api/user/user.service";
import { CertificationService } from "../api/certification/certification.service";
import { FirebaseUserService } from "../api/user/firebaseuser.service";

@Injectable()
export class NCZFormService { // For Portal, NCZ Forms
  constructor(private readonly databaseService: DatabaseService, private readonly clickupService: ClickUpService,
    private customFieldsConstants:CustomFieldsConstants, private readonly errorLoggerService: ErrorLoggerService,
    private readonly companyService: CompanyService,
    private readonly userService: UserService,
    private readonly certificationService: CertificationService,
    private readonly firebaseUserService: FirebaseUserService
  ) { }

  public async selectForms(): Promise<any> {
    const query = await this.databaseService.execute("[Forms].[spForm_SelectAll]", [
      { name: "extSourceId", type: mssql.TYPES.Int, value: 1 }
    ]);
    return query.results;
  }

  public async saveResponse(data: any) {
    //Jotform doesnt provide any auth options for webhooks. 
    //So, making sure that formId in request matches with our DB before storing data to our DB.
    const validRequest = await this._isValidRequest(data);
    if (!validRequest) {
      console.error('saveResponse', {'error':'Invalid request'});
      return 'Invalid request'
    }
    try{
      console.log(`Jotform SubmissionId: ${data.submissionID}, FormId: ${data.formID} Received`);
      
      const query = await this.databaseService.execute("[Forms].[spForm_SaveRawResponse]", [
        { name: "formID", type: mssql.TYPES.NVarChar, value: data.formID },
        { name: "submissionId", type: mssql.TYPES.NVarChar, value: data.submissionID },
        { name: "data", type: mssql.TYPES.NVarChar, value: data.rawRequest },
      ]
      );
      return query.results;
    }
    catch(e){
      console.error('saveResponse', e);
      return e;
    }
  }

  public async customerProfile(data: any) {
    const formId = data.formID;
    //TODO this should be driven by DB configuration.
    if (formId != '231773524072050') { //Jotform customer profile form's Id
      return 'Invalid request'
    }

    const jsonData = data.rawRequest;
    const rawData = typeof jsonData == "string" ? JSON.parse(jsonData) : jsonData;
    if (!rawData) {
      return 'No data in rawRequest';
    }
    const name = rawData['q18_typeA18'];
    const reference = rawData['q29_customerId'];
    const periodStart = rawData['q33_date'] ? new Date(`${rawData['q33_date']['year']}-${rawData['q33_date']['month']}-${rawData['q33_date']['day']}`) : undefined;
    const periodEnd = rawData['q34_periodEnd'] ? new Date(`${rawData['q34_periodEnd']['year']}-${rawData['q34_periodEnd']['month']}-${rawData['q34_periodEnd']['day']}`) : undefined;
    const headCount = rawData['q12_totalHeadcount'];
    const annualRevenue = rawData['q13_annualRevenue'];
    const industryType = rawData['q16_typeA16'] == 'Other' ? rawData['q17_other'] : rawData['q16_typeA16'];
    const locations_JSON = rawData['q5_typeA'];

    const query = await this.databaseService.execute("[Dimension].[spCustomer_SaveProfile]", [
      { name: "name", type: mssql.TYPES.NVarChar, value: name },
      { name: "reference", type: mssql.TYPES.NVarChar, value: reference },
      { name: "periodStart", type: mssql.TYPES.DateTime, value: periodStart },
      { name: "periodEnd", type: mssql.TYPES.DateTime, value: periodEnd },
      { name: "headCount", type: mssql.TYPES.Int, value: headCount },
      { name: "annualRevenue", type: mssql.TYPES.NVarChar, value: annualRevenue },
      { name: "industryType", type: mssql.TYPES.NVarChar, value: industryType },
      { name: "locations_JSON", type: mssql.TYPES.NVarChar, value: locations_JSON },
    ]
    );
    return query.results;
  }

  public async events(data: any) {
    const formId = data.formID;
    if (formId != '232771160158858') { //Jotform Events forms
      return 'Invalid request'
    }
    const submissionID = data.submissionID;

    const jsonData = data.rawRequest;
    const rawData = typeof jsonData == "string" ? JSON.parse(jsonData) : jsonData;
    if (!rawData) {
      return 'No data in rawRequest';
    }
    const title = rawData['q8_title'];
    const type = rawData['q110_type'];
    const organiserName = rawData['q3_yourName'] ? `${rawData['q3_yourName']?.first} ${rawData['q3_yourName']?.last}` : '';
    const organiserEmail = rawData['q4_email'];
    const companyName = rawData['q21_companyName'];
    const objEventStartDate = rawData['q80_eventDate'] ? rawData['q80_eventDate'] : undefined;
    const objEventEndDate = rawData['q118_eventFinish'] ? rawData['q118_eventFinish'] : undefined;
    const startDateTime = objEventStartDate ? new Date(`${objEventStartDate?.year}-${objEventStartDate?.month}-${objEventStartDate?.day} ${objEventStartDate?.timeInput}`) : '';
    const endDateTime = objEventEndDate ? new Date(`${objEventEndDate?.year}-${objEventEndDate?.month}-${objEventEndDate?.day} ${objEventEndDate?.timeInput}`) : '';
    const location = rawData['q120_eventLocation'];
    const locationType = rawData['q97_locationType'];
    const noOfAttendees = rawData['q98_numberOf'];

    const query = await this.databaseService.execute("[Dimension].[spEvent_Save]", [
      { name: "title", type: mssql.TYPES.NVarChar, value: title },
      { name: "reference", type: mssql.TYPES.NVarChar, value: submissionID },
      { name: "type", type: mssql.TYPES.NVarChar, value: type },
      { name: "organiserName", type: mssql.TYPES.NVarChar, value: organiserName },
      { name: "organiserEmail", type: mssql.TYPES.NVarChar, value: organiserEmail },
      { name: "companyName", type: mssql.TYPES.NVarChar, value: companyName },
      { name: "startDateTime", type: mssql.TYPES.DateTime, value: startDateTime },
      { name: "endDateTime", type: mssql.TYPES.DateTime, value: endDateTime },
      { name: "location", type: mssql.TYPES.NVarChar, value: location },
      { name: "locationType", type: mssql.TYPES.NVarChar, value: locationType },
      { name: "noOfAttendees", type: mssql.TYPES.Int, value: noOfAttendees },
    ]
    );
    return query.results;
  }


  public async processSubmissions(): Promise<void> {
    // NCZ Form submissions made through Portal, (Blue Award is not included in this function)
    try { 
      const query = await this.databaseService.execute(process.env.NCZFORM_PROCESS_LOCAL_SP || "[portal].[spSubmission_SelectToProcess]");
      const submissions = query.results;

      console.log(`Total NCZForm submissions to process : ${submissions.length}`)
      let processResult: ProcessingResponse = ProcessingResponse.unknown;
      for (let submission of submissions) {
        try {
          this.errorLoggerService.setFormSubmissionIds(String(submission.formId), String(submission.submissionId));
          
          console.log(`Processing NCZForm SubmissionId: ${submission.submissionId}`);

          //TODO: GET data from portal.FormSubmissionResponses where id = response.submissionId
          if (submission.categoryId == FormCategory.BlueAwardQuestionnaire && submission.progId == 1) {
            processResult = await this.processBlueAwardForm(submission);
          }
          else if (submission.categoryId == FormCategory.BlueAwardQuestionnaire && submission.progId == 2) {
            processResult = await this.processSilverAwardForm(submission);
          }
          else if (submission.categoryId == FormCategory.GoldAwardQuestionnaire) {
            processResult = await this.processGoldAwardForm(submission);
          }
          else { // Other NCZ Forms
            processResult = await this.processSubmission(submission);
          }
        }
        catch (e) {
          console.error("processNCZFormSubmissions 1",e);
        }
        finally {
          // Mark as processed so won't be picked again
          //if (processResult !== ProcessingResponse.entity_not_found) {
          if(processResult == ProcessingResponse.success) {
            try{
              await this._markProcessed(submission.submissionId);
            }
            catch (e) {
              console.error("processNCZFormSubmissions 2", e);
            }
          }
        }
      }
      this.errorLoggerService.setFormSubmissionIds(null, null);
    } catch (e) {
      console.error("processNCZFormSubmissions 3",e);
    }
  }

  private removeBeforeBAQ(str) {
    const baqIndex = str.indexOf('BAQ');
    if (baqIndex !== -1) {
      return str.substring(baqIndex);
    }
    return str; // Return the original string if 'BAQ' is not found
  }

  private processBlueAwardJson(key, obj) {
    if (key.indexOf('BAQ_ReportStartDate') > -1) {
      let data = obj[key];
      // Handle ISO date string format "2026-01-30T18:30:00.000Z" (with or without quotes)
      // Convert to UTC midnight of the local date
      if (typeof data === 'string' && data.length > 0) {
        // Remove quotes if present
        data = data.replace(/"/g, '');
        // Parse the UTC datetime and convert to local date
        const utcDate = new Date(data);
        // Get the local date components (this accounts for timezone offset)
        const localYear = utcDate.getFullYear();
        const localMonth = utcDate.getMonth();
        const localDay = utcDate.getDate();
        // Create a new Date object at UTC midnight for the local date
        obj[key] = new Date(Date.UTC(localYear, localMonth, localDay, 0, 0, 0, 0));
      }
    }
    else if (key.indexOf('BAQ_WorkingDaysAndCommuting') > -1) {
      let data = typeof obj[key] === 'string' ? JSON.parse(obj[key]) : obj[key];
      if (data && data.length > 0) {
        const dataUnits = obj['BAQ_DataUnit']?.toLowerCase().trim(); // Km or Miles
        const conversionFactor = dataUnits === 'miles (m)' ? 1.60934 : 1;
        
        // Find each row by rowLabel
        const workedRow = data.find(row => row.rowLabel === 'AvgDaysPerWeekWorked');
        const commutingRow = data.find(row => row.rowLabel === 'AvgDaysPerWeekCommuting');
        const distanceRow = data.find(row => row.rowLabel === 'AvgDistance');
        
        if (workedRow) {
          obj['BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office'] = workedRow.officeWfhStaff;
          obj['BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Other'] = workedRow.otherStaff;
        }
        if (commutingRow) {
          obj['BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Office'] = commutingRow.officeWfhStaff;
          obj['BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Other'] = commutingRow.otherStaff;
        }
        if (distanceRow) {
          obj['BAQ_WorkingDaysAndCommuting_AvgDistance_Office'] = distanceRow.officeWfhStaff * conversionFactor;
          obj['BAQ_WorkingDaysAndCommuting_AvgDistance_Other'] = distanceRow.otherStaff * conversionFactor;
        }
        delete obj[key];
      }
    }
    else if (key.indexOf('BAQ_CompanyVehiclesMileage') > -1) {
      let data = typeof obj[key] === 'string' ? JSON.parse(obj[key]) : obj[key];
      if (data && data.length > 0) {
        const dataUnits = obj['BAQ_DataUnit']?.toLowerCase().trim(); // Km or Miles
        const conversionFactor = dataUnits === 'miles (m)' ? 1.60934 : 1;
        for (let index = 0; index < data.length; index++) {
          const vehicleType = data[index]['vehicleType'];
          obj[`BAQ_CompanyVehiclesMileage_${vehicleType}`] = data[index]['totalDistance'] * conversionFactor;
        }
      }
      delete obj[key];
    }
    else if (key.indexOf('BAQ_BusinessTravel') > -1) {
      let data = typeof obj[key] === 'string' ? JSON.parse(obj[key]) : obj[key];
      if (data && data.length > 0) {
        for (let index = 0; index < data.length; index++) {
          const travelType = data[index]['travelType'];
          const frequency = data[index]['frequency'];
          obj[`BAQ_BusinessTravel_${travelType}_${frequency}`] = data[index]['numberOfStaff'];
        }
      }
      delete obj[key];
    }
    else if (key.indexOf('BAQ_GoodsReceived') > -1) {
      let data = typeof obj[key] === 'string' ? JSON.parse(obj[key]) : obj[key];
      if (data && data.length > 0) {
        for (let index = 0; index < data.length; index++) {
          const distance = data[index]['distance'];
          const frequency = data[index]['frequency'];
          obj[`BAQ_GoodsReceived_${distance}_${frequency}`] = data[index]['avgWeight'];
        }
      }
      delete obj[key];
    }
    else if (key.indexOf('BAQ_GoodsSent') > -1) {
      let data = typeof obj[key] === 'string' ? JSON.parse(obj[key]) : obj[key];
      if (data && data.length > 0) {
        for (let index = 0; index < data.length; index++) {
          const distance = data[index]['distance'];
          const frequency = data[index]['frequency'];
          obj[`BAQ_GoodsSent_${distance}_${frequency}`] = data[index]['avgWeight'];
        }
      }
      delete obj[key];
    }
    else if (key.indexOf('BAQ_Currency') > -1) {
      let data = typeof obj[key] === 'string' ? JSON.parse(obj[key]) : obj[key];
      obj['BAQ_Currency'] = data.value;
    }
    else if (key.indexOf('BAQ_CompanyCountry') > -1) {
      let data = typeof obj[key] === 'string' ? JSON.parse(obj[key]) : obj[key];
      obj['BAQ_CompanyCountry'] = data.value;
    }
    else if (key.indexOf('BAQ_CompanyLogo') > -1) {
      let data = typeof obj[key] === 'string' && obj[key].trim() !== "" ? JSON.parse(obj[key]) : obj[key];
      if (data.length > 0) {
        obj['BAQ_CompanyLogo'] = data[0];
      }
      else {
        obj['BAQ_CompanyLogo'] = null;
      }
    }
    // else {
    //   var newkey = this.removeBeforeBAQ(key);
    //   obj[newkey] = obj[key];
    //   delete obj[key];
    // }
  }

  // Recursive function to flatten the JSON object
  private flattenBlueAwardJSON(obj) {
    for (let key in obj) {
      if (obj.hasOwnProperty(key)) {
        this.processBlueAwardJson(key, obj);
      }
    }
    return obj;
  }

  private async _isValidRequest(data: any) {
    const query = await this.databaseService.execute("[Forms].[spForm_SelectByExternalId]", [
      { name: "formId", type: mssql.TYPES.NVarChar, value: data.formID },
    ]
    );
    const result = query.singleResult;
    return result?.id > 0 ? true : false;
  }

  private async _insertIntoAudit(id: any, message: any) {
    throw new Error("Method not implemented.");
  }

  private async _markProcessed(submissionId: any) {
    const query = await this.databaseService.execute("[portal].[spSubmission_MarkProcessed]", [
      { name: "submissionId", type: mssql.TYPES.Int, value: submissionId }
    ]);
    return query.results;
  }

  private async _getFormResponses(submissionId: number): Promise<any> {
    const query = await this.databaseService.execute("portal.spFormSubmission_GetResponses", [
      { name: "submissionId", type: mssql.TYPES.Int, value: submissionId }
    ]);
    return query.results;
  }

  private async _getFormQuestions(formId: number): Promise<any> {
    const query = await this.databaseService.execute("[Forms].[spForm_SelectQuestions]", [
      { name: "formId", type: mssql.TYPES.Int, value: formId }
    ]);
    return query.results;
  }

  private async _saveResponseData(submissionId: number, responseData: string): Promise<any> {
    const query = await this.databaseService.execute("[Forms].[spForm_SaveResponseData]", [
      { name: "submissionId", type: mssql.TYPES.Int, value: submissionId },
      { name: "responseData", type: mssql.TYPES.NVarChar, value: responseData },
    ]);
    return query.results;
  }

  public async processBlueAwardForm(submission: any) {
    try { 
      const dimFormId = submission.dimFormId;
      const entityTypeId = submission.entityTypeId;
      const entityId = submission.companyId; 
      const submissionId = submission.submissionId;

      const responses: QuestionResponse[] = await this._getFormResponses(submissionId);
      if (!responses || responses.length == 0) {
        console.log('No responses found for submissionId: ' + submissionId);
        return ProcessingResponse.unknown;
      }

      const dimSubmissionId = await this._saveDimensionSubmission(submissionId, entityId, entityTypeId, dimFormId, 0, 1);
      if (!dimSubmissionId) {
        return ProcessingResponse.submission_not_saved;;
      }

      // Build object from responses for processing
      let jsonObj = {};
      responses.forEach((response) => {
        jsonObj[response.questionKey] = response.responseData;
      });

      // Process the JSON object through processBlueAwardJson to handle special fields
      jsonObj = this.flattenBlueAwardJSON(jsonObj);

      // Build array for database insertion from processed object
      let arrBlueAwardFormsArr = [];
      for (let key in jsonObj) {
        if (jsonObj.hasOwnProperty(key)) {
          let arrBlueAwardForms = {};
          arrBlueAwardForms['key'] = key;
          arrBlueAwardForms['value'] = jsonObj[key];
          arrBlueAwardForms['submissionId'] = submissionId;
          arrBlueAwardForms['dataType'] = typeof jsonObj[key];
          arrBlueAwardForms['dimSubmissionId'] = dimSubmissionId;
          arrBlueAwardFormsArr.push(arrBlueAwardForms);
        }
      }

      await this._processItemsInBatches(arrBlueAwardFormsArr, 50, this.addBlueAwardQuestionnaire.bind(this));

      // Step 1: Create ClickUp tasks first (if enabled) to get task IDs
      let clickupTaskIds = {
        companyTaskId: '',
        personTaskId: '',
        certTaskId: ''
      };
      // Certification refNumber generate
      //const refNumber = await this._getBAQNextReferenceNumber(submissionId);

      if(process.env.CLICKUP_CREATE_BAQTASK == "1") {
        const buildDate = Date.now();

        // Extract data from jsonObj
        const companyTaskData = {
            BAQ_CompanyName: jsonObj['BAQ_CompanyName'] || '',
            BAQ_CompanyDescription: jsonObj['BAQ_CompanyDescription'] || '',
            BAQ_CompanyIndustry: jsonObj['BAQ_CompanyIndustry'] || '',
            BAQ_CompanyWebsite: jsonObj['BAQ_CompanyWebsite'] || '',
            BAQ_Phone: jsonObj['BAQ_Phone'] || '',
            BAQ_CompanyRevenue: jsonObj['BAQ_CompanyRevenue'] || ''
        };

        // 1. Create Company Task
        const companyTaskResponse = await this._createCompanyTask(
            'Company',
            companyTaskData,
            buildDate
        );

        if (companyTaskResponse?.id) {
            clickupTaskIds.companyTaskId = companyTaskResponse.id;
            //console.log(`ClickUp Company Task created: ${clickupTaskIds.companyTaskId}`);
        } else {
            console.error('Failed to create company task');
        }

        // 2. Create Person Task
        const personTaskData = {
            BAQ_YourName: jsonObj['BAQ_YourName'] || '',
            BAQ_Email: jsonObj['BAQ_Email'] || '',
            BAQ_Phone: jsonObj['BAQ_Phone'] || '',
            BAQ_CompanyName: jsonObj['BAQ_CompanyName'] || '',
            BAQ_JobTitle: jsonObj['BAQ_JobTitle'] || '',
        };
        const personTaskResponse = await this._createPersonTask(
            'People',
            personTaskData,
            clickupTaskIds.companyTaskId,
            buildDate
        );

        if (personTaskResponse?.id) {
            clickupTaskIds.personTaskId = personTaskResponse.id;
            //console.log(`ClickUp Person Task created: ${clickupTaskIds.personTaskId}`);
        } else {
            console.error('Failed to create person task');
        }

        // 3. create Certification Task
        const resClickupTask = await this._createPortalCertificationTask(
            1, // Blue Award
            jsonObj['BAQ_CompanyName'] || '',
            '', // refNumber,
            jsonObj['BAQ_Phone'] || '',
            jsonObj['BAQ_Email'] || '',
            jsonObj['BAQ_YourName'] || '',
            jsonObj['BAQ_JobTitle'] || '',
            buildDate,
            dimFormId, dimSubmissionId, jsonObj['BAQ_source']
        );

        if (resClickupTask.success && resClickupTask.data?.id) {
            clickupTaskIds.certTaskId = resClickupTask.data.id;
            //console.log(`ClickUp Certification Task created: ${clickupTaskIds.certTaskId}`);
        } else {
            console.error('Failed to create certification task:', resClickupTask.message);
        }

        // Create task relationships if all tasks were successfully created
        if (clickupTaskIds.companyTaskId && clickupTaskIds.personTaskId && clickupTaskIds.certTaskId) {
          try {
            const taskResult: TaskResult = {
              companyTaskId: clickupTaskIds.companyTaskId,
              personTaskId: clickupTaskIds.personTaskId,
              certTaskId: clickupTaskIds.certTaskId,
              certTaskCreated: true,
              tasks: []
            };

            await this.createRelationships(taskResult, jsonObj);
            //console.log('Successfully created task relationships');
          } catch (e) {
            console.error('Failed to create task relationships:', e);
          }
        }

      } else {
        console.log('processBlueAwardForm', 'CLICKUP_CREATE_BAQTASK is not enabled');
      }

      // // Step 2: Create company, user, and certification records with ClickUp task IDs
      // const creationResult = await this._createCompanyCertificationAndUser(
      //   jsonObj,
      //   submissionId,
      //   submission.progId,
      //   dimSubmissionId,
      //   clickupTaskIds
      // );

      // if (!creationResult.success) {
      //   console.error('Failed to create company, user, or certification:', creationResult.error);
      //   return ProcessingResponse.error;
      // }

      return ProcessingResponse.success;

    } catch (e) {
      console.error('processBlueAwardForm', e);
      return ProcessingResponse.error;
    }
  }

  public async processSilverAwardForm(submission: any) {
    try { // Blue submission will not come through, there will be different process for it
      const dimFormId = submission.dimFormId;
      const entityTypeId = submission.entityTypeId;
      const entityId = submission.companyId; // Portal company id
      const submissionId = submission.submissionId;

      const responses: QuestionResponse[] = await this._getFormResponses(submissionId);
      if (!responses || responses.length == 0) {
        console.log('No responses found for submissionId: ' + submissionId);
        return ProcessingResponse.unknown;
      }

      const dimSubmissionId = await this._saveDimensionSubmission(submissionId, entityId, entityTypeId, dimFormId, 0, 1);
      if (!dimSubmissionId) {
        return ProcessingResponse.submission_not_saved;;
      }

      // Build object from responses for processing
      let jsonObj = {};
      responses.forEach((response) => {
        jsonObj[response.questionKey] = response.responseData;
      });

      // Process the JSON object through processBlueAwardJson to handle special fields
      jsonObj = this.flattenBlueAwardJSON(jsonObj);

      let arrSilverAwardFormsArr = [];
      for (let key in jsonObj) {
        if (jsonObj.hasOwnProperty(key)) {
          let arrSilverAwardForms = {};
          arrSilverAwardForms['key'] = key;
          arrSilverAwardForms['value'] = jsonObj[key];
          arrSilverAwardForms['submissionId'] = submissionId;
          arrSilverAwardForms['dataType'] = typeof jsonObj[key];
          arrSilverAwardForms['dimSubmissionId'] = dimSubmissionId;
          arrSilverAwardFormsArr.push(arrSilverAwardForms);
        }
      }

      await this._processItemsInBatches(arrSilverAwardFormsArr, 50, this.addBlueAwardQuestionnaire.bind(this));
      return ProcessingResponse.success;

    } catch (e) {
      console.error('processSilverAwardForm', e);
      return ProcessingResponse.error;
    }
  }

  public async processGoldAwardForm(submission: any) {
    try { // Gold Form will be submitted through Gold and Platinum certification
      const dimFormId = submission.dimFormId;
      const entityTypeId = submission.entityTypeId;
      const entityId = submission.companyId; // Portal company id
      const submissionId = submission.submissionId;

      const responses: QuestionResponse[] = await this._getFormResponses(submissionId);
      if (!responses || responses.length == 0) {
        console.log('No responses found for submissionId: ' + submissionId);
        return ProcessingResponse.unknown;
      }

      const dimSubmissionId = await this._saveDimensionSubmission(submissionId, entityId, entityTypeId, dimFormId, 0, 1);
      if (!dimSubmissionId) {
        return ProcessingResponse.submission_not_saved;;
      }

      // Build object from responses for processing
      let jsonObj = {};
      responses.forEach((response) => {
        jsonObj[response.questionKey] = response.responseData;
      });

      // Process the JSON object through processBlueAwardJson to handle special fields
      jsonObj = this.flattenBlueAwardJSON(jsonObj);
      
      let arrGoldAwardFormsArr = [];
      for (let key in jsonObj) {
        let arrGoldAwardForms = {};
        arrGoldAwardForms['key'] = key;
        arrGoldAwardForms['value'] = jsonObj[key];
        arrGoldAwardForms['submissionId'] = submissionId;
        arrGoldAwardForms['dataType'] = typeof jsonObj[key];
        arrGoldAwardForms['dimSubmissionId'] = dimSubmissionId;
        arrGoldAwardFormsArr.push(arrGoldAwardForms);
      }

      await this._processItemsInBatches(arrGoldAwardFormsArr, 50, this.addGoldAwardQuestionnaire.bind(this));

      return ProcessingResponse.success;
    } catch (e) {
      console.error('processGoldAwardForm', e);
      return ProcessingResponse.error;
    }
  }

  private async _createPersonTask(listName: string, jsonObj: any, submissionId: string, buildDate: any)
  {
    try { 
        const nameParts = jsonObj.BAQ_YourName.trim().split(" ");
        const lastName = nameParts.length > 1 ? nameParts[nameParts.length - 1] : "";
        const firstName = jsonObj.BAQ_YourName.replace(lastName, "").trim();

        const personCF = [
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Last Contacted Date"), 
            value: buildDate
          },
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Product"), 
            value: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.Product, "Blue Award")??"Blue Award",
          },
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Email"),
            value: jsonObj.BAQ_Email
          },
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Mobile/Phone Number"),
            value: jsonObj.BAQ_Phone?.area? (jsonObj.BAQ_Phone.area + " " + jsonObj.BAQ_Phone.phone).trim() : jsonObj.BAQ_Phone
          },
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Company Name"),
            value: jsonObj.BAQ_CompanyName
          },
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"First Name"),
            value: firstName
          },
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Surname"),
            value: lastName
          },
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Contact Title"),
            value: jsonObj.BAQ_JobTitle
          },
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Created by API"),
            value: '1'
          },
        ];
        const personTaskResponse = await this.clickupService.createTaskCF(jsonObj.BAQ_YourName, submissionId, 'ACTIVE CUSTOMER', personCF, 
            parseInt(this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.ListId, listName)));
        
        if(!personTaskResponse?.id)
          console.error('_createPersonTask', personTaskResponse);

        return personTaskResponse;

      } catch (e) {
        console.error('_createPersonTask', e)
        return ProcessingResponse.error;
    }
  }
  private async _createCompanyTask(listName: string, jsonObj: any, buildDate: any)
  {
    try {
      let companyCF = [
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Contract Start"), 
          value: buildDate
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Industry"), 
          value: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.Industry, jsonObj.BAQ_CompanyIndustry)??"",// jsonObj.BAQ_CompanyIndustry,
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Company Revenue"),
          value: jsonObj.BAQ_CompanyRevenue
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Website"),
          value: jsonObj.BAQ_CompanyWebsite
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Mobile/Phone Number"),
          value: jsonObj.BAQ_Phone?.area? (jsonObj.BAQ_Phone.area + " " + jsonObj.BAQ_Phone.phone).trim() : jsonObj.BAQ_Phone
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Created by API"),
          value: '1'
        },
      ];
      const companyTaskResponse = await this.clickupService.createTaskCF(jsonObj.BAQ_CompanyName, jsonObj.BAQ_CompanyDescription??'', 'ACTIVE', companyCF, 
        parseInt(this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.ListId, listName)));
      
      if(!companyTaskResponse?.id)
        console.error('_createCompanyTask', companyTaskResponse);

      return companyTaskResponse;
    } catch (e) {
      console.error('_createCompanyTask', e)
      return ProcessingResponse.error;
    }
  }
  private async _createCertificationTask(listName: string, productName: string, status: string, jsonObj: any, submissionId: string, jotFormId: string, buildDate: any)
  {
    try {
      const certCF = [
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Contract Start"), 
          value: buildDate
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Product"), 
          value: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.Product, productName??"Blue Award"),
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Email"),
          value: jsonObj.BAQ_Email
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Mobile/Phone Number"),
          value: jsonObj.BAQ_Phone?.area? (jsonObj.BAQ_Phone.area + " " + jsonObj.BAQ_Phone.phone).trim() : jsonObj.BAQ_Phone
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Contact"),
          value: jsonObj.BAQ_YourName
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"formId"),
          value: jotFormId
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"submissionId"),
          value: submissionId
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"BAQ uniqueId"),
          value: jsonObj.BAQ_uniqueId
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Created by API"),
          value: '1'
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Calendar link"),
          value: 'https://calendly.com/zac-neutralcarbonzone'
        },
      ];
      const certTaskResponse = await this.clickupService.createTaskCF(jsonObj.BAQ_CompanyName, "SubmissionID: " + submissionId +" ", status, certCF, 
        parseInt(this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.ListId, listName)));

      if(!certTaskResponse?.id)
        console.error('_createCertificationTask', certTaskResponse);

      return certTaskResponse;
    } catch (e) {
      console.error('_createCertificationTask', e)
      return ProcessingResponse.error;
    }
  }
  public async _createPortalCertificationTask(progId: number, companyName: string, refNumber: string,
    phone: string, email: string, contactName: string, contactTitle: string, contractStartDate: any,
    formId?: number, submissionId?: number, source?: string)
  { // Certification Task to be created when Certification record is created.
    // Later update SubmissionID, FormID etc details on Company profile submission processing
    let awardType;
    switch(progId) {
      case 1:
        awardType = AwardType.RJM;
        break;
      case 2:
        awardType = AwardType.APP_SILVER;
        break;
      case 3:
        awardType = AwardType.APP_GOLD;
        break;
      case 4:
        awardType = AwardType.APP_PLATINUM;
        break;
      default:
        awardType = AwardType.DEFAULT;
        break;
    }
    const awardConfig = this.getAwardConfig( awardType );
    try {
      const certCF = [
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Contract Start"), 
          value: contractStartDate
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Product"), 
          value: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.Product, awardConfig.productName)??"Blue Award",
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Email"),
          value: email
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Mobile/Phone Number"),
          value: phone
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Contact"),
          value: contactName
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Contact Title"),
          value: contactTitle
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Created by API"),
          value: '1'
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Calendar link"),
          value: 'https://calendly.com/zac-neutralcarbonzone'
        },
      ];
      if (awardType === AwardType.RJM) {
        certCF.push(
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"formId"),
            value: formId ? formId.toString() : ''
          },
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"submissionId"),
            value: submissionId ? submissionId.toString() : ''
          },
          { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Blue Lead Source"),
            value: source ?? '' // used to get the source of the submission
          }
        );
      }
      const certTaskResponse = await this.clickupService.createTaskCF(`${companyName} ${Boolean(refNumber)? `(${refNumber})`:''}`, "", awardConfig.statusName, certCF, 
        parseInt(this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.ListId, awardConfig.listName)));

      if (!certTaskResponse?.id) {
        console.error('_createBlankCertificationTask', certTaskResponse);
        return { success: false, message: 'Unable to create certification task', data: certTaskResponse };
      }
      else {
        await this.clickupService.processTasksDirectToDB([certTaskResponse]);
        return { success: true, message: 'Certification task created successfully', data: certTaskResponse };
      }
    } catch (e) {
      console.error('_createBlankCertificationTask', e)
      return { success: false, message: 'Unable to create certification task', data: e };
    }
  }

  /**
   * Creates company, user, and certification records from BAQ submission data
   * Implements rollback on error by logging and throwing exceptions
   * @param jsonObj - The flattened BAQ submission data
   * @param submissionId - The NCZForm submission ID
   * @param progId - The programme/certification type ID (1=Blue, 2=Silver, 3=Gold, 4=Platinum)
   * @param dimSubmissionId - The dimension submission ID
   * @param clickupTaskIds - Optional ClickUp task IDs to link to the records
   * @returns Object with success status, created IDs, and error details if any
   */
  private async _createCompanyCertificationAndUser(
    jsonObj: any,
    submissionId: string,
    progId: number,
    dimSubmissionId: number,
    clickupTaskIds?: { companyTaskId: string; personTaskId: string; certTaskId: string }
  ): Promise<any> {

    try {
      const result = await this.databaseService.execute("[portal].[spBlueAwardCompanyCertUser_Save]", [
        { name: "dimSubmissionId", type: mssql.TYPES.Int, value: dimSubmissionId },
        { name: "companyTaskId", type: mssql.TYPES.NVarChar, value: clickupTaskIds?.companyTaskId || null },
        { name: "personTaskId", type: mssql.TYPES.NVarChar, value: clickupTaskIds?.personTaskId || null },
        { name: "certificationTaskId", type: mssql.TYPES.NVarChar, value: clickupTaskIds?.certTaskId || null }
      ]);

      if (result.results && result.results.length > 0) {
        const record = result.results[0];

        // Check for ERROR status
        if (record.status === 'ERROR') {
          const errorDetails = {
            status: record.status,
            errorMsg: record.errorMsg,
            errorNumber: record.errorNumber,
            errorLine: record.errorLine,
            dimSubmissionId: dimSubmissionId,
            submissionId: submissionId
          };
          console.error('_createCompanyCertificationAndUser 1', errorDetails);
          return {
            success: false,
            error: record.errorMsg || 'Unknown error occurred'
          };
        }
        
        // Success case
        if (record.status === 'SUCCESS') {

          const userRecord = await this.firebaseUserService.createUser(record.email, 'TempP@ssw0rd', record.fullName);
          if (userRecord?.uid) {
              await this.userService.updateUserUID(record.userId, userRecord.uid);
              const verificationLink = await this.firebaseUserService.sendEmailVerification(record.email);
              this.userService.sendVerifyEmail(record.email, record.fullName, verificationLink);
          }

          return {
            success: true,
            companyId: record.companyId,
            userId: record.userId,
            certId: record.certId
          };
        }
      }

    } catch (error) {
      // Log error to database
      console.error('_createCompanyCertificationAndUser 2', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  public async processSubmission(submission: any) {
    try {
      const formId = submission.formId;
      const dimFormId = submission.dimFormId;
      const formName = submission.formName;
      const entityTypeId = submission.entityTypeId;
      //const jsonData = submission.data;
      const submissionId = submission.submissionId;
      //const data = typeof jsonData == "string" ? JSON.parse(jsonData) : jsonData;
      //const questions = await this._getFormQuestions(formId);
      //const certId = response.certId; // Portal certification id
      let entityId = submission.companyId; // Portal company id
      const certTaskId = submission.certTaskId; // Clickup certification task id
      const companyName = submission.companyName;
      const country = submission.country;
      const currency = submission.currency;
            
      // if (process.env.CLICKUP_CREATE_SUBTASK == '1') {
      //   //Create Subtask in clickup.
      //   const taskResponse = await this.clickupService.getTaskDetailsFromDB(certTaskId);
      //   if (taskResponse.success) { 
      //     const taskDetails = taskResponse.data[0];
      //     const response = await this.clickupService.createTask(formName, companyName, taskDetails.status, certTaskId, taskDetails.listId, formId, submissionId);
      //     if (!response?.id) {
      //       console.error('SubTask not created ', response);
      //       return 0;
      //     } else {
      //       await this.clickupService.processTasksDirectToDB([response]);
      //     }
      //   }
      // }

      const responses: QuestionResponse[] = await this._getFormResponses(submissionId);
      if (!responses || responses.length == 0) {
        console.log('No responses found for submissionId: ' + submissionId);
        return ProcessingResponse.unknown;
      }

      const isMBD = this._getMBD(responses);
      const optedIn = this._getOptedIn(responses);

      const dimSubmissionId = await this._saveDimensionSubmission(submissionId, entityId, entityTypeId, dimFormId, isMBD, optedIn);
      if (!dimSubmissionId) {
        return ProcessingResponse.submission_not_saved;;
      }

      if (optedIn == 1 && isMBD == 0) {
        //Set reporting frequency
        let reportingFrequency = this._getReportingFrequency(responses);
        let month = undefined;

        //Global Conversion Factor
        let conversionFactorG = this._getResponseDataByQuestionType(responses, QuestionType.conversionFactor);
        conversionFactorG = conversionFactorG ? conversionFactorG : 1;

        //Global Data Unit
        let dataUnitG = this._getResponseDataByQuestionType(responses, QuestionType.dataUnit);

        // For Electricity form
        const greenTariffPercent = this._getGreenTariffPercent(responses);

        //Process all activity Question responses
        const eaResponses: QuestionResponse[] = responses.filter((x: QuestionResponse) => x.emissionActivities);
        for (let response of eaResponses) {
          //console.log("Question: " + question.reference + " " + question.id+" "+question.displayText);

          let rawData = response.responseData && typeof response.responseData == 'string' ? JSON.parse(response.responseData) : response.responseData;
          // Check for null/undefined/zero length array/empty string/empty object
          if (this.isEmpty(rawData)) {
            continue;
          }

          //Properties can have dataUnit or conversion factor questions.
          const properties = response.properties ? JSON.parse(response.properties) : undefined;

          const emissionActivities = typeof response.emissionActivities == 'string' ? JSON.parse(response.emissionActivities) : response.emissionActivities;
          if (!emissionActivities) {
            console.log('No emission activity configured for questionId : ' + response.questionId)
            continue;
          }

          // Override Data Unit and Conversion Factor for a question
          let conversionFactor = conversionFactorG;
          let dataUnit = dataUnitG;
          let chargingPercentAtWorkPlace = null;

          if (properties){ // && properties.linkedQuestions) {
            dataUnit = this._getPropertyResponseDataByQuestionType(properties, responses, QuestionType.dataUnit);
            dataUnit = dataUnit ? dataUnit : dataUnitG;

            conversionFactor = this._getPropertyResponseDataByQuestionType(properties, responses, QuestionType.conversionFactor);
            conversionFactor = conversionFactor ? conversionFactor : conversionFactorG;

            chargingPercentAtWorkPlace = this._getPropertyResponseDataByQuestionType(properties, responses, QuestionType.chargingPercentAtWorkPlace);
          }

          // For Green Tariff percentage in Electricity, update conversion factor
          if (greenTariffPercent) {
            conversionFactor = this._getRemainingValue(conversionFactor, greenTariffPercent);
          }
          // For the conversion calculation, e.g. Amount to Litre of petrol/diesel, Amount to USD etc
          let conversionInfo: ConversionInfo = null;
          if (properties && properties.conversion) {
            conversionInfo = {
              conversionType: properties.conversion,
              country: country,
              currency: currency,
            }
          }

          if (response.questionTypeId == QuestionType.userInput_annul_by_month && reportingFrequency == ReportingFrequency.annualised_monthly) {
            for (let eA of emissionActivities) {
              if (properties.typeCol && eA.typeValue) { // if multiple types are there in same data table
                const filteredData = rawData.filter((r) => r[properties.typeCol] == eA.typeValue);
                if(filteredData.length > 0) 
                  await this._processAnnualSubmissionByMonths(response.questionId, filteredData, properties, entityId, entityTypeId, dimSubmissionId, eA.emissionActivityId, conversionFactor, reportingFrequency, dataUnit, conversionInfo, chargingPercentAtWorkPlace);
              }
              else { // single type data
                await this._processAnnualSubmissionByMonths(response.questionId, rawData, properties, entityId, entityTypeId, dimSubmissionId, eA.emissionActivityId, conversionFactor, reportingFrequency, dataUnit, conversionInfo, chargingPercentAtWorkPlace);
              }
            }
          }
          else if (response.questionTypeId == QuestionType.userInput_annual && reportingFrequency == ReportingFrequency.annualised) {
            for (let eA of emissionActivities) {
              let responseData: any = null;
              if (properties.typeCol && eA.typeValue) { // if multiple types are there in same data table
                const filteredData = rawData.filter((r) => r[properties.typeCol] == eA.typeValue);
                if (filteredData.length > 0) {
                  for (const element of filteredData) {
                    responseData = element[properties.dataCol];
                    await this._processSubmissionByAnnual(response.questionId, responseData, entityId, entityTypeId, dimSubmissionId, eA.emissionActivityId, month, conversionFactor, reportingFrequency, dataUnit, conversionInfo, chargingPercentAtWorkPlace);
                  }
                }
              }
              else { // single type data
                responseData = rawData[0][properties.dataCol];
                await this._processSubmissionByAnnual(response.questionId, responseData, entityId, entityTypeId, dimSubmissionId, eA.emissionActivityId, month, conversionFactor, reportingFrequency, dataUnit, conversionInfo, chargingPercentAtWorkPlace);
              }
            }
          }
          // } else if (question.questionTypeId == QuestionType.userInput_annual_JanToJun && reportingFrequency == ReportingFrequency.annualised_monthly) {
          //   for (let annualProp of emissionActivities) {
          //     const annualisedData = (Object.keys(rawData).length > annualProp.rowNo || rawData.length > annualProp.rowNo) ? rawData[annualProp.rowNo] : [];
          //     await this._processAnnualSubmissionByJanToJun(question.id, annualisedData, entityId, entityTypeId, dimSubmissionId, annualProp.emissionActivityId, conversionFactor, reportingFrequency, dataUnit, conversionInfo);
          //   }
          // } else if (question.questionTypeId == QuestionType.userInput_annual_JulToDec && reportingFrequency == ReportingFrequency.annualised_monthly) {
          //   for (let annualProp of emissionActivities) {
          //     const annualisedData = (Object.keys(rawData).length > annualProp.rowNo || rawData.length > annualProp.rowNo) ? rawData[annualProp.rowNo] : [];
          //     await this._processAnnualSubmissionByJulToDec(question.id, annualisedData, entityId, entityTypeId, dimSubmissionId, annualProp.emissionActivityId, conversionFactor, reportingFrequency, dataUnit, conversionInfo);
          //   }
          // } 
          else if (response.questionTypeId == QuestionType.userInput_textbox) {
            for (let eA of emissionActivities) {
              const userInput = rawData; // data[question.reference];
              await this._processSubmissionByAnnual(response.questionId, userInput, entityId, entityTypeId, dimSubmissionId, eA.emissionActivityId, month, conversionFactor, reportingFrequency, dataUnit, conversionInfo, chargingPercentAtWorkPlace);
            }
          } 
          else if (response.questionTypeId == QuestionType.deliveries_itemise_input) {
            const userInput = rawData;
            await this._processDeliveriesItemiseInput(response.questionId, userInput, entityId, entityTypeId, dimSubmissionId, emissionActivities, properties, conversionFactor, reportingFrequency, dataUnit, conversionInfo);
          }
          else if (response.questionTypeId == QuestionType.otherFuel_itemise_input) {
            const userInput = rawData;
            await this._processOtherFuelItemiseInput(response.questionId, userInput, entityId, entityTypeId, dimSubmissionId, emissionActivities, properties, conversionFactor, reportingFrequency);
          }
          else if (response.questionTypeId == QuestionType.hotelStay_itemise_input) {
            const userInput = rawData;
            await this._processHotelStayItemiseInput(response.questionId, userInput, entityId, entityTypeId, dimSubmissionId, emissionActivities, properties, month, conversionFactor, reportingFrequency, dataUnit);
          }
          else if(response.questionTypeId == QuestionType.flight_domestic_itemise_input) {
            const userInput = rawData;
            await this._processFlightDomesticItemiseInput(response.questionId, userInput, entityId, entityTypeId, dimSubmissionId, emissionActivities[0]?.emissionActivityId, conversionFactor, reportingFrequency, dataUnit);
          }
          else if (response.questionTypeId == QuestionType.flight_short_haul_itemise_input) {
            const userInput = rawData;
            await this._processFlightShortHaulItemiseInput(response.questionId, userInput, entityId, entityTypeId, dimSubmissionId, emissionActivities, properties, month, conversionFactor, reportingFrequency, dataUnit);
          }
          else if (response.questionTypeId == QuestionType.flight_long_haul_itemise_input) {
            const userInput = rawData;
            await this._processFlightLongHaulItemiseInput(response.questionId, userInput, entityId, entityTypeId, dimSubmissionId, emissionActivities, properties, month, conversionFactor, reportingFrequency, dataUnit);
          }
          else if (response.questionTypeId == QuestionType.flight_itemise_input) {
            const userInput = rawData;
            await this._processFlightItemiseInput(response.questionId, userInput, entityId, entityTypeId, dimSubmissionId, emissionActivities, properties, month, conversionFactor, reportingFrequency, dataUnit);
          }
        }
      }

      if (process.env.CLICKUP_CREATE_SUBTASK == '1' && (dimFormId != 11 && dimFormId != 26)) { // Don't create subtask for C&HW submissions
        //Create Subtask in clickup.
        const taskResponse = await this.clickupService.getTaskDetailsFromDB(certTaskId);
        if (taskResponse.success) { 
          const taskDetails = taskResponse.data[0];
          const response = await this.clickupService.createTask(formName, companyName, taskDetails.status, certTaskId, taskDetails.listId, formId.toString(), submissionId.toString());
          if (!response?.id) {
            console.error('SubTask not created ', response);
            return 0;
          } else {
            await this.clickupService.processTasksDirectToDB([response]);
          }
        }
      }

      return ProcessingResponse.success;

    } catch (e) {
      console.error('processResponse', e);
      return ProcessingResponse.error;
    }
  }

  private isEmpty = (value: any): boolean => {
      if (!value) return true;
      if (Array.isArray(value)) return value.length === 0;
      if (typeof value === 'string') return value.trim().length === 0;
      if (typeof value === 'object') return Object.keys(value).length === 0;
      return false;
  };

  private _getRemainingValue(inputValue: number, percentage: number): number {
    // remove % charged at work place from userInput
    return (inputValue * (100 - percentage)) / 100;
  }
  private async _convertTo(conversionInfo: ConversionInfo, inputValue: number): Promise<ConversionOutput>
  {
      if (conversionInfo.conversionType == 'AmountToLitre-Petrol' || conversionInfo.conversionType == 'AmountToLitre-Diesel') 
      {
        // X Convert Amount unit to its replacement unit. e.g. Amount Spend - Petrol to No of Litre - Petrol
        // set OutputValue of Amount 1 as conversionFactor for Amount Spend, keep inputValue as it is
        const query = await this.databaseService.execute("[Emissions].[spConvertAmountTo]", [
          { name: "conversionType", type: mssql.TYPES.NVarChar, value: conversionInfo.conversionType },
          { name: "amount", type: mssql.TYPES.Decimal, value: 1 }, // inputValue
          { name: "country", type: mssql.TYPES.NVarChar, value: conversionInfo.country },
          ]);
        const res = query.singleResult;
        if (res) { 
          if (res.outputValue && res.dataUnit) {
            return { outputValue: inputValue, conversionFactor: res.outputValue }; //{ outputValue: res.outputValue, dataUnit: res.dataUnit};
          }
        }
      }
      if (conversionInfo.conversionType == 'AmountToUSD') { 
        // set currency rate as conversionFactor for AmountToUSD, keep inputValue as it is
        const query = await this.databaseService.execute("[Emissions].[spConvertAmountTo]", [
          { name: "conversionType", type: mssql.TYPES.NVarChar, value: conversionInfo.conversionType },
          { name: "amount", type: mssql.TYPES.Decimal, value: 1 }, // inputValue
          { name: "currency", type: mssql.TYPES.NVarChar, value: conversionInfo.currency },
          ]); 
        const res = query.singleResult;
        if (res) { 
            return { outputValue: inputValue, conversionFactor: res.outputValue };
        }
      }

      return null;
  }

  private async _saveDimensionSubmission(submissionId: number, entityId: number, entityTypeId: number, formId: number,
                                isMBD: number, optedIn: number): Promise<number> {
    //Create submission record in Dimension.Submission table.
    const dimSubmissionId = await this._createSubmission(submissionId, isMBD, optedIn, entityId, entityTypeId, formId);
    if (!dimSubmissionId) {
      console.log('Submission record not created');
      return 0
    }
    return dimSubmissionId;
  }

  private _getReportingFrequency(responses: QuestionResponse[]) {
    let reportingFrequency = ReportingFrequency.unknown;
    let freqResponse: any = responses.find((x: QuestionResponse) => x.questionTypeId == QuestionType.reportingFrequency);
    if (freqResponse) {
      switch (freqResponse.responseData) {
        // case "2":
        //   reportingFrequency = ReportingFrequency.monthly;
        //   break;
        case "3":
        case "monthly":
          reportingFrequency = ReportingFrequency.annualised_monthly;
          break;
        case "4":
        case "annualised":
          reportingFrequency = ReportingFrequency.annualised;
          break;
      }
    }
    
    return reportingFrequency;
  }

  private _getMBD(responses: QuestionResponse[]) {
    let MBD = 0;
    let mbdResponse: any = responses.find((x: QuestionResponse) => x.questionTypeId == QuestionType.ManagementBasedDecision);
    if (mbdResponse) {
      MBD = parseInt(mbdResponse.responseData);
    }
    return MBD;
  }

  private _getOptedIn(responses: QuestionResponse[]) {
    let OptedIn = 1;
    let optResponse: any = responses.find((x: QuestionResponse) => x.questionTypeId == QuestionType.optInPreference);
    if (optResponse) {
      OptedIn = parseInt(optResponse.responseData);
    }
    return OptedIn;
  }

  private _getResponseDataByQuestionType(responses: QuestionResponse[], questionType: QuestionType) {
    let questionResponse: any = responses.find((x: QuestionResponse) => x.questionTypeId == questionType);
    
    return questionResponse ? questionResponse.responseData : null;
  }

  private _getPropertyResponseDataByQuestionType(properties: any, responses: QuestionResponse[], questionType: QuestionType) {
    
    if (questionType == QuestionType.dataUnit)
    {
      return properties.dataUnitValue ?? this._getResponseDataByQuestionKey(responses, properties.dataUnitKey);
    }
    if (questionType == QuestionType.conversionFactor)
    {
      return properties.conversionFactorValue ?? this._getResponseDataByQuestionKey(responses, properties.conversionFactorKey);
    }
    if (questionType == QuestionType.chargingPercentAtWorkPlace)
    {
      return properties.wpChargingValue ?? this._getResponseDataByQuestionKey(responses, properties.wpChargingKey);
    }

    let questionKey: string = this._getLinkedQuestionKeyByQuestionType(properties.linkedQuestions, questionType);
    if (!questionKey) return null;

     return this._getResponseDataByQuestionKey(responses, questionKey);
  }

  private _getLinkedQuestionResponseDataByQuestionType(linkedQuestions: any, responses: QuestionResponse[], questionType: QuestionType) {
     let questionKey: any = this._getLinkedQuestionKeyByQuestionType(linkedQuestions, questionType);
     if (!questionKey) return null;

     return this._getResponseDataByQuestionKey(responses, questionKey);
  }

  private _getLinkedQuestionKeyByQuestionType(linkedQuestions: any, questionType: QuestionType) {
    let question: any = linkedQuestions.find((x: any) => x.questionTypeId == questionType);
    
    return question ? question.reference : null;
  }
  private _getResponseDataByQuestionKey(responses: QuestionResponse[], questionKey: string) {
    let questionResponse: any = responses.find((x: QuestionResponse) => x.questionKey == questionKey);
    
    return questionResponse ? questionResponse.responseData : null;
  }

  private _getGreenTariffPercent(responses: QuestionResponse[]) {

    const hasGreenTarrif = this._getResponseDataByQuestionType(responses, QuestionType.electricity_greenTariffYesNo_portal);
    if (hasGreenTarrif) {
      if (hasGreenTarrif?.toLowerCase() == "yes" || hasGreenTarrif == 1) {
        const greenTariffPercent = this._getResponseDataByQuestionType(responses, QuestionType.electricity_greenTariffPercentage_portal);
        if (greenTariffPercent && !isNaN(greenTariffPercent)) {
          return parseFloat(greenTariffPercent);
        }
      }
    }
    return null;
  }

  private async _saveQuestionResponse(questions: any, data: any, submissionId: any) {
    const responseData = [];
    questions.forEach((question: Question) => {
      responseData.push({
        questionId: question.id,
        value: typeof data[question.reference] == 'object' ? JSON.stringify(data[question.reference]) : data[question.reference],
      });
    });
    await this._saveResponseData(submissionId, JSON.stringify(responseData));
  }

  private async _saveEntity(entityTypeId: number, data: any, questions: Question[]): Promise<number> {
    //There must be an entity column and its value is unique identity for us.
    const entityColumn: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.entityReference);
    if (!entityColumn) {
      console.log('No entityColumn available');
      return 0;
    }

    //Insert entity in db if not exist and return its ID.
    const entityName = data[entityColumn.reference];
    const entityId = await this._selectEntity(entityName, entityTypeId);
    if (!entityId) {
      console.log('No entityId available ' + entityName);
      return 0;
    }
    return entityId;
  }

  private async _getEntityIdByEmail(formName: string, data: any, questions: Question[], formId: string, submissionId: string): Promise<number> {
    //There must be an entity column and its value is unique identity for us.
    const entityColumn: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.emailEntityReference);
    if (!entityColumn) {
      console.log('No entityColumn available');
      return 0;
    }

    //Insert entity in db if not exist and return its ID.
    const email = data[entityColumn.reference];
    const entityId = await this._selectCustomerByPersonEmail(email)
    if (!entityId) {
      console.log('No company linked with person ' + email);
      return 0;
    }

    
    /* RAM: To control create clickup task while offline processing of submissions */
   if(process.env.CLICKUP_CREATE_SUBTASK=='1')
    {
       //Create Subtask in clickup.
       const task = await this._getCertificationTaskfromEmail(email);
       //Do we need to check if subtask already exsit in parent before proceeding? 
       //We can query to clickup.task where parent = task.parent and name = formname
       const response = await this.clickupService.createTask(formName, task.companyName, task.status, task.certificationTaskId, task.listId, formId, submissionId);
       if (!response?.id) {
          console.error('_getEntityIdByEmail SubTask not created ', response);
          return 0;
       } else {
          await this.clickupService.processTasksDirectToDB([response]);
       }
    }

    return entityId;
  }

  private async _getEntityIdByUniqueId(data: any, questions: Question[]): Promise<number> {
    //There must be an entity column and its value is unique identity for us.
    const entityColumn: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.entityReference);
    if (!entityColumn) {
      console.log('No entityColumn available');
      return 0;
    }

    //Insert entity in db if not exist and return its ID.
    const BAQ_UniqueId = data[entityColumn.reference];
    const entityId = await this._selectCustomerByUniqueId(BAQ_UniqueId)
    if (!entityId) {
      console.log('No company linked with BAQ_UniqueId ' + BAQ_UniqueId);
      return 0;
    }

    return entityId;
  }

  private _getMonthNumber(monthName: string): number | undefined {
    if (monthName.length < 3) { // if a number is provided
      if (!isNaN(Number(monthName)))
      {
        if (Number(monthName) >= 1 && Number(monthName) <= 12)
          return Number(monthName);
      }
      return undefined; // Invalid month name
    }
    const months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
    monthName = monthName.toLocaleLowerCase().trim().substring(0,3);
    const monthIndex = months.findIndex((month) => month === monthName);

    if (monthIndex !== -1) {
      return monthIndex + 1;
    } else {
      return undefined; // Invalid month name
    }
  }

  private async _selectEntity(entityName: any, entityTypeId: number) {
    const query = await this.databaseService.execute("[Dimension].[spEntity_Select]", [
      { name: "entityName", type: mssql.TYPES.NVarChar, value: entityName },
      { name: "entityTypeId", type: mssql.TYPES.NVarChar, value: entityTypeId }
    ]);
    const results = query.singleResult;
    return results?.id;
  }


  private async _selectCustomerByPersonEmail(email: string) {
    const query = await this.databaseService.execute("[Dimension].[spCustomer_SelectByPersonEmail]", [
      { name: "email", type: mssql.TYPES.NVarChar, value: email },
    ]);
    const results = query.singleResult;
    return results?.id;
  }
  private async _selectCustomerByUniqueId(BAQ_uniqueId: string) {
    const query = await this.databaseService.execute("[Dimension].[spCustomer_SelectByUniqueId]", [
      { name: "BAQ_UniqueId", type: mssql.TYPES.NVarChar, value: BAQ_uniqueId },
    ]);
    const results = query.singleResult;
    return results?.id;
  }
  private async _getCertificationTaskfromEmail(email: string) {
    const query = await this.databaseService.execute("[clickup].[spClickup_GetCertificationTaskByPersonEmail]", [
      { name: "email", type: mssql.TYPES.NVarChar, value: email },
    ]);
    const result = query.singleResult;
    return result;
  }

  private async _getBAQUniqueIdfromEmail(email: string) {
    const query = await this.databaseService.execute("[clickup].[spCustomField_GetCertificationUniqueId]", [
      { name: "email", type: mssql.TYPES.NVarChar, value: email },
    ]);
    const result = query.singleResult;
    return result;
  }

  private async _getPersonTaskfromEmail(email: string) {
    const query = await this.databaseService.execute("[clickup].[spClickup_GetPersonTaskByEmail]", [
      { name: "email", type: mssql.TYPES.NVarChar, value: email },
    ]);
    const result = query.singleResult;
    return result?.personTaskId;
  }

  private async _getCompanyTaskfromName(name: string) {
    const query = await this.databaseService.execute("[clickup].[spClickup_GetCompanyTaskByName]", [
      { name: "name", type: mssql.TYPES.NVarChar, value: name },
    ]);
    const result = query.singleResult;
    return result?.companyTaskId;
  }

  private async _getCompanyTask(name: string, email: string) {
    const query = await this.databaseService.execute("[clickup].[spClickup_GetCompanyTask]", [
      { name: "name", type: mssql.TYPES.NVarChar, value: name },
      { name: "email", type: mssql.TYPES.NVarChar, value: email },
    ]);
    const result = query.singleResult;
    return result?.companyTaskId;
  }

  private async _createSubmission(submissionId: number, managementBasedDecision: number, optedIn: number, entityId: number, entityTypeId: number, formId: number) {
    const query = await this.databaseService.execute("portal.spFormSubmissionDimension_Save", [
      { name: "submissionId", type: mssql.TYPES.Int, value: submissionId },
      { name: "isMBD", type: mssql.TYPES.Int, value: managementBasedDecision },
      { name: "optedIn", type: mssql.TYPES.Int, value: optedIn },
      { name: "entityId", type: mssql.TYPES.Int, value: entityId },
      { name: "entityTypeId", type: mssql.TYPES.Int, value: entityTypeId },
      { name: "formId", type: mssql.TYPES.Int, value: formId }
    ]);

    const results = query.singleResult;
    return results?.id;
  }

  // private async _processSubmissionByMonth(questionId: number, userInput: number, entityId: number, entityTypeId: number,
  //   submissionId: number, emissionActivityId: number, month: number, conversionFactor: number,
  //   reportingFrequencyId: number, dataUnit: string, conversionInfo: any, chargingPercentAtWorkPlace: number|null) {
  //   if (this.isEmpty(userInput)) {
  //     //console.log(`No user input found for month ${month} for ${entityId}`);
  //     return;
  //   }
  //   if(conversionInfo) {
  //     const convertedValue = await this._convertTo(conversionInfo, userInput);
  //     if (convertedValue) {
  //       userInput = convertedValue.outputValue;
  //       //dataUnit = convertedValue.dataUnit || dataUnit;
  //       conversionFactor = convertedValue.conversionFactor || conversionFactor;
  //     }
  //   }
  //   if(chargingPercentAtWorkPlace) { // remove % charged at work place from Conversion Factor
  //     conversionFactor = this._getRemainingValue(conversionFactor, chargingPercentAtWorkPlace); // userInput * ((100 - chargingPercentAtWorkPlace) / 100);
  //   }

  //   const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, emissionActivityId, userInput, month, conversionFactor,
  //                                           reportingFrequencyId, dataUnit, false, false, questionId);
  //   await this._processEmissionctivity(clsEmission);
  // }

  private async _processSubmissionByAnnual(questionId: number, userInput: number, entityId: number, entityTypeId: number,
    submissionId: number, emissionActivityId: number, month: number, conversionFactor: number,
    reportingFrequencyId: number, dataUnit: string, conversionInfo: any, chargingPercentAtWorkPlace: number|null) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for annualised option for ${entityId}`);
      return;
    }
    if(conversionInfo) {
      const convertedValue = await this._convertTo(conversionInfo, userInput);
      if (convertedValue) {
        userInput = convertedValue.outputValue;
        //dataUnit = convertedValue.dataUnit || dataUnit;
        conversionFactor = convertedValue.conversionFactor || conversionFactor;
      }
    }
    if(chargingPercentAtWorkPlace) { // remove % charged at work place from userInput
      conversionFactor = this._getRemainingValue(conversionFactor, chargingPercentAtWorkPlace); //userInput * ((100 - chargingPercentAtWorkPlace) / 100);
    }

    const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, emissionActivityId, userInput, month, conversionFactor,
                                            reportingFrequencyId, dataUnit, false, false, questionId);
    await this._processEmissionctivity(clsEmission);
  }

  private async _processAnnualSubmissionByMonths(questionId: number, arrMonths: any[], queProp: any, entityId: number, entityTypeId: number,
    submissionId: number, emissionActivityId: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string,
    conversionInfo: any, chargingPercentAtWorkPlace: number|null) {
    if (typeof arrMonths == 'object') {
      arrMonths = Object.values(arrMonths);
    }
    // if (arrMonths.length < 12) {
    //   //TODO - add this in audit table
    //   console.log("Less number of months found for annualised (monthly) option for " + entityId);
    // }

    // let month = 0;
    for (let monthlyInput of arrMonths) {
      let _conversionFactor = conversionFactor; // reset to original for each month

      //month++;
      // if (typeof monthlyInput == 'object') {
      //   monthlyInput = Object.values(monthlyInput);
      // }
      let month = this._getMonthNumber(monthlyInput[queProp.monthCol]);
      let userInput = queProp.dataCol ? monthlyInput[queProp.dataCol] : undefined;
      if (this.isEmpty(userInput)) {
        //console.log(`No user input found for month ${month} for ${entityId}`);
        continue;
      }

      if(conversionInfo) {
        const convertedValue = await this._convertTo(conversionInfo, userInput);
        if (convertedValue) {
          userInput = convertedValue.outputValue;
          //dataUnit = convertedValue.dataUnit || dataUnit;
          _conversionFactor = convertedValue.conversionFactor || _conversionFactor;
        }
      }

      if(chargingPercentAtWorkPlace) { // remove % charged at work place from userInput
        _conversionFactor = this._getRemainingValue(_conversionFactor, chargingPercentAtWorkPlace); //userInput * ((100 - chargingPercentAtWorkPlace) / 100);
      }

      const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, emissionActivityId, userInput, month,
                                              _conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
      await this._processEmissionctivity(clsEmission);
    }
  }

  private async _processAnnualSubmissionByJanToJun(questionId: number, arrMonths: any, entityId: number, entityTypeId: number, submissionId: number, emissionActivityId: number,
    conversionFactor: number, reportingFrequencyId: number, dataUnit: string, conversionInfo: any) {
    if (typeof arrMonths == 'object') {
      arrMonths = Object.values(arrMonths);
    }

    if (arrMonths.length < 6) {
      //TODO - add this in audit table
      console.log("Less number of months found for annualised (monthly) option for " + entityId);
    }
    let month = 0;
    for (let userInput of arrMonths) {
      let _conversionFactor = conversionFactor; // reset to original for each month

      month++;
      // const userInput = monthlyInput.length > 0 ? monthlyInput[0] : undefined;
      if (this.isEmpty(userInput)) {
        //console.log(`No user input found for month ${month} for ${entityId}`);
        continue;
      }

      if(conversionInfo) {
        const convertedValue = await this._convertTo(conversionInfo, userInput);
        if (convertedValue) {
          userInput = convertedValue.outputValue;
          //dataUnit = convertedValue.dataUnit || dataUnit;
          _conversionFactor = convertedValue.conversionFactor || _conversionFactor;
        }
      }

      const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, emissionActivityId, userInput, month, _conversionFactor,
                                              reportingFrequencyId, dataUnit, false, false, questionId);
      await this._processEmissionctivity(clsEmission);
    }
  }

  private async _processAnnualSubmissionByJulToDec(questionId: number, arrMonths: any[], entityId: number, entityTypeId: number, submissionId: number, emissionActivityId: number,
    conversionFactor: number, reportingFrequencyId: number, dataUnit: string, conversionInfo: any) {
    if (typeof arrMonths == 'object') {
      arrMonths = Object.values(arrMonths);
    }

    if (arrMonths.length < 6) {
      console.log("Less number of months found for annualised (monthly) option for " + entityId);
    }
    let month = 6;
    for (let userInput of arrMonths) {
      let _conversionFactor = conversionFactor; // reset to original for each month

      month++;
      if (this.isEmpty(userInput)) {
        //console.log(`No user input found for month ${month} for ${entityId}`);
        continue;
      }

      if(conversionInfo) {
        const convertedValue = await this._convertTo(conversionInfo, userInput);
        if (convertedValue) {
          userInput = convertedValue.outputValue;
          //dataUnit = convertedValue.dataUnit || dataUnit;
          _conversionFactor = convertedValue.conversionFactor || _conversionFactor;
        }
      }

      const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, emissionActivityId, userInput, month, _conversionFactor,
                                              reportingFrequencyId, dataUnit, false, false, questionId);
      await this._processEmissionctivity(clsEmission);
    }
  }

  private _processOfficeStaffItemiseInput(userInput: any) {
    let totalOfficeStaff = 0;
    if (userInput) {
      const data = typeof userInput == "string" ? JSON.parse(userInput) : userInput;

      data.forEach((siteItem: any) => {
        const numOfficeStaff = siteItem['Number of staff'];
        if (numOfficeStaff && !isNaN(+numOfficeStaff)) {
          totalOfficeStaff += +numOfficeStaff;
        }
      });
    }
    return totalOfficeStaff;
  }

  private async _processOtherFuelItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, emissionActivities: any, properties: any, conversionFactor: number, reportingFrequencyId: number) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for other fuel for ${entityId}`);
      return;
    }

    const fuelData = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
    //const emissionActivities = questionId?.emissionActivities ?? [];

    if (!emissionActivities || emissionActivities.length == 0) {
      console.log(`fuel emission data is not configured in question properties.`);
      return;
    }
    if (fuelData && fuelData.length > 0) {
      for (const fuelItem of fuelData) {
          const fuelType = fuelItem[properties.typeCol];
          const dataUnit = fuelItem[properties.dataUnitCol];
          const usage = fuelItem[properties.dataCol];

          if (!fuelType || !dataUnit) {
            //console.log(`No Fuel Type or Unit found`);
            continue;
          }
          
          const eA = emissionActivities.find((ea: any) => ea.typeValue == fuelType && ea.dataUnitValue == dataUnit);
          
          if (!eA) {
            console.log(`No emission activity found for fuelType: ${fuelType} ${dataUnit}`);
            continue;
          }
        
          if (!usage || isNaN(+usage)) {
            //console.log(`Invalid usage value: ${usage}`);
            continue;
          }

          const monthValue = properties.monthCol ? fuelItem[properties.monthCol] : null;
          const monthNumber = monthValue ? this._getMonthNumber(monthValue) : null;
        
          const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, eA.emissionActivityId, usage,
                                            monthNumber, conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
          await this._processEmissionctivity(clsEmission);
        }
    }
  }

  private async _processDeliveriesItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number,
    emissionActivities: any, properties: any, 
    conversionFactor: number, reportingFrequencyId: number, dataUnit: string, conversionInfo: any) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for deliveries for ${entityId}`);
      return;
    }

    const deliveryData = typeof userInput == "string" ? JSON.parse(userInput) : userInput;

    if (!emissionActivities || emissionActivities.length == 0) {
      console.log(`Delivery emission data is not configured in question properties.`);
      return;
    }
    if (deliveryData && deliveryData.length > 0) {
      
      for (const deliveryItem of deliveryData) {
          const transportType = deliveryItem[properties.typeCol];
          const dataUnit = properties.dataUnitValue;
          const distance = deliveryItem.distance;
          const weight = deliveryItem.weight;
          const spendAmount = deliveryItem.spendAmount;
          let _conversionFactor = properties.conversionFactorValue; // reset to original for each item
        
          if (!transportType) {
            continue;
          }
          
          const eA = emissionActivities.find((ea: any) => ea.typeValue == transportType);
          
          if (!eA) {
            console.log(`No emission activity found for transportType: ${transportType} ${dataUnit}`);
            continue;
          }
        
          if ((!distance && !weight) && isNaN(+spendAmount)) {
            continue;
          }
        
          if (distance && weight && !isNaN(+distance) && !isNaN(+weight)) {
            const vehicleTotal = distance * weight;
            const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, eA.emissionActivityId, vehicleTotal, null,
                                                    _conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
            await this._processEmissionctivity(clsEmission);
          }
          else if (spendAmount && !isNaN(+spendAmount)) {
            if(conversionInfo) {
              const convertedValue = await this._convertTo(conversionInfo, 1);
              if (convertedValue) {
                _conversionFactor = convertedValue.conversionFactor || conversionFactor;
              }
            }
            const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, eA.spendAmountEmissionActivityId, spendAmount,
                                                    null, _conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
            await this._processEmissionctivity(clsEmission);
          }
        }
    }
  }

  private async _processHotelStayItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, emissionActivities: any, properties: any, month: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for Nights Stayed for ${entityId}`);
      return;
    }

    const data = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
    //const emissionActivities = questionResponse?.emissionActivities ?? [];

    if (!emissionActivities || emissionActivities.length == 0) {
      console.log(`hotel emission data is not configured in question properties.`);
      return;
    }

    for(const eA of emissionActivities){
      const hotelData = data.filter((r) => r[properties.typeCol] == eA.typeValue); //data?.filter((x: any) => x['Country'] == hotel.country);
      if (hotelData && hotelData.length > 0) {
        for(const hotelItem of hotelData) {
          const nights = hotelItem.nights;
          //const persons = hotelItem.people; // not used as of now in template excelsheet
          const rooms = hotelItem.rooms; 
          if (nights && !isNaN(+nights) && rooms && !isNaN(rooms)) {
            const hotelTotal = nights * rooms; // as per Excelsheet calculation is (Nights * Rooms) 
            const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, eA.emissionActivityId, hotelTotal, month,
                                                    conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
            await this._processEmissionctivity(clsEmission);
          }
        }
      }
    }
  }

  private async _processFlightDomesticItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, emissionActivityId: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string) {
      if (this.isEmpty(userInput)) {
        //console.log(`No user input found for Nights Stayed for ${entityId}`);
        return;
      }

      const flightData = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
      if (!emissionActivityId) {
        console.log(`flights emission data is not configured in QuestionEmissionActivity.`);
        return;
      }
      //dataUnit = "Kilometers (KM)";
      if (flightData && flightData.length > 0) {
        //flightData.forEach(async (flightItem: any) => { // << forEach doesn't wait for await
        for (const flightItem of flightData) {
          const depAirport = flightItem.departureAirport.value;
          const arrAirport = flightItem.arrivalAirport.value;

          if (!depAirport || !arrAirport) {
            console.log(`No Dep. or Arr. Airport found`);
            continue;
          }
          const distance = await this._getFlightDistance(depAirport, arrAirport);
          if (!distance) {
            console.log(`No distance found for ${depAirport} to ${arrAirport}`);
            continue;
          }

          const returnFlight = flightItem.returnFlight;
          const flightCount = flightItem.numFlights; 
          const month = flightItem.month; 
          const monthNumber = month ? this._getMonthNumber(month) : null;

          const flightDistance = distance.distanceKms;
          const totalDistance = (returnFlight ? flightDistance * 2 : flightDistance) * (!flightCount ? 1 : flightCount);
          const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, emissionActivityId, totalDistance, monthNumber,
                                                  conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
          await this._processEmissionctivity(clsEmission);
        }//);
      }
  }
  private async _processFlightShortHaulItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, emissionActivities: any, properties: any, month: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for Nights Stayed for ${entityId}`);
      return;
    }
    
    const data = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
    //const emissionActivities = questionResponse?.emissionActivities ?? [];

    if (!emissionActivities || emissionActivities.length == 0) {
      console.log(`flight emission data is not configured in question properties.`);
      return;
    }
    //dataUnit = "Kilometers (KM)";
    //flightClasses?.forEach((flightClass: any) => {
    for(const eA of emissionActivities){
      const flightData = data.filter((r) => r[properties.typeCol] == eA.typeValue); //data?.filter((x: any) => x['Short-Haul'] == flightClass.type);
      if (flightData && flightData.length > 0) {
        //flightData.forEach(async (flightItem: any) => {
        for (const flightItem of flightData) {
          const depAirport = flightItem.departureAirport.value;
          const arrAirport = flightItem.arrivalAirport.value;

          if (!depAirport || !arrAirport) {
            console.log(`No Dep. or Arr. Airport found`);
            continue;
          }
          const distance = await this._getFlightDistance(depAirport, arrAirport);
          if (!distance) {
            console.log(`No distance found for ${depAirport} to ${arrAirport}`);
            continue;
          }

          const returnFlight = flightItem.returnFlight;
          const flightCount = flightItem.numFlights;
          const month = flightItem.month;
          const monthNumber = month ? this._getMonthNumber(month) : null;

          const flightDistance = distance.distanceKms;
          const totalDistance = (returnFlight ? flightDistance * 2 : flightDistance) * (!flightCount ? 1 : flightCount);
          const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, eA.emissionActivityId, totalDistance,
                                              monthNumber, conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
          await this._processEmissionctivity(clsEmission);
        }//);
      }
    }//);
  }

  private async _processFlightLongHaulItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, emissionActivities: any, properties: any, month: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for Nights Stayed for ${entityId}`);
      return;
    }

    const data = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
    //const emissionActivities = questionId?.emissionActivities ?? [];

    if (!emissionActivities || emissionActivities.length == 0) {
      console.log(`flight emission data is not configured in question properties.`);
      return;
    }
    //dataUnit = "Kilometers (KM)";
    //flightClasses?.forEach((flightClass: any) => {
    for(const eA of emissionActivities){
      const flightData = data.filter((r) => r[properties.typeCol] == eA.typeValue); // data?.filter((x: any) => x['Long-Haul'] == flightClass.type);
      if (flightData && flightData.length > 0) {
        //flightData.forEach(async (flightItem: any) => {
        for (const flightItem of flightData) {
          const depAirport = flightItem.departureAirport.value;
          const arrAirport = flightItem.arrivalAirport.value;

          if (!depAirport || !arrAirport) {
            console.log(`No Dep. or Arr. Airport found`);
            continue;
          }
          const distance = await this._getFlightDistance(depAirport, arrAirport);
          if (!distance) {
            console.log(`No distance found for ${depAirport} to ${arrAirport}`);
            continue;
          }

          const returnFlight = flightItem.returnFlight;
          const flightCount = flightItem.numFlights;
          const month = flightItem.month;
          const monthNumber = month ? this._getMonthNumber(month) : null;

          const flightDistance = distance.distanceKms;
          const totalDistance = (returnFlight ? flightDistance * 2 : flightDistance) * (!flightCount ? 1 : flightCount);
          const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, eA.emissionActivityId, totalDistance,
                                            monthNumber, conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
          await this._processEmissionctivity(clsEmission);
        }//);
      }
    } //);
  }
  private async _processFlightItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, emissionActivities: any, properties: any, month: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for Nights Stayed for ${entityId}`);
      return;
    }

    const flightData = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
    //const emissionActivities = questionId?.emissionActivities ?? [];

    if (!emissionActivities || emissionActivities.length == 0) {
      console.log(`flight emission data is not configured in question properties.`);
      return;
    }
    if (flightData && flightData.length > 0) {
      for (const flightItem of flightData) {
          const depAirport = flightItem.departureAirport.value;
          const arrAirport = flightItem.arrivalAirport.value;

          if (!depAirport || !arrAirport) {
            console.log(`No Dep. or Arr. Airport found`);
            continue;
          }
          const flightTypeDistance = await this._getFlightTypeDistance(depAirport, arrAirport);
          if (!flightTypeDistance) {
            console.log(`No distance found for ${depAirport} to ${arrAirport}`);
            continue;
          }
          const flightType = flightTypeDistance.flightType;
          const flightClass = flightItem.flightClass;
        
          // Determine the typeValue based on flight type and class
          let typeValue = flightType;
          
          if (flightType === 'domestic') {
            // For domestic flights, ignore flightClass
            typeValue = 'domestic';
          } else if (flightType === 'short_haul') {
            // For short haul flights, apply mapping rules
            let mappedClass = flightClass;
            if (flightClass === 'premium_economy') {
              mappedClass = 'economy';
            } else if (flightClass === 'first') {
              mappedClass = 'business';
            }
            typeValue = flightClass ? `${flightType}_${mappedClass}` : `${flightType}_average`;
          } else if (flightType === 'long_haul') {
            // For long haul flights, use class as-is
            typeValue = flightClass ? `${flightType}_${flightClass}` : `${flightType}_average`;
          }
          
          const eA = emissionActivities.find((ea: any) => ea.typeValue == typeValue);
          
          if (!eA) {
            console.log(`No emission activity found for typeValue: ${typeValue}`);
            continue;
          }
        
          const flightDistance = flightTypeDistance.distanceKms;
          const returnFlight = flightItem.returnFlight;
          const flightCount = flightItem.numFlights;
          const month = flightItem.month;
          const monthNumber = month ? this._getMonthNumber(month) : null;
          const totalDistance = (returnFlight ? flightDistance * 2 : flightDistance) * (!flightCount ? 1 : flightCount);
        
          const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, eA.emissionActivityId, totalDistance,
                                            monthNumber, conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
          await this._processEmissionctivity(clsEmission);
        }
    }
  }

  private async _getFlightDistance(depAirport: string, arrAirport: string): Promise<any> {
      const query = await this.databaseService.execute("Emissions.spGetFlightDistance", [
        { name: "depAirport", type: mssql.TYPES.NVarChar, value: depAirport },
        { name: "arrAirport", type: mssql.TYPES.NVarChar, value: arrAirport },
      ]);
      const result = query.singleResult;
      return result;
  }

  private async _getFlightTypeDistance(depAirport: string, arrAirport: string): Promise<any> {
      const query = await this.databaseService.execute("Emissions.spGetFlightTypeDistance", [
        { name: "depAirport", type: mssql.TYPES.NVarChar, value: depAirport },
        { name: "arrAirport", type: mssql.TYPES.NVarChar, value: arrAirport },
      ]);
      const result = query.results[0];
      return result;
  }

  private async _processEmissionctivity(clsEmission: EmissionActivity) {
    //console.log(clsEmission);
      if(clsEmission.userInput <= 0) { // No need to process zero or negative values
        return;
      }
    
      const query = await this.databaseService.execute("[Fact].[spEmission_Save]", [
        { name: "entityId", type: mssql.TYPES.Int, value: clsEmission.entityId },
        { name: "entityTypeId", type: mssql.TYPES.Int, value: clsEmission.entityTypeId },
        { name: "submissionId", type: mssql.TYPES.Int, value: clsEmission.submissionId },
        { name: "emissionActivityId", type: mssql.TYPES.Int, value: clsEmission.emissionActivityId },
        { name: "userInput", type: mssql.TYPES.Decimal(18,2), value: clsEmission.userInput },
        { name: "month", type: mssql.TYPES.Int, value: clsEmission.month },
        { name: "conversionFactor", type: mssql.TYPES.Decimal(10,4), value: clsEmission.conversionFactor },
        { name: "reportingFrequencyId", type: mssql.TYPES.Int, value: clsEmission.reportingFrequencyId || ReportingFrequency.annualised },
        { name: "dataUnit", type: mssql.TYPES.NVarChar, value: clsEmission.dataUnit },
        { name: "questionId", type: mssql.TYPES.Int, value: clsEmission.questionId },
      ]);
      return query.results;
  }

  private async _processItemsInBatches(items: any[], batchSize: number, callback: (batch: any) => Promise<any>): Promise<void> {
    for (let i = 0; i < items.length; i += batchSize) {
      try {
        const batch = items.slice(i, i + batchSize);
        await callback(batch);
      } catch (e) {
        console.error("error while processing jotforms.", e)
      }
    }
  }

  private async addToPowerBIExport(submissionId: string, emailTo: string, companyName: string, productName: string) {
    const query = await this.databaseService.execute('[powerbi].[spPowerBIExportQueue_Add]', [
      { name: "submissionId", type: mssql.TYPES.NVarChar, value: submissionId },
      { name: "emailTo", type: mssql.TYPES.NVarChar, value: emailTo },
      { name: "companyName", type: mssql.TYPES.NVarChar, value: companyName },
      { name: "productName", type: mssql.TYPES.NVarChar, value: productName }
    ]);
    const results = query.results;
    return results;
  }

  private async addBlueAwardQuestionnaire(items: any) {
    const query = await this.databaseService.execute('[forms].[spForms_AddBlueAward]', [
      { name: "blueAwards_JSON", type: mssql.TYPES.NVarChar, value: JSON.stringify(items) },
    ]);
    const results = query.results;
    return results;
  }

  private async addGoldAwardQuestionnaire(items: any) {
    const query = await this.databaseService.execute('[forms].[spForms_AddGoldAward]', [
      { name: "goldAwards_JSON", type: mssql.TYPES.NVarChar, value: JSON.stringify(items) },
    ]);
    const results = query.results;
    return results;
  }
  

  private getAwardType(BAQ_id: string, progId: number): AwardType {
    if (BAQ_id.toUpperCase() === "RJM DIGITAL") {
      return AwardType.RJM;
    }
    else if (BAQ_id.toUpperCase() === "APP" && !progId) { // If progId is null then its blue award
      return AwardType.DEFAULT;
    }
    else if (progId == 2) {
      return AwardType.APP_SILVER;
    }
    else if (progId == 3) {
      return AwardType.APP_GOLD;
    }
    else if (progId == 4) {
      return AwardType.APP_PLATINUM;
    }
    else {
      return AwardType.DEFAULT;
    }
  }
  
  private getAwardConfig(awardType: AwardType): AwardConfig {
    const configs = {
      [AwardType.RJM]: {
        productName: "Blue Award",
        listName: "Blue completed",
        statusName: this.getStatusName("Blue completed")
      },
      [AwardType.APP_GOLD]: {
        productName: "Gold Certification",
        listName: "Gold incomplete",
        statusName: this.getStatusName("Gold incomplete")
      },
      [AwardType.APP_SILVER]: {
        productName: "Silver Certification",
        listName: "Silver incomplete",
        statusName: this.getStatusName("Silver incomplete")
      },
      [AwardType.APP_PLATINUM]: {
        productName: "Platinum Certification",
        listName: "Platinum incomplete",
        statusName: this.getStatusName("Platinum incomplete")
      },
      [AwardType.DEFAULT]: {
        productName: "Blue Award",
        listName: "Blue completed",
        statusName: this.getStatusName("Blue completed")
      }
    };
    
    return configs[awardType];
  }
  
  private getStatusName(listName: string): string {
    return this.customFieldsConstants.findConstantIdbyName(
      CustomFieldsConstantTypes.ClickupListDefaultStatusNames,
      listName
    );
  }
  
  private async processAwardForm(
    jsonObj: any,
    response: any,
    jsonResponseData: any
  ): Promise<ProcessingResponse> {
    try {
      const awardType = this.getAwardType(jsonObj, jsonResponseData);
      const config = this.getAwardConfig(awardType);
      const result = await this.processAwardByType( awardType, jsonObj, response, jsonResponseData, config );
  
      if (!result) {
        return ProcessingResponse.entity_not_found;
      }
  
      await this.createRelationships(result, jsonObj);
      return ProcessingResponse.success;
    } catch (error) {
      console.error('processAwardForm', error);
      return ProcessingResponse.entity_not_found;
    }
  }
  
  private async processAwardByType(
    awardType: AwardType,
    jsonObj: any,
    response: any,
    jsonResponseData: any,
    config: AwardConfig
  ): Promise<TaskResult | null> {
    const tasks = [];
    let personTaskId, certTaskId, companyTaskId, certTaskCreated = false;
  
    switch (awardType) {
      case AwardType.RJM: // Blue Award through RJM Digital
        personTaskId = await this._getPersonTaskfromEmail(jsonObj.BAQ_Email);
        if (!personTaskId)
        {
            console.error('processAwardByType[RJM]', `Person Task not found for ${jsonObj.BAQ_Email}`);
            await this.errorLoggerService.notifyToAdmin(`processAwardByType[RJM]: Person Task not found for ${jsonObj.BAQ_Email}`);
            return null;
        } 
  
        const certTask = await this._createCertificationTask(
          config.listName,
          config.productName,
          config.statusName,
          jsonObj,
          response.submissionId,
          response.jotFormId,
          jsonResponseData.buildDate
        );
        certTaskId = certTask?.id;
        if (!certTaskId) return null;
        certTaskCreated = true;
        tasks.push(certTask);
  
        const companyTask = await this._createCompanyTask( "Company", jsonObj, jsonResponseData.buildDate );
        companyTaskId = companyTask?.id;
        if (!companyTaskId) return null;
        tasks.push(companyTask);
        
        break;
  
      case AwardType.APP_GOLD:
      case AwardType.APP_SILVER:
      case AwardType.APP_PLATINUM:
        personTaskId = await this._getPersonTaskfromEmail(jsonObj.BAQ_Email);
        if (!personTaskId)
        {
            console.error('processAwardByType[SILVER/GOLD]', `Person Task not found for ${jsonObj.BAQ_Email}`);
            await this.errorLoggerService.notifyToAdmin(`processAwardByType[SILVER/GOLD]: Person Task not found for ${jsonObj.BAQ_Email}`);
            return null;
        } 
  
        companyTaskId = await this._getCompanyTask( jsonObj.BAQ_CompanyName, jsonObj.BAQ_Email );
        if (!companyTaskId)
        {
            console.error('processAwardByType[SILVER/GOLD]', `Company Task not found for ${jsonObj.BAQ_CompanyName}`);
            await this.errorLoggerService.notifyToAdmin(`processAwardByType[SILVER/GOLD]: Company Task not found for ${jsonObj.BAQ_CompanyName}`);
            return null;
        } 
  
        const existingCertTask = await this._getCertificationTaskfromEmail( jsonObj.BAQ_Email );
        if (existingCertTask?.certificationTaskId) {
          certTaskId = existingCertTask.certificationTaskId === '8694174h3' ? null  : existingCertTask.certificationTaskId;
        }
        if (!certTaskId) {
          const newCertTask = await this._createCertificationTask(
            config.listName,
            config.productName,
            config.statusName,
            jsonObj,
            response.submissionId,
            response.jotFormId,
            jsonResponseData.buildDate
          );
          certTaskId = newCertTask?.id;
          certTaskCreated = true;
          tasks.push(newCertTask);
        }
        else { // Set submissionId, formId in Manually created Certification Task custom field
          await this.clickupService.setTaskCustomFieldValue(certTaskId, "submissionId", response.submissionId);
          await this.clickupService.setTaskCustomFieldValueInDB(certTaskId, "submissionId", response.submissionId);
          await this.clickupService.setTaskCustomFieldValue(certTaskId, "formId", response.jotFormId);
          await this.clickupService.setTaskCustomFieldValueInDB(certTaskId, "formId", response.jotFormId);
        }
        if (!certTaskId) return null;
        break;
  
      default: // Blue Award
        const personTask = await this._createPersonTask( "People", jsonObj, response.submissionId, jsonResponseData.buildDate );
        personTaskId = personTask?.id;
        if (!personTaskId) return null;
        tasks.push(personTask);
  
        const defaultCertTask = await this._createCertificationTask(
          config.listName,
          config.productName,
          config.statusName,
          jsonObj,
          response.submissionId,
          response.jotFormId,
          jsonResponseData.buildDate
        );
        certTaskId = defaultCertTask?.id;
        if (!certTaskId) return null;
        certTaskCreated = true;
        tasks.push(defaultCertTask);
  
        const defaultCompanyTask = await this._createCompanyTask( "Company", jsonObj, jsonResponseData.buildDate );
        companyTaskId = defaultCompanyTask?.id;
        if (!companyTaskId) return null;
        tasks.push(defaultCompanyTask);
        
        break;
    }
  
    return { tasks, personTaskId, certTaskId, companyTaskId, certTaskCreated };
  }
  
  public async createRelationships(result: TaskResult, jsonObj: any): Promise<void> {
    const { companyTaskId, personTaskId, certTaskId, tasks, certTaskCreated } = result;
  
    await this.clickupService.addCompanyDirectToDB(
      companyTaskId,
      jsonObj.BAQ_CompanyName,
      jsonObj.BAQ_CompanyDescription
    );
  
    if (!certTaskCreated) {
      await this.clickupService.addPersonCompanyDirectToDB(companyTaskId, personTaskId);
      await this.clickupService.addCompanyCertificationDirectToDB(companyTaskId, certTaskId);
    }
  
    if (tasks.length > 0) {
      await this.clickupService.processTasksDirectToDB(tasks);
    }
  
    if (certTaskCreated) {
      await this.clickupService.setTaskRelationship(
        companyTaskId,
        certTaskId,
        companyTaskId,
        "Company in Certification Relationship"
      );
      await this.clickupService.setTaskRelationship(
        companyTaskId,
        certTaskId,
        personTaskId,
        "Person in Certification Relationship"
      );
    }
  }
}

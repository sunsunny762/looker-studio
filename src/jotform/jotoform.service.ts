import { Injectable } from "@nestjs/common";
import { DatabaseService } from "../database";
import * as mssql from "mssql";
import { QuestionType, EmissionActivity } from "./model";
import { ReportingFrequency } from "./model/reporting-frequency";
import { ConversionInfo, ConversionOutput, Question } from "./model/question";
import { ClickUpService } from "../clickup/clickup.service";
import { ProcessingResponse } from "./model/response";
import { FormCategory } from "./model/form-category";
import { CustomFieldsConstants } from "../clickup/customfields-constants";
import { CustomFieldsConstantTypes } from "../clickup/customfields-constant-types";
import { ErrorLoggerService } from "../error-logger/error-logger.service";
import { el } from "date-fns/locale";
import { AwardConfig, AwardType, TaskResult } from "./interfaces/award.interface";

@Injectable()
export class JotformService {
  constructor(private readonly databaseService: DatabaseService, private readonly clickupService: ClickUpService,
    private customFieldsConstants:CustomFieldsConstants, private readonly errorLoggerService: ErrorLoggerService
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

  public async processJotformResponses(): Promise<void> {
    
    try { 
      //const query = await this.databaseService.execute(process.env.JOTFORM_PROCESS_LOCAL_SP || "[Forms].[spFormResponse_SelectToProcess]");
      const query = await this.databaseService.execute(process.env.JOTFORM_PROCESS_LOCAL_SP || "[Forms].[spFormResponse_SelectToProcess_NonPortal]");
      const responses = query.results;

      console.log(`Total submissions to process : ${responses.length}`)
      let processResult: ProcessingResponse = ProcessingResponse.unknown;
      for (let response of responses) {
        try {
          this.errorLoggerService.setFormSubmissionIds(response.jotFormId, response.submissionId);
          
          console.log(`Processing SubmissionId: ${response.submissionId}`);
          if (response.categoryId == FormCategory.GoldAwardQuestionnaire) {
            processResult = await this.processGoldAwardForm(response);
            // In processGoldAwardForm, Create a Certification Task in Gold incomplete list in clickup
            // This form will be submitted through Gold App in Jotform
          } else if (response.categoryId == FormCategory.BlueAwardQuestionnaire) {
            processResult = await this.processBlueAwardForm(response);
            // In processBlueAwardForm, add function to create a subTask in clickup under certifications list > "company name" task
            // Use clickUp API to findout "company name" task and create subtask under that.
          } else {
            processResult = await this.processResponse(response);
          }
          // await this._insertIntoAudit(response.id, "result");
        }
        catch (e) {
          console.error("processJotformResponses1",e);
        }
        finally {
          // Mark as processed so won't be picked again
          //if (processResult !== ProcessingResponse.entity_not_found) {
          if(processResult == ProcessingResponse.success) {
            try{
              await this._markProcessed(response.id);
            }
            catch (e) {
              console.error("processJotformResponses2", e);
            }
          }
        }
      }
      this.errorLoggerService.setFormSubmissionIds(null, null);
    } catch (e) {
      console.error("processJotformResponses3",e);
    }
  }


  private removeBeforeBAQ(str) {
    const baqIndex = str.indexOf('BAQ');
    if (baqIndex !== -1) {
      return str.substring(baqIndex);
    }
    return str; // Return the original string if 'BAQ' is not found
  }

  private processCustomJson(key, obj) {
    if (key.indexOf('BAQ_ReportStartDate') > -1) {
      let data = obj[key];
      let date = new Date(data.year, data.month-1, data.day);
      var newkey = this.removeBeforeBAQ(key);
      obj[newkey] = date;
      delete obj[key];
    }
    else if (key.indexOf('BAQ_WorkingDaysAndCommuting') > -1) {
      let data = obj[key];
      if (data.length > 0) {
        const dataUnits = obj['BAQ_DataUnit']?.toLowerCase().trim(); // Km or Miles
        const conversionFactor = dataUnits === 'miles (m)' ? 1.60934 : 1;
        obj['BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Office'] = data[0][0];
        obj['BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekWorked_Other'] = data[0][1];
        obj['BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Office'] = data[1][0];
        obj['BAQ_WorkingDaysAndCommuting_AvgDaysPerWeekCommuting_Other'] = data[1][1];
        obj['BAQ_WorkingDaysAndCommuting_AvgDistance_Office'] = data[2][0] * conversionFactor;
        obj['BAQ_WorkingDaysAndCommuting_AvgDistance_Other'] = data[2][1] * conversionFactor;
        delete obj[key];
      }
    }
    else if (key.indexOf('BAQ_CompanyVehiclesMileage') > -1) {
      let data = obj[key] ? JSON.parse(obj[key]) : [];
      const dataUnits = obj['BAQ_DataUnit']?.toLowerCase().trim(); // Km or Miles
      const conversionFactor = dataUnits === 'miles (m)' ? 1.60934 : 1;
      for (let index = 0; index < data.length; index++) {
        const element = data[index]['Vehicle type'];
        const key = `BAQ_CompanyVehiclesMileage_${element}`;
        obj[key] = (obj[key] || 0) + data[index]['Total distance'] * conversionFactor;
      }
      delete obj[key];
    }
    else if (key.indexOf('BAQ_BusinessTravel') > -1) {
      let data = obj[key] ? JSON.parse(obj[key]) : [];
      for (let index = 0; index < data.length; index++) {
        const element = data[index]['Domestic / International'];
        const elementFrequency = data[index]['Frequency of travel'];
        obj[`BAQ_BusinessTravel_${element}_${elementFrequency}`] = data[index]['Number of staff'];
      }
      delete obj[key];
    }
    else if (key.indexOf('BAQ_GoodsReceived') > -1) {
      let data = obj[key] ? JSON.parse(obj[key]) : [];
      for (let index = 0; index < data.length; index++) {
        const element = data[index]['Distance'];
        const elementFrequency = data[index]['Frequency'];
        obj[`BAQ_GoodsReceived_${element}_${elementFrequency}`] = data[index]['Avg weight (Kgs) per delivery'];
      }
      delete obj[key];
    }
    else if (key.indexOf('BAQ_GoodsSent') > -1) {
      let data = obj[key] ? JSON.parse(obj[key]) : [];
      for (let index = 0; index < data.length; index++) {
        const element = data[index]['Distance'];
        const elementFrequency = data[index]['Frequency'];
        obj[`BAQ_GoodsSent_${element}_${elementFrequency}`] = data[index]['Avg weight (Kgs) per delivery'];
      }
      delete obj[key];
    }
    else if (key.indexOf('BAQ_YourName') > -1) {
      let data = obj[key];
      const firstName = data['first'];
      const lastName = data['last'];
      obj['BAQ_YourName'] = firstName + ' ' + lastName;
      delete obj[key];
    }
    else if (key.indexOf('BAQ_CompanyLogo') > -1) {
      let data = obj[key];
      if (data.length > 0) {
        obj['BAQ_CompanyLogo'] = data[0];
      }
    }
    else {
      var newkey = this.removeBeforeBAQ(key);
      obj[newkey] = obj[key];
      delete obj[key];
    }
  }

  // Recursive function to flatten the JSON object
  private flattenJSON(obj) {
    for (let key in obj) {
      if (obj.hasOwnProperty(key)) {
        this.processCustomJson(key, obj);
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

  private async _markProcessed(id: any) {
    const query = await this.databaseService.execute("[Forms].[spFormResponse_MarkProcessed]", [
      { name: "id", type: mssql.TYPES.Int, value: id }
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

  public async processBlueAwardForm(response: any) {
    try { // Blue Form will be submitted through direct, RJM digital and Silver App in Jotform
      const jsonResponseData = JSON.parse(response.data);
      // Flatten the JSON object
      const jsonObj = this.flattenJSON(JSON.parse(response.data));

      let arrBlueAwardFormsArr = [];
      Object.keys(jsonObj).forEach((key) => {
        let arrBlueAwardForms = {};
        arrBlueAwardForms['key'] = key;
        arrBlueAwardForms['value'] = jsonObj[key];
        arrBlueAwardForms['submissionId'] = response.submissionId;
        arrBlueAwardForms['dataType'] = typeof (jsonObj[key]);
        arrBlueAwardFormsArr.push(arrBlueAwardForms);
      });

      let processFormData = true;
      if(process.env.CLICKUP_CREATE_BAQTASK == "1") {

        const res = await this.processAwardForm(jsonObj, response, jsonResponseData);
        if(res != ProcessingResponse.success) {
          processFormData = false;
          return res;
        }
      }
      else 
        console.log('processBlueAwardForm', 'CLIKCUP_CREATE_BAQTASK is not enabled');

      if(processFormData) {
        const awardType = this.getAwardType(jsonObj, jsonResponseData);
        //if(awardType == AwardType.APP_GOLD || awardType == AwardType.APP_SILVER)  
        if(awardType == AwardType.APP_SILVER)  
        {
          // Set BAQ_uniqueId custom field value from manually created Certification task to BAQ_uniqueId as Form value
          const existingUniqueId = await this._getBAQUniqueIdfromEmail(jsonObj.BAQ_Email);
          if(existingUniqueId?.value != null && existingUniqueId.value != jsonObj.BAQ_uniqueId) {
            arrBlueAwardFormsArr.forEach(item => {
              if (item.key === "BAQ_uniqueId") {
                item.value = existingUniqueId.value;
              }
            });
          }
          if(existingUniqueId?.value == null) { 
            // If BAQ uniqueId is not set in Certification task, then set it in BAQ uniqueId custom field
            await this.clickupService.setTaskCustomFieldValue(existingUniqueId.taskId, "BAQ uniqueId", jsonObj.BAQ_uniqueId);
            await this.clickupService.setTaskCustomFieldValueInDB(existingUniqueId.taskId, "BAQ uniqueId", jsonObj.BAQ_uniqueId);
          }
        }

        await this._processItemsInBatches(arrBlueAwardFormsArr, 50, this.addBlueAwardQuestionnaire.bind(this));

        //if(awardType != AwardType.APP_GOLD && awardType != AwardType.APP_SILVER) 
        if(awardType != AwardType.APP_SILVER) 
        {
          // Add to Power BI export queue
          await this.addToPowerBIExport(response.submissionId, jsonObj.BAQ_Email, jsonObj.BAQ_CompanyName, 'Blue Award');
        }
        return ProcessingResponse.success;
      }
      else
        return ProcessingResponse.error;
    } catch (e) {
      console.error('processBlueAwardForm', e);
      return ProcessingResponse.error;
    }
  }

  public async processGoldAwardForm(response: any) {
    try { // Gold Form will be submitted through Gold and Platinum App in Jotform
      const jsonResponseData = JSON.parse(response.data);
      // Flatten the JSON object
      const jsonObj = this.flattenJSON(JSON.parse(response.data));

      let arrGoldAwardFormsArr = [];
      Object.keys(jsonObj).forEach((key) => {
        let arrGoldAwardForms = {};
        arrGoldAwardForms['key'] = key;
        arrGoldAwardForms['value'] = jsonObj[key];
        arrGoldAwardForms['submissionId'] = response.submissionId;
        arrGoldAwardForms['dataType'] = typeof (jsonObj[key]);
        arrGoldAwardFormsArr.push(arrGoldAwardForms);
      });

      const totalOfficeHeadCount = this._processOfficeStaffItemiseInput(jsonObj.BAQ_SiteStaff);
      arrGoldAwardFormsArr.forEach(item => {
        if (item.key === "BAQ_OfficeHeadcount") {
          item.value = totalOfficeHeadCount;
        }
      });

      let processFormData = true;
      if(process.env.CLICKUP_CREATE_BAQTASK == "1") {
        const res = await this.processAwardForm(jsonObj, response, jsonResponseData);
        if(res != ProcessingResponse.success) {
          processFormData = false;
          return res;
        }
      }
      else 
        console.log('processGoldAwardForm', 'CLIKCUP_CREATE_BAQTASK is not enabled');

      if(processFormData) {

        // Set BAQ_uniqueId custom field value from manually created Certification task to BAQ_uniqueId as Form value
        const existingUniqueId = await this._getBAQUniqueIdfromEmail(jsonObj.BAQ_Email);
        if(existingUniqueId?.value != null && existingUniqueId.value != jsonObj.BAQ_uniqueId) {
          arrGoldAwardFormsArr.forEach(item => {
            if (item.key === "BAQ_uniqueId") {
              item.value = existingUniqueId.value;
            }
          });
        }
        if (existingUniqueId) {
          if (existingUniqueId?.value == null) {
            // If BAQ uniqueId is not set in Certification task, then set it in BAQ uniqueId custom field
            await this.clickupService.setTaskCustomFieldValue(existingUniqueId.taskId, "BAQ uniqueId", jsonObj.BAQ_uniqueId);
            await this.clickupService.setTaskCustomFieldValueInDB(existingUniqueId.taskId, "BAQ uniqueId", jsonObj.BAQ_uniqueId);
          }
        }
        await this._processItemsInBatches(arrGoldAwardFormsArr, 50, this.addGoldAwardQuestionnaire.bind(this));
        return ProcessingResponse.success;
      }
      else
        return ProcessingResponse.error;
    } catch (e) {
      console.error('processGoldAwardForm', e);
      return ProcessingResponse.error;
    }
  }

  public async _createPersonTask(listName: string, jsonObj: any, submissionId: string, buildDate: any) {
    try {
      const nameParts = jsonObj.BAQ_YourName.trim().split(" ");
      const lastName = nameParts.length > 1 ? nameParts[nameParts.length - 1] : "";
      const firstName = jsonObj.BAQ_YourName.replace(lastName, "").trim();

      const personCF = [
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Last Contacted Date"),
          value: buildDate
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Product"),
          value: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.Product, "Blue Award") ?? "Blue Award",
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Email"),
          value: jsonObj.BAQ_Email
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Mobile/Phone Number"),
          value: jsonObj.BAQ_Phone?.area ? (jsonObj.BAQ_Phone.area + " " + jsonObj.BAQ_Phone.phone).trim() : jsonObj.BAQ_Phone
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Company Name"),
          value: jsonObj.BAQ_CompanyName
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "First Name"),
          value: firstName
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Surname"),
          value: lastName
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Contact Title"),
          value: jsonObj.BAQ_JobTitle
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Created by API"),
          value: '1'
        },
      ];
      const personTaskResponse = await this.clickupService.createTaskCF(jsonObj.BAQ_YourName, submissionId, 'ACTIVE CUSTOMER', personCF,
        parseInt(this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.ListId, listName)));

      if (!personTaskResponse?.id)
        console.error('_createPersonTask', personTaskResponse);

      return personTaskResponse;

    } catch (e) {
      console.error('_createPersonTask', e)
      return ProcessingResponse.error;
    }
  }
  public async _createCompanyTask(listName: string, jsonObj: any, buildDate: any) {
    console.log(jsonObj);
    try {
      let companyCF = [
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Contract Start"),
          value: buildDate
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Industry"),
          value: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.Industry, jsonObj.BAQ_CompanyIndustry) ?? jsonObj.BAQ_CompanyIndustry,
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Company Revenue"),
          value: jsonObj.BAQ_CompanyRevenue
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Website"),
          value: jsonObj.BAQ_CompanyWebsite
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Mobile/Phone Number"),
          value: jsonObj.BAQ_Phone?.area ? (jsonObj.BAQ_Phone.area + " " + jsonObj.BAQ_Phone.phone).trim() : jsonObj.BAQ_Phone
        },
        {
          id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, "Created by API"),
          value: '1'
        },
      ];
      const companyTaskResponse = await this.clickupService.createTaskCF(jsonObj.BAQ_CompanyName, jsonObj.BAQ_CompanyDescription ?? '', 'ACTIVE', companyCF,
        parseInt(this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.ListId, listName)));

      if (!companyTaskResponse?.id)
        console.error('_createCompanyTask', companyTaskResponse);

      return companyTaskResponse;
    } catch (e) {
      console.error('_createCompanyTask', e)
      return ProcessingResponse.error;
    }
  }
  private async _createCertificationTask(listName: string, productName: string, status: string, jsonObj: any,
                                         submissionId: string, jotFormId: string, buildDate: any, tags?: string[])
  {
    try {
      const certCF = [
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Contract Start"), 
          value: buildDate
        },
        { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Product"), 
          value: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.Product, productName)??"Blue Award",
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
        parseInt(this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.ListId, listName)), tags);

      if(!certTaskResponse?.id)
        console.error('_createCertificationTask', certTaskResponse);

      return certTaskResponse;
    } catch (e) {
      console.error('_createCertificationTask', e)
      return ProcessingResponse.error;
    }
  }
  public async processResponse(response: any) {
    try {
      const formId = response.formId;
      const formName = response.formName;
      const entityTypeId = response.entityTypeId;
      const jsonData = response.data;
      const jotformSubmissionId = response.submissionId;
      const jotformId = response.jotFormId;
      const data = typeof jsonData == "string" ? JSON.parse(jsonData) : jsonData;
      const questions = await this._getFormQuestions(formId);

      let entityId;
      if(entityTypeId == 4 && formId != 11) 
        entityId = await this._getEntityIdByEmail(formName, data, questions, jotformId, jotformSubmissionId);
      else if(entityTypeId == 4 && formId == 11) // For Commuting & Homeworking, getEntityIdbyBAQUniqueId 
        entityId = await this._getEntityIdByUniqueId(data, questions);

      if (!entityId) {
        return ProcessingResponse.entity_not_found;
      }

      const submissionId = await this._saveSubmission(data, questions, jotformSubmissionId, entityId, entityTypeId, formId);
      if (!submissionId) {
        return ProcessingResponse.submission_not_saved;;
      }

      //Prepare array of response data and that will be stored in db as per column config.
      await this._saveQuestionResponse(questions, data, submissionId);

      const { currency, country } = await this._selectCountryCurrencyByPersonEmail(questions, data);

      //Set reporting frequency
      let reportingFrequency = this._getReportingFrequency(questions, data);

      //Set month if monthly submission.
      let month = undefined;
      if (reportingFrequency == ReportingFrequency.monthly) {
        const monthQuestion: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.month);
        month = monthQuestion ? this._getMonthNumber(data[monthQuestion.reference]) : undefined;
      }

      //Global Conversion Factor
      let conversionFactorColumn: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.conversionFactor);
      let conversionFactorG = conversionFactorColumn ? data[conversionFactorColumn.reference] : 1;
      conversionFactorG = conversionFactorG ? conversionFactorG : 1;

      //Global Data Unit
      let dataUnitColumn: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.dataUnit);
      let dataUnitG = dataUnitColumn ? data[dataUnitColumn.reference] : undefined;

      // For Electricity form
      const greenTariffPercent = this._getGreenTariffPercent(questions, data);

      //Process all activity columns
      const activityQuestions: Question[] = questions.filter((x: Question) => x.emissionActivities);
      for (let question of activityQuestions) {
        //console.log("Question: " + question.reference + " " + question.id+" "+question.displayText);

        let rawData = data[question.reference] && typeof data[question.reference] == 'string' ? JSON.parse(data[question.reference]) : data[question.reference];
        // Check for null/undefined/zero length array/empty string/empty object
        if (this.isEmpty(rawData)) {
            continue;
        }

        //Properties can have dataUnit or conversion factor questions.
        const properties = question.properties ? JSON.parse(question.properties) : undefined;

        const emissionActivities = typeof question.emissionActivities == 'string' ? JSON.parse(question.emissionActivities) : question.emissionActivities;
        if (!emissionActivities) {
          console.log('No emission activity configured for questionId : ' + question.id)
          continue;
        }

        // Override Data Unit and Conversion Factor for a question
        let conversionFactor = conversionFactorG;
        let dataUnit = dataUnitG;
        let chargingPercentAtWorkPlace = null;

        if (properties && properties.linkedQuestions) {
          dataUnitColumn = properties.linkedQuestions?.find((x: Question) => x.questionTypeId == QuestionType.dataUnit);
          dataUnit = dataUnitColumn ? data[dataUnitColumn.reference.trim()] : dataUnit;

          //TODO Check this for business travel
          conversionFactorColumn = properties.linkedQuestions.find((x: Question) => x.questionTypeId == QuestionType.conversionFactor);
          conversionFactor = conversionFactorColumn ? data[conversionFactorColumn.reference.trim()] : conversionFactorG;

          const chargingPercentAtWorkPlaceColumn = properties.linkedQuestions.find((x: Question) => x.questionTypeId == QuestionType.chargingPercentAtWorkPlace);
          chargingPercentAtWorkPlace = chargingPercentAtWorkPlaceColumn ? data[chargingPercentAtWorkPlaceColumn.reference.trim()] : null;
        }

        // For Green Tariff percentage in Electricity, update conversion factor
        if (greenTariffPercent) {
          conversionFactor = this._getRemainingValue(conversionFactor, greenTariffPercent);
        }
        // For the conversion calculation, e.g. Amount to Litre of petrol/diesel, Amount to USD etc
        let conversionInfo:ConversionInfo = null; 
        if (properties && properties.conversion) {
          conversionInfo = {
              conversionType: properties.conversion,
              country: country,
              currency: currency,
            }
        }

        if (question.questionTypeId == QuestionType.userInput_month && reportingFrequency == ReportingFrequency.monthly) {
          for (let queProp of emissionActivities) {
            const monthlyData = (Object.keys(rawData).length > queProp.rowNo || rawData.length > queProp.rowNo) ? rawData[queProp.rowNo][queProp.columnNo] : 0;
            await this._processSubmissionByMonth(question.id, monthlyData, entityId, entityTypeId, submissionId, queProp.emissionActivityId, month, conversionFactor, reportingFrequency, dataUnit, conversionInfo, chargingPercentAtWorkPlace);
          }
        } else if (question.questionTypeId == QuestionType.userInput_annul_by_month && reportingFrequency == ReportingFrequency.annualised_monthly) {
          for (let queProp of emissionActivities) {
            await this._processAnnualSubmissionByMonths(question.id, rawData, queProp, entityId, entityTypeId, submissionId, question.emissionActivityId, conversionFactor, reportingFrequency, dataUnit, conversionInfo, chargingPercentAtWorkPlace);
          }
        } else if (question.questionTypeId == QuestionType.userInput_annual && (reportingFrequency == ReportingFrequency.annualised || entityTypeId != 1)) {
          for (let annualProp of emissionActivities) {
            const annualisedData = (Object.keys(rawData).length > annualProp.rowNo || rawData.length > annualProp.rowNo) ? rawData[annualProp.rowNo][annualProp.columnNo] : 0;
            await this._processSubmissionByAnnual(question.id, annualisedData, entityId, entityTypeId, submissionId, annualProp.emissionActivityId, month, conversionFactor, reportingFrequency, dataUnit, conversionInfo, chargingPercentAtWorkPlace);
          }
        } else if (question.questionTypeId == QuestionType.userInput_annual_JanToJun && reportingFrequency == ReportingFrequency.annualised_monthly) {
          for (let annualProp of emissionActivities) {
            const annualisedData = (Object.keys(rawData).length > annualProp.rowNo || rawData.length > annualProp.rowNo) ? rawData[annualProp.rowNo] : [];
            await this._processAnnualSubmissionByJanToJun(question.id, annualisedData, entityId, entityTypeId, submissionId, annualProp.emissionActivityId, conversionFactor, reportingFrequency, dataUnit, conversionInfo);
          }
        } else if (question.questionTypeId == QuestionType.userInput_annual_JulToDec && reportingFrequency == ReportingFrequency.annualised_monthly) {
          for (let annualProp of emissionActivities) {
            const annualisedData = (Object.keys(rawData).length > annualProp.rowNo || rawData.length > annualProp.rowNo) ? rawData[annualProp.rowNo] : [];
            await this._processAnnualSubmissionByJulToDec(question.id, annualisedData, entityId, entityTypeId, submissionId, annualProp.emissionActivityId, conversionFactor, reportingFrequency, dataUnit, conversionInfo);
          }
        } else if (question.questionTypeId == QuestionType.userInput_textbox) {
          const userInput = data[question.reference];
          await this._processSubmissionByAnnual(question.id, userInput, entityId, entityTypeId, submissionId, emissionActivities[0]?.emissionActivityId, month, conversionFactor, reportingFrequency, dataUnit, conversionInfo, chargingPercentAtWorkPlace);
        } else if (question.questionTypeId == QuestionType.deliveries_itemise_input) {
          const userInput = data[question.reference];
          await this._processDeliveriesItemiseInput(question.id, userInput, entityId, entityTypeId, submissionId, properties, month, conversionFactor, reportingFrequency, dataUnit, conversionInfo);
        }
        else if (question.questionTypeId == QuestionType.otherFuel_itemise_input) {
          const userInput = data[question.reference];
          await this._processOtherFuelItemiseInput(question.id, userInput, entityId, entityTypeId, submissionId, properties, month, conversionFactor, reportingFrequency, dataUnit);
        }
        else if (question.questionTypeId == QuestionType.hotelStay_itemise_input) {
          const userInput = data[question.reference];
          await this._processHotelStayItemiseInput(question.id, userInput, entityId, entityTypeId, submissionId, properties, month, conversionFactor, reportingFrequency, dataUnit);
        }
        else if(question.questionTypeId == QuestionType.flight_domestic_itemise_input) {
          const userInput = data[question.reference];
          await this._processFlightDomesticItemiseInput(question.id, userInput, entityId, entityTypeId, submissionId, emissionActivities[0]?.emissionActivityId, conversionFactor, reportingFrequency, dataUnit);
        }
        else if (question.questionTypeId == QuestionType.flight_short_haul_itemise_input) {
          const userInput = data[question.reference];
          await this._processFlightShortHaulItemiseInput(question.id, userInput, entityId, entityTypeId, submissionId, properties, month, conversionFactor, reportingFrequency, dataUnit);
        }
        else if (question.questionTypeId == QuestionType.flight_long_haul_itemise_input) {
          const userInput = data[question.reference];
          await this._processFlightLongHaulItemiseInput(question.id, userInput, entityId, entityTypeId, submissionId, properties, month, conversionFactor, reportingFrequency, dataUnit);
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

  private async _saveSubmission(data: any, questions: Question[], extSubmissionId: number, entityId: number, entityTypeId: number, formId: number): Promise<number> {
    const submissionDate = data['buildDate'] ? Math.round(+data['buildDate'] / 1000) : undefined;
    const managementBasedDecisionColumn: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.ManagementBasedDecision);
    const managementBasedDecision = managementBasedDecisionColumn ? data[managementBasedDecisionColumn.reference] : 0;
    const optInPreferenceColumn: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.optInPreference);
    const optedIn = optInPreferenceColumn ? data[optInPreferenceColumn.reference] : 1;

    //Create submission record.
    const submissionId = await this._createSubmission(extSubmissionId, submissionDate, managementBasedDecision, optedIn, entityId, entityTypeId, formId);
    if (!submissionId) {
      console.log('Submission record not created');
      return 0
    }
    return submissionId;
  }

  private _getReportingFrequency(questions: any, data: any) {
    let reportingFrequency = ReportingFrequency.unknown;
    let freqQuestion: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.reportingFrequency);
    if (freqQuestion) {
      if (data[freqQuestion.reference] == "2") {
        reportingFrequency = ReportingFrequency.monthly;
      } else if (data[freqQuestion.reference] == "3") {
        reportingFrequency = ReportingFrequency.annualised_monthly;
      } else if (data[freqQuestion.reference] == "4") {
        reportingFrequency = ReportingFrequency.annualised;
      }
    }
    return reportingFrequency;
  }

  private _getGreenTariffPercent(questions: any, data: any) {
    let tariffQuestion: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.electricity_tariff_itemise_input);
    if (tariffQuestion) {
      const rawValue = data[tariffQuestion.reference];
      if (!rawValue) return null;

      let parsed;
      try {
          parsed = JSON.parse(rawValue);
      } catch (e) {
          return null;
      }

      if (Array.isArray(parsed) && parsed.length > 0) {
          if (parsed[0]["Green tariff"] && parsed[0]["Green tariff"].toLowerCase() == "yes")
            return parsed[0]["Percentage of tariff"] || null;
          else
            return null;
      }
      return null;
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
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];

    const monthIndex = months.findIndex((month) => month.toLowerCase() === monthName.toLowerCase());

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
  private async _selectCountryCurrencyByPersonEmail(questions: Question[], data: any): Promise<{ currency: any; country: any }> {
    const entityColumn: Question = questions.find((x: Question) => x.questionTypeId == QuestionType.emailEntityReference);
    if (!entityColumn) {
      console.log('No entityColumn available');
      return { currency: null, country: null };
    }
    const email = data[entityColumn.reference];

    const query = await this.databaseService.execute("Dimension.spCurrency_SelectByPersonEmail", [
      { name: "email", type: mssql.TYPES.NVarChar, value: email },
    ]);
    const results = query.singleResult;
    return { currency: results?.currency ?? null, country: results?.country ?? null };
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

  private async _createSubmission(extSubmissionId: number, submissionDate: number, managementBasedDecision: number, optedIn: number, entityId: number, entityTypeId: number, formId: number) {
    const query = await this.databaseService.execute("[Forms].[spForm_SaveSubmission]", [
      { name: "extSubmissionId", type: mssql.TYPES.NVarChar, value: extSubmissionId },
      { name: "submissionDate", type: mssql.TYPES.BigInt, value: submissionDate },
      { name: "managementBasedDecision", type: mssql.TYPES.Int, value: managementBasedDecision },
      { name: "optedIn", type: mssql.TYPES.Int, value: optedIn },
      { name: "entityId", type: mssql.TYPES.Int, value: entityId },
      { name: "entityTypeId", type: mssql.TYPES.Int, value: entityTypeId },
      { name: "formId", type: mssql.TYPES.Int, value: formId }
    ]);
    const results = query.singleResult;
    return results?.id;
  }

  private async _processSubmissionByMonth(questionId: number, userInput: number, entityId: number, entityTypeId: number,
    submissionId: number, emissionActivityId: number, month: number, conversionFactor: number,
    reportingFrequencyId: number, dataUnit: string, conversionInfo: any, chargingPercentAtWorkPlace: number|null) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for month ${month} for ${entityId}`);
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
    if(chargingPercentAtWorkPlace) { // remove % charged at work place from Conversion Factor
      conversionFactor = this._getRemainingValue(conversionFactor, chargingPercentAtWorkPlace); // userInput * ((100 - chargingPercentAtWorkPlace) / 100);
    }

    const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, emissionActivityId, userInput, month, conversionFactor,
                                            reportingFrequencyId, dataUnit, false, false, questionId);
    await this._processEmissionctivity(clsEmission);
  }

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
    if (arrMonths.length < 12) {
      //TODO - add this in audit table
      console.log("Less number of months found for annualised (monthly) option for " + entityId);
    }

    let month = 0;
    for (let monthlyInput of arrMonths) {
      let _conversionFactor = conversionFactor; // reset to original for each month

      month++;
      if (typeof monthlyInput == 'object') {
        monthlyInput = Object.values(monthlyInput);
      }
      let userInput = monthlyInput.length > queProp.columnNo ? monthlyInput[queProp.columnNo] : undefined;
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

      const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, queProp.emissionActivityId, userInput, month,
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

  private async _processOtherFuelItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, questionProperties: any, month: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for other for ${entityId}`);
      return;
    }

    const data = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
    const typeOfFuels = questionProperties?.fuelConfigurations ?? [];

    if (!typeOfFuels || typeOfFuels.length == 0) {
      console.log(`Fuel emission data is not configured in question properties.`);
      return;
    }

    typeOfFuels?.forEach((fuel: any) => {
      const fuelData = data?.filter((x: any) => x['Fuel Type'] == fuel['Fuel Type'] && x['Unit'] == fuel.Unit);
      if (fuelData && fuelData.length > 0) {
        fuelData.forEach(async (fuelItem: any) => {
          const usage = fuelItem.Usage;
          dataUnit = fuelItem.Unit;
          conversionFactor = 1;
          if (usage && !isNaN(+usage)) {
            const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, fuel.emissionActivityId, usage, month, conversionFactor,
                                                    reportingFrequencyId, dataUnit, false, false, questionId);
            await this._processEmissionctivity(clsEmission);
          }
        });
      }
    });
  }

  private async _processDeliveriesItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, questionProperties: any,
    month: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string, conversionInfo: any) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for deliveries for ${entityId}`);
      return;
    }

    const data = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
    const typeOfVehicles = questionProperties?.vehicleEmissions ?? [];

    if (!typeOfVehicles || typeOfVehicles.length == 0) {
      console.log(`Vehicle emission data is not configured in question properties.`);
      return;
    }

    if(conversionInfo) {
      const convertedValue = await this._convertTo(conversionInfo, 1);
      if (convertedValue) {
        userInput = convertedValue.outputValue;
        //dataUnit = convertedValue.dataUnit || dataUnit;
        conversionFactor = convertedValue.conversionFactor || conversionFactor;
      }
    }

    typeOfVehicles?.forEach((vehicle: any) => {
      const vehicleData = data?.filter((x: any) => x['Type of Vehicle'] == vehicle.type);
      if (vehicleData && vehicleData.length > 0) {
        vehicleData.forEach(async (vehicleItem: any) => {
          const distance = vehicleItem['Distance (km)'];
          const weight = vehicleItem['Weight (kg)'];
          const spendAmount = vehicleItem['Spend amount'];
          if (distance && weight && !isNaN(+distance) && !isNaN(+weight)) {
            const vehicleTotal = distance * weight;
            const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, vehicle.emissionActivityId, vehicleTotal, month,
                                                    conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
            await this._processEmissionctivity(clsEmission);
          }
          else if(spendAmount && !isNaN(+spendAmount)) {
            const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, vehicle.spendAmountEmissionActivityId, spendAmount,
                                                    month, conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
            await this._processEmissionctivity(clsEmission);
          }
        });
      }
    });
  }

  private async _processHotelStayItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, questionProperties: any, month: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for Nights Stayed for ${entityId}`);
      return;
    }

    const data = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
    const countryOfHotels = questionProperties?.hotelEmissions ?? [];

    if (!countryOfHotels || countryOfHotels.length == 0) {
      console.log(`hotel emission data is not configured in question properties.`);
      return;
    }

    countryOfHotels?.forEach((hotel: any) => {
      const hotelData = data?.filter((x: any) => x['Country'] == hotel.country);
      if (hotelData && hotelData.length > 0) {
        hotelData.forEach(async (hotelItem: any) => {
          const nights = hotelItem['Nights Stayed'];
          //const persons = hotelItem['No of People']; // not used as of now in template excelsheet
          const rooms = hotelItem['No of Rooms']; 
          if (nights && !isNaN(+nights) && rooms && !isNaN(rooms)) {
            const hotelTotal = nights * rooms; // as per Excelsheet calculation is (Nights * Rooms) 
            const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, hotel.emissionActivityId, hotelTotal, month,
                                                    conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
            await this._processEmissionctivity(clsEmission);
          }
        });
      }
    });
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
      dataUnit = "Kilometers (KM)";
      if (flightData && flightData.length > 0) {
        //flightData.forEach(async (flightItem: any) => { // << forEach doesn't wait for await
        for (const flightItem of flightData) {
          const depAirport = flightItem['Dep. Airport'];
          const arrAirport = flightItem['Arr. Airport'];

          if (!depAirport || !arrAirport) {
            console.log(`No Dep. or Arr. Airport found`);
            continue;
          }
          const distance = await this._getFlightDistance(depAirport, arrAirport);
          if (!distance) {
            console.log(`No distance found for ${depAirport} to ${arrAirport}`);
            continue;
          }

          const returnFlight = flightItem['Return flight'];
          const flightCount = flightItem['No of Flights']; 
          const month = flightItem['Month']; 
          const monthNumber = month ? this._getMonthNumber(month) : null;

          const flightDistance = distance.distanceKms;
          const totalDistance = (returnFlight ? flightDistance * 2 : flightDistance) * (!flightCount ? 1 : flightCount);
          const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, emissionActivityId, totalDistance, monthNumber,
                                                  conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
          await this._processEmissionctivity(clsEmission);
        }//);
      }
  }
  private async _processFlightShortHaulItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, questionProperties: any, month: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for Nights Stayed for ${entityId}`);
      return;
    }

    const data = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
    const flightClasses = questionProperties?.flightEmissions ?? [];

    if (!flightClasses || flightClasses.length == 0) {
      console.log(`flight emission data is not configured in question properties.`);
      return;
    }
    dataUnit = "Kilometers (KM)";
    //flightClasses?.forEach((flightClass: any) => {
    for(const flightClass of flightClasses){
      const flightData = data?.filter((x: any) => x['Short-Haul'] == flightClass.type);
      if (flightData && flightData.length > 0) {
        //flightData.forEach(async (flightItem: any) => {
        for (const flightItem of flightData) {
          const depAirport = flightItem['Dep. Airport'];
          const arrAirport = flightItem['Arr. Airport'];

          if (!depAirport || !arrAirport) {
            console.log(`No Dep. or Arr. Airport found`);
            continue;
          }
          const distance = await this._getFlightDistance(depAirport, arrAirport);
          if (!distance) {
            console.log(`No distance found for ${depAirport} to ${arrAirport}`);
            continue;
          }

          const returnFlight = flightItem['Return flight'];
          const flightCount = flightItem['No of Flights'];
          const month = flightItem['Month'];
          const monthNumber = month ? this._getMonthNumber(month) : null;

          const flightDistance = distance.distanceKms;
          const totalDistance = (returnFlight ? flightDistance * 2 : flightDistance) * (!flightCount ? 1 : flightCount);
          const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, flightClass.emissionActivityId, totalDistance,
                                              monthNumber, conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
          await this._processEmissionctivity(clsEmission);
        }//);
      }
    }//);
  }

  private async _processFlightLongHaulItemiseInput(questionId: number, userInput: any, entityId: number, entityTypeId: number, submissionId: number, questionProperties: any, month: number, conversionFactor: number, reportingFrequencyId: number, dataUnit: string) {
    if (this.isEmpty(userInput)) {
      //console.log(`No user input found for Nights Stayed for ${entityId}`);
      return;
    }

    const data = typeof userInput == "string" ? JSON.parse(userInput) : userInput;
    const flightClasses = questionProperties?.flightEmissions ?? [];

    if (!flightClasses || flightClasses.length == 0) {
      console.log(`flight emission data is not configured in question properties.`);
      return;
    }
    dataUnit = "Kilometers (KM)";
    //flightClasses?.forEach((flightClass: any) => {
    for(const flightClass of flightClasses){
      const flightData = data?.filter((x: any) => x['Long-Haul'] == flightClass.type);
      if (flightData && flightData.length > 0) {
        //flightData.forEach(async (flightItem: any) => {
        for (const flightItem of flightData) {
          const depAirport = flightItem['Dep. Airport'];
          const arrAirport = flightItem['Arr. Airport'];

          if (!depAirport || !arrAirport) {
            console.log(`No Dep. or Arr. Airport found`);
            continue;
          }
          const distance = await this._getFlightDistance(depAirport, arrAirport);
          if (!distance) {
            console.log(`No distance found for ${depAirport} to ${arrAirport}`);
            continue;
          }

          const returnFlight = flightItem['Return flight'];
          const flightCount = flightItem['No of Flights']; 
          const month = flightItem['Month']; 
          const monthNumber = month ? this._getMonthNumber(month) : null;

          const flightDistance = distance.distanceKms;
          const totalDistance = (returnFlight ? flightDistance * 2 : flightDistance) * (!flightCount ? 1 : flightCount);
          const clsEmission = new EmissionActivity(entityId, entityTypeId, submissionId, flightClass.emissionActivityId, totalDistance,
                                            monthNumber, conversionFactor, reportingFrequencyId, dataUnit, false, false, questionId);
          await this._processEmissionctivity(clsEmission);
        }//);
      }
    } //);
  }
  private async _getFlightDistance(depAirport: string, arrAirport: string): Promise<any> {
      const query = await this.databaseService.execute("Emissions.spGetFlightDistance", [
        { name: "depAirport", type: mssql.TYPES.NVarChar, value: depAirport },
        { name: "arrAirport", type: mssql.TYPES.NVarChar, value: arrAirport },
      ]);
      const result = query.singleResult;
      return result;
  }

  private async _processEmissionctivity(clsEmission: EmissionActivity) {
    //console.log(clsEmission);

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
  
  private getAwardType(jsonObj: any, jsonResponseData: any): AwardType {
    if (jsonObj.BAQ_id.toUpperCase() === "RJM DIGITAL") {
      return AwardType.RJM;
    }
    
    if (jsonObj.BAQ_id.toUpperCase() === "APP" && jsonResponseData?.pwa_id) {
      const pwaIdGold = this.customFieldsConstants.findConstantIdbyName(
        CustomFieldsConstantTypes.JotformAppId,
        "Gold"
      );
      const pwaIdSilver = this.customFieldsConstants.findConstantIdbyName(
        CustomFieldsConstantTypes.JotformAppId,
        "Silver"
      );
      const pwaIdPlatinum = this.customFieldsConstants.findConstantIdbyName(
        CustomFieldsConstantTypes.JotformAppId,
        "Platinum"
      );
      if (jsonResponseData.pwa_id === pwaIdGold) {
        return AwardType.APP_GOLD;
      }
      if (jsonResponseData.pwa_id === pwaIdSilver) {
        return AwardType.APP_SILVER;
      }
      if (jsonResponseData.pwa_id === pwaIdPlatinum) {
        return AwardType.APP_PLATINUM;
      }
    }
    
    return AwardType.DEFAULT;
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
        let tags = null;
        if (jsonObj.BAQ_id.trim().toUpperCase() === "PLATINUM") {
          tags = ["Platinum"];
        }
        const defaultCertTask = await this._createCertificationTask(
          config.listName,
          config.productName,
          config.statusName,
          jsonObj,
          response.submissionId,
          response.jotFormId,
          jsonResponseData.buildDate,
          tags
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
  
  private async createRelationships(result: TaskResult, jsonObj: any): Promise<void> {
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

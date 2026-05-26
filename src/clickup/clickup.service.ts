import { Injectable } from '@nestjs/common';
import fetch from 'node-fetch';
import * as mssql from 'mssql';
import { DatabaseService } from '../database';
import { Task } from './model/task';
import * as FormData from 'form-data';
import * as path from 'path';
import { CustomFieldsConstants } from './customfields-constants';
import * as fs from 'fs';
import { CustomFieldsConstantTypes } from "./customfields-constant-types";
import { ErrorLoggerService } from '../error-logger/error-logger.service';
import { th } from 'date-fns/locale';

@Injectable()
export class ClickUpService {

    constructor(private readonly databaseService: DatabaseService, private customFieldsConstants: CustomFieldsConstants,
        private readonly errorLoggerService: ErrorLoggerService
    ) { }

    private headers = {
        'Authorization': `${process.env.CLICKUP_APIKEY}`,
        'content-type': "application/json"
    }

    public async processConfiguredClickUpTasks() {
        const configurations = await this.getLists();
        for (let i = 0; i < configurations.length; i++) {
            await this.processClickUpTasksV2(configurations[i].listId);
        };
    }

    public async processUpdateDeletedTasks() {
        await this.updateDeletedTasksToDB();
    }

    public async processClickUpTasks(listId: string) {
        const tasks = await this.getTasks(+listId, "true");
        let refinedTasks: Task[] = [];
        for (let i = 0; i < tasks.length; i++) {
            const objTask = new Task();
            objTask.id = tasks[i].id;
            objTask.name = tasks[i].name;
            objTask.description = tasks[i].description;
            objTask.folderId = tasks[i].folder ? tasks[i].folder.id : undefined;
            objTask.listId = tasks[i].list ? tasks[i].list.id : undefined;
            objTask.spaceId = tasks[i].space ? tasks[i].space.id : undefined;
            objTask.status = tasks[i].status ? tasks[i].status?.status : '';
            objTask.createdBy = tasks[i].creator ? tasks[i].creator.id : undefined;
            objTask.startDate = tasks[i].start_date ? Math.round(tasks[i].start_date / 1000) : undefined;
            objTask.dueDate = tasks[i].due_date ? Math.round(tasks[i].due_date / 1000) : undefined;
            objTask.dateCreated = tasks[i].date_created ? Math.round(tasks[i].date_created / 1000) : undefined;;
            objTask.dateUpdated = tasks[i].date_updated ? Math.round(tasks[i].date_updated / 1000) : undefined;;
            objTask.dateDone = tasks[i].date_done ? Math.round(tasks[i].date_done / 1000) : undefined;;
            objTask.isArchived = tasks[i].archived;
            objTask.parentId = tasks[i].parent;
            objTask.status_JSON = tasks[i].status ? JSON.stringify([tasks[i].status]) : undefined;
            objTask.creator_JSON = tasks[i].creator ? JSON.stringify([tasks[i].creator]) : undefined;
            objTask.assignees_JSON = tasks[i].assignees?.length > 0 ? JSON.stringify(tasks[i].assignees) : undefined;
            objTask.customFields_JSON = tasks[i].custom_fields?.length > 0 ? this.setDropdownlistValue(tasks[i].custom_fields) : undefined;
            refinedTasks.push(objTask);
        }

        await this._processItemsInBatches(refinedTasks, 20, this.addTasksToDB.bind(this));

        return 1;
    }
    
    public async processClickUpTasksV2(listId: string) {
        const fieldsToKeep = this.customFieldsConstants.getCustomFieldstoKeep();
        console.log("processClickUpTasksV2 ", listId," ", new Date().toLocaleString());

        const clickupTasks = await this.getTasks(+listId, "true","false","false");
        let refinedTasks: Task[] = [];
        let creators: any[] = [];
        let assignees: any[] = [];
        let taskAssignees: any[] = [];
        let taskCustomFields: any[] = [];

        //For CustomFields, as clickup api filter date_updated_gt & date_updated_lt not working, we are filtering last 24 hours tasks here.
        const last24Hours = Math.round(new Date().getTime() / 1000)- (86400); // last 24 hours
        const tasks = clickupTasks.filter(task => task.date_updated? Math.round(task.date_updated / 1000) >= last24Hours : 0);
        
        for (let i = 0; i < tasks.length; i++) {
            const objTask = new Task();
            objTask.id = tasks[i].id;
            objTask.name = tasks[i].name;
            objTask.description = tasks[i].description;
            objTask.folderId = tasks[i].folder ? tasks[i].folder.id : undefined;
            objTask.listId = tasks[i].list ? tasks[i].list.id : undefined;
            objTask.spaceId = tasks[i].space ? tasks[i].space.id : undefined;
            objTask.status = tasks[i].status ? tasks[i].status?.status : '';
            objTask.createdBy = tasks[i].creator ? tasks[i].creator.id : undefined;
            objTask.startDate = tasks[i].start_date ? Math.round(tasks[i].start_date / 1000) : undefined;
            objTask.dueDate = tasks[i].due_date ? Math.round(tasks[i].due_date / 1000) : undefined;
            objTask.dateCreated = tasks[i].date_created ? Math.round(tasks[i].date_created / 1000) : undefined;;
            objTask.dateUpdated = tasks[i].date_updated ? Math.round(tasks[i].date_updated / 1000) : undefined;;
            objTask.dateDone = tasks[i].date_done ? Math.round(tasks[i].date_done / 1000) : undefined;;
            objTask.isArchived = tasks[i].archived;
            objTask.parentId = tasks[i].parent;

            refinedTasks.push(objTask);

            if(tasks[i].creator)
                creators.push(JSON.stringify([tasks[i].creator]));
            if(tasks[i].assignees?.length > 0)
            {    
                taskAssignees.push({ taskId: tasks[i].id, assignees_JSON: tasks[i].assignees });
                assignees.push(JSON.stringify(tasks[i].assignees));  
            }
            if(tasks[i].custom_fields?.length > 0)
            {    
                const result = tasks[i].custom_fields.filter(field => fieldsToKeep.includes(field.name));
                taskCustomFields.push({ taskId: tasks[i].id, customFields_JSON: this.setDropdownlistValueV2(result) });
            }
        }      

        //This will process only tasks now
        console.log("AddTasksToDB ", refinedTasks.length, new Date().toLocaleString());
        await this._processItemsInBatches(refinedTasks, 50, this.clickUpJob_AddTasksToDB.bind(this));
        console.log("AddAssigneesToDB ", taskAssignees.length, new Date().toLocaleString());
        await this._processItemsInBatches(taskAssignees, 50, this.clickUpJob_AddAssigneesToDB.bind(this));
        console.log("AddCustomFieldsToDB ", taskCustomFields.length, new Date().toLocaleString());
        await this._processItemsInBatches(taskCustomFields, 50, this.clickUpJob_AddCustomFieldsToDB.bind(this));
        console.log("AddCreatorsToDB ", creators.length, new Date().toLocaleString());
        await this._processItemsInBatches(creators, 50, this.clickUpJob_AddUsersToDB.bind(this));
        console.log("AddAssigneesToDB ", assignees.length, new Date().toLocaleString());
        await this._processItemsInBatches(assignees, 50, this.clickUpJob_AddUsersToDB.bind(this));

        console.log("processClickUpTasksV2 End ", new Date().toLocaleString());
        return 1;
    }

    public async processTasksDirectToDB(tasks: any) {
        //const tasks = await this.getTasks(+listId, "true");
        let refinedTasks: Task[] = [];
        for (let i = 0; i < tasks.length; i++) {
            const objTask = new Task();
            objTask.id = tasks[i].id;
            objTask.name = tasks[i].name;
            objTask.description = tasks[i].description;
            objTask.folderId = tasks[i].folder ? tasks[i].folder.id : undefined;
            objTask.listId = tasks[i].list ? tasks[i].list.id : undefined;
            objTask.spaceId = tasks[i].space ? tasks[i].space.id : undefined;
            objTask.status = tasks[i].status ? tasks[i].status?.status : '';
            objTask.createdBy = tasks[i].creator ? tasks[i].creator.id : undefined;
            objTask.startDate = tasks[i].start_date ? Math.round(tasks[i].start_date / 1000) : undefined;
            objTask.dueDate = tasks[i].due_date ? Math.round(tasks[i].due_date / 1000) : undefined;
            objTask.dateCreated = tasks[i].date_created ? Math.round(tasks[i].date_created / 1000) : undefined;;
            objTask.dateUpdated = tasks[i].date_updated ? Math.round(tasks[i].date_updated / 1000) : undefined;;
            objTask.dateDone = tasks[i].date_done ? Math.round(tasks[i].date_done / 1000) : undefined;;
            objTask.isArchived = tasks[i].archived;
            objTask.parentId = tasks[i].parent;
            objTask.status_JSON = tasks[i].status ? JSON.stringify([tasks[i].status]) : undefined;
            objTask.creator_JSON = tasks[i].creator ? JSON.stringify([tasks[i].creator]) : undefined;
            objTask.assignees_JSON = tasks[i].assignees?.length > 0 ? JSON.stringify(tasks[i].assignees) : undefined;
            objTask.customFields_JSON = tasks[i].custom_fields?.length > 0 ? this.setDropdownlistValue(tasks[i].custom_fields) : undefined;
            refinedTasks.push(objTask);
        }

        await this.addTasksToDB(refinedTasks);
        //await this._processItemsInBatches(refinedTasks, 20, this.addTasksToDB.bind(this));

        return 1;
    }

    private setDropdownlistValue(custom_fields: any[]) {
        for (let index = 0; index < custom_fields.length; index++) {
            const element = custom_fields[index];
            if (element.type == 'drop_down' && element.value) {
                let currentValue =  this.getValueFromTypesConfig(element.type_config.options, element.value);
                element.value = currentValue;
            }
            else if (element.type == 'date' && element.value) {
                element.value = element.value /1000;
            }
        }
        return JSON.stringify(custom_fields)
    }

    private setDropdownlistValueV2(custom_fields: any[]) {
        for (let index = 0; index < custom_fields.length; index++) {
            const element = custom_fields[index];
            if (element.type == 'drop_down' && element.value) {
                let currentValue =  this.getValueFromTypesConfig(element.type_config.options, element.value);
                element.value = currentValue;
            }
            else if (element.type == 'date' && element.value) {
                element.value = element.value /1000;
            }
        }
        return custom_fields;
    }

    private getValueFromTypesConfig(typeConfigs: any[], value: number) {
        let data = typeConfigs.find(x => x.orderindex == value);
        return data?.name;
    }

    //Get all parent tasks from db.
    public async processAllParentTasksStatusHistory() {
        const parentTasks = await this.getAllParentTasksLists();
        this.processTasksStatusHistory(parentTasks);
    }

    //we will loop through tasks and process status history against each task.
    public async processTasksStatusHistory(refinedTasks: Task[]) {
        for (let index = 0; index < refinedTasks.length; index++) {
            await this.processStatusHistory(refinedTasks[index].id);
            await this.sleep(500);
        }
    }

    public async processStatusHistory(taskId: string) {
        const taskstatusHistory = await this.getStatusHistory(taskId);
        let statusHistory = taskstatusHistory.filter(x => x.type);
        let arrStatusHistory = [];
        for (let i = 0; i < statusHistory.length; i++) {
            const objStatusHistory = {}
            objStatusHistory['status'] = statusHistory[i].status;
            objStatusHistory['type'] = statusHistory[i].type;
            objStatusHistory['durationInMinutes'] = statusHistory[i].total_time.by_minute;
            objStatusHistory['dateCreated'] = Math.round(statusHistory[i].total_time.since / 1000);
            arrStatusHistory.push(objStatusHistory);
        }

        if (arrStatusHistory.length > 0)
            await this._processItemsInBatchesHistory(taskId, arrStatusHistory, 10, this.addStatusHistoryToDB.bind(this));

        return 1;
    }

    public async processLinkCertificationWithPersonCompany() {
        //Get custom field with CERTIFICATION list id
        let cfCertifications = await this.GetCustomFieldsForCertificationLink();
        //cfCertifications = cfCertifications.filter(x => x.value);
        if(cfCertifications.length == 0) {
            console.log('Certifications Custom Field not found');
            return;
        }

        let arrPersonCompanies = [];
        let arrCompanyCertifications = [];
        for (let i = 0; i < cfCertifications.length; i++) {
            try {
                let companyTaskId = null;
                if(cfCertifications[i].companyTask) { // Company-Certification
                    const valueJson = JSON.parse(cfCertifications[i].companyTask);
                    for (let index = 0; index < valueJson.length; index++) {
                        const objCompanyCertificate = {}
                        companyTaskId = valueJson[index].id; 
                        objCompanyCertificate['taskId'] = companyTaskId  // companyTaskId
                        objCompanyCertificate['parentId'] = cfCertifications[i].certificationTaskId; // certificationTaskId
                        arrCompanyCertifications.push(objCompanyCertificate);
                    }
                }
                    
                if(cfCertifications[i].personTask && companyTaskId) { // Company-Person
                    const valueJson = JSON.parse(cfCertifications[i].personTask);
                    for (let index = 0; index < valueJson.length; index++) {
                        const objPersonCompany = {}
                        objPersonCompany['taskId'] = valueJson[index].id; // personTaskId
                        objPersonCompany['parentId'] = companyTaskId; // companyTaskId
                        arrPersonCompanies.push(objPersonCompany);
                    }
                }
            }
            catch (err) {
                console.error("processLinkCertificationWithPersonCompany", err);
            }
        }
        
        await this._processItemsInBatches(arrPersonCompanies, 50, this.addPersonCompanyToDB.bind(this));
        await this._processItemsInBatches(arrCompanyCertifications, 50, this.addCompanyCertificationToDB.bind(this));
     }

    //Get all custom fields where type = list_relationship with value Company.
    public async processTasksPersonCompany() {
        //Get configuration to get list id for people.
        const configurations = await this.getLists();
        const peopleConfigs = configurations.filter(x => x.name == 'People');
        const listId = peopleConfigs.length > 0 ? peopleConfigs[0].listId : '';

        if (!listId) {
            console.log('People configuration not found');
            return;
        }

        //Get custom field with people list id
        //let custom_fields = await this.GetCustomFieldsByTypeName('Company', 'list_relationship', listId);
        let custom_fields = await this.GetCustomFieldsByTypeName('Company', 'tasks', listId);
        custom_fields = custom_fields.filter(x => x.value);

        let arrPersonCompanies = [];
        for (let i = 0; i < custom_fields.length; i++) {
            try {
                const valueJson = JSON.parse(custom_fields[i].value);
                for (let index = 0; index < valueJson.length; index++) {
                    const objPersonCompany = {}
                    objPersonCompany['taskId'] = custom_fields[i].taskId;
                    const parentId = valueJson[index].id;
                    if (parentId) {
                        objPersonCompany['parentId'] = parentId;
                        arrPersonCompanies.push(objPersonCompany);
                    }
                }
            }
            catch (err) {
                console.error("processTasksPersonCompany", err);
            }
        }
        await this._processItemsInBatches(arrPersonCompanies, 50, this.addPersonCompanyToDB.bind(this));
    }

    //Get all custom fields where type = list_relationship with value Company.
    public async processTasksCompanyCertifications() {

        //Get configuration to get list id for customers.
        const configurations = await this.getLists();
        const customersConfigs = configurations.filter(x => x.name == 'Companies');
        const listId = customersConfigs.length > 0 ? customersConfigs[0].listId : '';

        if (!listId) {
            console.log('Customers configuration not found');
            return;
        }

        //Get custom field with customer list id
        //let custom_fields = await this.GetCustomFieldsByTypeName('Certifications', 'list_relationship', listId);
        let custom_fields = await this.GetCustomFieldsByTypeName('Certifications', 'tasks', listId);
        custom_fields = custom_fields.filter(x => x.value && x.value != '[]');

        let arrCompanyCertifications = [];
        for (let i = 0; i < custom_fields.length; i++) {
            try {
                const valueJson = JSON.parse(custom_fields[i].value);
                for (let index = 0; index < valueJson.length; index++) {
                    const objCompanyCertificate = {}
                    objCompanyCertificate['taskId'] = custom_fields[i].taskId;
                    const parentId = valueJson[index].id;
                    if (parentId) {
                        objCompanyCertificate['parentId'] = parentId;
                        arrCompanyCertifications.push(objCompanyCertificate);
                    }
                }
            }
            catch (err) {
                console.error("processTasksCompanyCertifications", err);
            }
        }
        await this._processItemsInBatches(arrCompanyCertifications, 50, this.addCompanyCertificationToDB.bind(this));
    }

    public async processTasksCertificationBuyer() {

        //Get configuration to get list id for customers.
        const configurations = await this.getLists();
        const customersConfigs = configurations.filter(x => x.name == 'Certifications');
        const listId = customersConfigs.length > 0 ? customersConfigs[0].listId : '';

        if (!listId) {
            console.log('Certifications configuration not found');
            return;
        }

        //Get custom field with customer list id
        let custom_fields = await this.GetCustomFieldsByTypeName('Buyer', 'list_relationship', listId);
        custom_fields = custom_fields.filter(x => x.value && x.value != '[]');

        let arrMapping = [];
        for (let i = 0; i < custom_fields.length; i++) {
            try {
                const valueJson = JSON.parse(custom_fields[i].value);
                for (let index = 0; index < valueJson.length; index++) {
                    const objData = {}
                    objData['certificationTaskId'] = custom_fields[i].taskId;
                    const parentId = valueJson[index].id;
                    if (parentId) {
                        objData['buyerTaskId'] = parentId;
                        arrMapping.push(objData);
                    }
                }
            }
            catch (err) {
                console.error("processTasksCompanyCertifications", err);
            }
        }
        await this._processItemsInBatches(arrMapping, 50, this.addCertificationBuyerToDB.bind(this));
    }

    //Get all customers from view and populate in Customer Table.
    public async populateCustomers() {
        await this.populateCustomersToDB();
    }

    //update due date with time for all people.
    public async processUpdatePeopleDueDate() {

        //Get tasks with people list id
        let peopleTasks = await this.getTasksToUpdateDueDateTime();
        for (let i = 0; i < peopleTasks.length; i++) {
            try {
                let objTask = {};
                let dueDate = peopleTasks[i]['dueDate'];
                let result = this.isWorkingDay(dueDate);
                if (!result) {
                    dueDate = this.getNextWorkingDay(dueDate);
                }
                const taskId = peopleTasks[i]['id'];
                const randomTime = this.getRandomTimeForADate(dueDate, 10, 16);
                dueDate.setHours(randomTime.getHours(), randomTime.getMinutes(), 0, 0);
                objTask['due_date'] = dueDate.getTime();
                objTask['due_date_time'] = true;
                await this.updateTaskDueDateToClickUp(taskId, objTask);
            }
            catch (err) {
                console.error("processUpdatePeopleDueDate", err);
            }
        }
    }

    public async processPeopleSnapshotRefresh() {
        await this.insertPeopleSnapshotRefresh();
    }
    
    private getRandomTimeForADate(date: Date, startHour: number, endHour: number) {
        // Calculate the time range in milliseconds
        const startTime = date.setHours(startHour, 0, 0);
        const endTime = date.setHours(endHour, 0, 0);
        const timeRangeMs = endTime - startTime;

        // Generate a random time within the range
        const randomTimeMs = Math.random() * timeRangeMs;
        const randomTime = new Date(startTime + randomTimeMs);
        return randomTime;
    }

    private getNextWorkingDay(date) {
        const oneDay = 24 * 60 * 60 * 1000; // Number of milliseconds in a day

        let nextDay: Date = null;
        // Clone the input date to avoid modifying the original
        nextDay = new Date(date.getTime() + oneDay);

        // Iterate forward until finding the next working day
        while (!this.isWorkingDay(nextDay)) {
            nextDay.setTime(nextDay.getTime() + oneDay); // Move to the next day
        }
        return nextDay;
    }

    // Function to check if a given date is a working day
    private isWorkingDay(date) {
        const dayOfWeek = date.getDay(); // Sunday - 0, Monday - 1, ..., Saturday - 6
        return dayOfWeek !== 0 && dayOfWeek !== 6; // Exclude Sunday (0) and Saturday (6)
    }

    public async addTaskAttachment(taskId: string, fileUrl: string){
        const url = `https://${process.env.CLICKUP_URL}/task/${taskId}/attachment`;
        
        // Fetch the logo image from the provided URL
        const res = await fetch(fileUrl+'?apiKey='+process.env.JOTFORM_APIKEY);
        if (!res.ok) {
            throw new Error(`Failed to fetch the file. Status: ${res.status} ${res.statusText}`);
        }
        const logoBuffer = await res.buffer();

        // Create the form data
        const form = new FormData();
        form.append('attachment', logoBuffer, {
            filename: path.basename(fileUrl),
            contentType: res.headers.get('Content-Type') || 'application/octet-stream',
        });
        
        const options = {
            method: 'POST',
            headers: {...this.headers, ...form.getHeaders() },  
            body: form
        };

        try {
            const response = await fetch(url, options);
            const result = await response.json();
            return result;
        } catch (e) {
            console.error("addTaskAttachment", e);
        }
    }
    public async setTaskCustomFieldValue(taskId: string, fieldName: string, fieldValue: string) {
        const cfId = this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, fieldName);
        const url = `https://${process.env.CLICKUP_URL}/task/${taskId}/field/${cfId}`;
        const options = {
            method: 'POST',
            headers: this.headers,
            body: JSON.stringify({ value: fieldValue })
        };

        try {
            const response = await fetch(url, options);
            const result = await response.json();
            if(response.ok) {
                return true;
            }
            else
                console.error("setTaskCustomFieldValue", result);
            return false;
        } catch (e) {
            console.error("setTaskCustomFieldValue", e);
            return false;
        }
    }
    public async setTaskCustomFieldValueInDB(taskId: string, fieldName: string, fieldValue: string) {
        try {
            const query = await this.databaseService.execute('[clickup].[spTask_SetCustomFieldValue]', [
                { name: "taskId", type: mssql.TYPES.NVarChar, value: taskId },
                { name: "fieldName", type: mssql.TYPES.NVarChar, value: fieldName },
                { name: "fieldValue", type: mssql.TYPES.NVarChar, value: fieldValue },
            ]);
            const results = query.results;
            return results;
        } catch (e) {
            console.error("setTaskCustomFieldValueInDB", e);
            return false;
        }
    }
    
    public async setTaskRelationship(companyTaskId: string, taskId: string, linkWithTaskId: string, relType: string) {
        const cfId = this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField, relType);
        const url = `https://${process.env.CLICKUP_URL}/task/${taskId}/field/${cfId}`;
        const options = {
            method: 'POST',
            headers: this.headers,
            body: JSON.stringify({
                value: {
                  add: [linkWithTaskId],
                }
              })
        };

        try {
            const response = await fetch(url, options);
            const result = await response.json();
            if(response.ok) {
                if(relType === "Person in Certification Relationship") //"People Relationship"
                    await this.addPersonCompanyDirectToDB(companyTaskId, linkWithTaskId);
                if(relType === "Company in Certification Relationship") //"Certifications Relationship"
                    await this.addCompanyCertificationDirectToDB(companyTaskId, taskId);
            }
            else
                console.error("setTaskRelationship", result);
            return result;
        } catch (e) {
            console.error("setTaskRelationship", e);
        }
    }

    // TODO: add CustomFieldsDef table to list all CustomFields for a list. (id, name, type, listId)
    //Create Task with CustomFields
    public async createTaskCF(name: string, description: string, status: string, customFields: any, listId: number, tags?: string[]) {
        let objTask = {};
        objTask['name'] = name;
        objTask['description'] = description;
        objTask['status'] = status;
        objTask['custom_fields'] = customFields;
        objTask['listId'] = listId;
        if (tags && tags.length > 0) {
            objTask['tags'] = tags;
        }
        
        const response = await this.processTaskToClickUp(objTask);
        return response;
    }

    //Post subtask details
    public async createTask(name: string, description: string, status: string, parentId: string, listId: number,
                            formId: string, submissionId: string, tags?: string[]) {
        let objTask = {};
        objTask['name'] = name;
        objTask['description'] = description;
        objTask['status'] = status;
        objTask['parent'] = parentId;
        objTask['listId'] = listId;

        objTask['custom_fields'] = 
            [{  id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"formId"),
                value: formId
             },
             { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"submissionId"),
                value: submissionId
             },
             { id: this.customFieldsConstants.findConstantIdbyName(CustomFieldsConstantTypes.CustomField,"Created by API"),
                value: '1'
             },
            ]
        const response = await this.processTaskToClickUp(objTask);
        return response;
    }

    private async _processItemsInBatchesHistory(taskId: string, items: any[], batchSize: number, callback: (taskId: string, batch: any) => Promise<any>): Promise<void> {
        for (let i = 0; i < items.length; i += batchSize) {
            try {
                const batch = items.slice(i, i + batchSize);
                await callback(taskId, batch);
            } catch (e) {
                //this.errorLoggerService.log("_processItemsInBatchesHistory", e);
                console.error("_processItemsInBatchesHistory ", e)
            }
        }
    }

    private async _processItemsInBatches(items: any[], batchSize: number, callback: (batch: any) => Promise<any>): Promise<void> {
        for (let i = 0; i < items.length; i += batchSize) {
            try {
                const batch = items.slice(i, i + batchSize);
                await callback(batch);
            } catch (e) {
                //this.errorLoggerService.log("_processItemsInBatches", e);
                console.error("_processItemsInBatches", e)
            }
        }
    }

    public async exportClickupLists() {
        const listId = process.env.CLICKUP_LISTID;
        const tasks = await this.getTasks(+listId);
        let refinedTasks = [];
        for (let i = 0; i < tasks.length; i++) {
            const refinedTask = {};
            refinedTask['Name'] = tasks[i].name;
            refinedTask['Start Date'] = tasks[i].start_date ? this.gateDateStr(tasks[i].start_date) : '';
            refinedTask['Due Date'] = tasks[i].due_date ? this.gateDateStr(tasks[i].due_date) : '';
            refinedTask['Created Date'] = tasks[i].date_created ? this.gateDateStr(tasks[i].date_created) : '';
            refinedTask['Updated Date'] = tasks[i].date_updated ? this.gateDateStr(tasks[i].date_updated) : '';
            refinedTask['Assignees'] = tasks[i].assignees.length > 0 ? tasks[i].assignees.map(x => x.username).join(', ') : '';
            refinedTask['status'] = tasks[i].status ? tasks[i].status?.status : '';
            const customFields = tasks[i].custom_fields;
            for (let j = 0; j < customFields.length; j++) {
                const name = customFields[j]['name'];
                if (name == 'Last Contacted' || name == 'Next Step Date') {
                    refinedTask[name] = customFields[j]['value'] ? this.gateDateStr(customFields[j]['value']) : '';
                } else if (name == 'Postcode') {
                    refinedTask[name] = customFields[j]['value'] ? (`${customFields[j]['value']['formatted_address']}`).replace(/\n/g, "") : '';
                } else if (name == 'Hot or Not') {
                    refinedTask[name] = customFields[j]['value'] ? this.getHotOrNot(+customFields[j]['value']) : '';
                } else if (name == 'Industry') {
                    refinedTask[name] = customFields[j]['value'] ? this.getIndustry(+customFields[j]['value']) : '';
                } else {
                    refinedTask[name] = customFields[j]['value'] ? (`${customFields[j]['value']}`).replace(/\n/g, "") : '';
                }
            }
            const comments = await this.getTaskComments(tasks[i].id);
            refinedTask['Last comment'] = comments[0]?.comment_text?.trim();
            refinedTasks.push(refinedTask);
        }

        await this.exportAsTxt('D:/clickup.txt', refinedTasks);

        return 1;
    }

    getHotOrNot(value: any): any {
        const arrHotOrNot = ['Hot', 'Warm', 'Cold']
        return value <= arrHotOrNot.length ? arrHotOrNot[value] : '';
    }

    getIndustry(value: number): string {
        const arrIndustry = ['Financial', 'Security', 'Recruitment', 'Engineering', 'Retail', 'Hospitality', 'Cleaning', 'Construction', 'Trades', 'Facilities Management', 'Sustainability', 'Graphics/Branding/Design', 'Technical/Digital/Telecoms', 'Education/Healthcare', 'Plant/Equipment/Haulage', 'Portals/Procurement Platforms', 'Retailer', 'logistics', 'Insurance', 'Charity', 'Legal', 'Pest Control', 'Window Cleaning']
        return value <= arrIndustry.length ? arrIndustry[value] : '';
    }

    private gateDateStr(value: number) {
        const d = new Date(+value);
        return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`;
    }

    public async exportAsTxt(filename: string, data: any) {
        let strHeaders = "";
        const strUsers = data.map((x: any) => {
            if (!strHeaders) {
                strHeaders = Object.keys(x).join("^");
            }
            return {
                value: Object.values(x).join("^")
            }
        }).map(x => x.value).join('\n');

        const fs = require('fs');
        fs.writeFile(filename || './result.txt', strHeaders + '\n' + strUsers, function (err) {
            if (err) {
                console.error('exportAsTxt',err);
            } else {
                console.log('exported')
            }
        });
    }

    public async getTasks(listId: number, includeSubtasks: 'true' | 'false' = 'false', includeClosed: 'true' | 'false' = 'true', includeArchived: 'true' | 'false' = 'true'): Promise<any> {
        let result = { last_page: false, tasks: [] };
        let tasks = []
        let page = 0;
        while (!result.last_page) {
            let url = `https://${process.env.CLICKUP_URL}/list/${listId}/task?archived=${includeArchived}&subtasks=${includeSubtasks}&include_closed=${includeClosed}&page=${page}`;
            const options = {
                method: 'GET',
                headers: this.headers
            };

            try {
                const response = await fetch(url, options);
                result = await response.json();
                tasks.push(...result?.tasks);
            } catch (e) {
                //this.errorLoggerService.log("getTasks", e);
                console.error("getTasks", e);
            }
            page++;
        }
        return tasks;
    }

    public async getTask(taskId: string): Promise<any> {
        let task;
        let url = `https://${process.env.CLICKUP_URL}/task/${taskId}`;
        const options = {
            method: 'GET',
            headers: this.headers
        };

        try {
            const response = await fetch(url, options);
            task = await response.json();
            //task = result?.task;
        } catch (e) {
            console.error("getTask", e);
        }

        return task;
    }

    public async addTaskComment(taskId: string, commentText: string, assignee?: number) {
        const url = `https://${process.env.CLICKUP_URL}/task/${taskId}/comment`;
        const parts = commentText.split('\n');
        commentText = parts.join('\\n');
        const options = {
            method: 'POST',
            headers: this.headers,
            body: `{
                "comment_text": "${commentText}", 
                "assignee": ${assignee || 0},
                "notify_all": false
            }`
        };

        try {
            const response = await fetch(url, options);
            const result = await response.json();
            return result;
        } catch (e) {
            //this.errorLoggerService.log("addTaskComment", e);
            console.error("addTaskComment", e);
        }
    }

    public async getTaskComments(taskId: string) {
        const url = `https://${process.env.CLICKUP_URL}/task/${taskId}/comment`;
        const options = {
            method: 'GET',
            headers: this.headers
        };

        try {
            const response = await fetch(url, options);
            const result = await response.json();
            return result?.comments;
        } catch (e) {
            //this.errorLoggerService.log("getTaskComments", e);
            console.error("getTaskComments", e);
        }
    }

    private async getCustomFields(listId: number) {
        const url = `https://${process.env.CLICKUP_URL}/list/${listId}/field`;
        const options = {
            method: 'GET',
            headers: this.headers
        };

        try {
            const response = await fetch(url, options);
            const result = await response.json();
            return result?.fields;
        } catch (e) {
            //this.errorLoggerService.log("getCustomFields", e);
            console.error("getCustomFields", e);
        }
    }

    public async getStatusHistory(taskId: string): Promise<any> {
        let statusHistory = []
        let url = `https://${process.env.CLICKUP_URL}/task/${taskId}/time_in_status`;
        // let url = `https://${process.env.CLICKUP_URL}/task/bulk_time_in_status/task_ids?task_ids=${taskId}`;
        const options = {
            method: 'GET',
            headers: this.headers
        };
        try {
            const response = await fetch(url, options);
            const result = await response.json();
            if (result && result.status_history) {
                statusHistory = result.status_history;
            }
        } catch (e) {
            //this.errorLoggerService.log("getStatusHistory", e);
            console.error("getStatusHistory", e);
        }
        return statusHistory;
    }

    public sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    public async processTaskToClickUp(task: any) {
        const url = `https://${process.env.CLICKUP_URL}/list/${task.listId}/task`;
        const options = {
            method: 'POST',
            headers: this.headers,
            body: JSON.stringify(task)
        };

        try {
            const response = await fetch(url, options);
            const result = await response.json();
            return result;
        } catch (e) {
            //this.errorLoggerService.log("processTaskToClickUp", e);
            console.error("processTaskToClickUp", e);
        }
    }

    public async updateTaskDueDateToClickUp(taskId: string, taskReq: any) {
        const url = `https://${process.env.CLICKUP_URL}/task/${taskId}`;
        const options = {
            method: 'PUT',
            headers: this.headers,
            body: JSON.stringify(taskReq)
        };

        try {
            const response = await fetch(url, options);
            const result = await response.json();
            return result;
        } catch (e) {
            this.errorLoggerService.log("updateTaskDueDateToClickUp", e);
            console.error("api error:", e);
        }
    }

    private async prepareCustomFieldFilter(listId: number, customFields: any[]): Promise<string> {
        if (!customFields || customFields?.length == 0) {
            return undefined;
        }
        const fields = [];
        const custFields = await this.getCustomFields(listId);
        customFields?.forEach(item => {
            const customFieldId = custFields?.find((x: any) => x.name.toLowerCase() == item.name.toLowerCase())?.id;
            if (customFieldId) {
                fields.push({
                    field_id: customFieldId,
                    operator: '=',
                    value: item.value
                })
            }
        });
        return fields.length > 0 ? JSON.stringify(fields) : undefined;
    }

    private async getLists() {
        const query = await this.databaseService.execute('[clickup].[spConfigration_Select]');
        const results = query.results;
        return results;
    }

    private async addTasksToDB(tasks: any) {
        const query = await this.databaseService.execute('[clickup].[spClickup_AddTasks]', [
            { name: "tasks_JSON", type: mssql.TYPES.NVarChar, value: JSON.stringify(tasks) },
        ]);
        const results = query.results;
        return results;
    }

    private async clickUpJob_AddTasksToDB(tasks: any) { // For ClickupJob performance optimize
        try {
            const query = await this.databaseService.execute('[clickup].[spClickupJob_AddTasks]', [
                { name: "tasks_JSON", type: mssql.TYPES.NVarChar, value: JSON.stringify(tasks) },
            ]);
            const results = query.results;
            return results;
        }
        catch (e) {
            console.error("clickUpJob_AddTasksToDB", e);
            return 0;
        }
    }
    private async clickUpJob_AddAssigneesToDB(tasks: any) { // For ClickupJob performance optimize
        try {
            const query = await this.databaseService.execute('[clickup].[spClickupJob_AddAssignees]', [
                { name: "tasks_JSON", type: mssql.TYPES.NVarChar, value: JSON.stringify(tasks) },
            ]);
            const results = query.results;
            return results;
        }
        catch (e) {
            console.error("clickUpJob_AddAssigneesToDB", e);
            return 0;
        }
    }
    private async clickUpJob_AddCustomFieldsToDB(tasks: any) { // For ClickupJob performance optimize
        try {
            const query = await this.databaseService.execute('[clickup].[spClickupJob_AddCustomFields]', [
                { name: "tasks_JSON", type: mssql.TYPES.NVarChar, value: JSON.stringify(tasks) },
            ]);
            const results = query.results;
            return results;
        }
        catch (e) {
            console.error("clickUpJob_AddCustomFieldsToDB", e);
            return 0;
        }   
    }
    private async clickUpJob_AddUsersToDB(tasks: any) { // For ClickupJob performance optimize
        try {
            const query = await this.databaseService.execute('[clickup].[spClickup_AddUsers]', [
                { name: "users_JSON", type: mssql.TYPES.NVarChar, value: JSON.stringify(tasks) },
            ]);
            const results = query.results;
            return results;
        }
        catch (e) {
            console.error("clickUpJob_AddUsersToDB", e);
            return 0;
        }
    }


    private async addStatusHistoryToDB(taskId: string, tasks: any) {
        const query = await this.databaseService.execute('[clickup].[spClickup_AddStatusHistory]', [
            { name: "status_JSON", type: mssql.TYPES.NVarChar, value: JSON.stringify(tasks) },
            { name: "taskId", type: mssql.TYPES.NVarChar, value: taskId }
        ]);
        const results = query.results;
        return results;
    }

    public getWebhookExists(webhookId: string):boolean
    {   // Safety check that request comes through is from clickup
       return this.customFieldsConstants.findWebhookId(webhookId);
    }

    public async getTaskDetailsFromDB(taskId: string) { 
        try {
            const query = await this.databaseService.execute('[clickup].[spClickup_GetTaskDetails]', [
                { name: "taskId", type: mssql.TYPES.NVarChar, value: taskId },
            ]);
            const results = query.results;
            if(results.length == 0) {
                return { success: false, message: 'Task not found', data: null };
            }
            else {
                return { success: true, data: results };
            }
        }
        catch (e) {
            console.error("getTaskDetailsFromDB", e);
            return { success: false, message: e.message, data: null };
        }
    }
    public async deleteTaskToDB(taskId: string) {
        try {
            const query = await this.databaseService.execute('[clickup].[spTask_DeleteTask]', [
                { name: "taskId", type: mssql.TYPES.NVarChar, value: taskId }
            ]);
            const results = query.results;
            return results;
        }
        catch (e) {
            console.error("deleteTaskToDB", e);
            return 0;
        }
    }
    public async createTaskToDB(body: any, log: boolean = true) { // New task entry in DB
        try {
            if (log) {
                const jsonFile = path.join('./logs', `taskCreatedPayload-${new Date().toISOString().split('T')[0]}.log`);
                const jsonMessage = `[Task Created] [${new Date().toISOString()}]\n ${JSON.stringify(body)}\n`;
                fs.appendFileSync(jsonFile, jsonMessage, 'utf8');
            }
            // Check for duplicate task in DB
            const query = await this.databaseService.execute('[clickup].[spTask_TaskCreatedExists]', [
                { name: "taskId", type: mssql.TYPES.NVarChar, value: body.task_id },
            ]);
            const results = query.results;
            if(results[0].cnt == 1)
                return 0;
            else
            {   // Get Task details from Clickup API
                const task = await this.getTask(body.task_id);

                if(task && task.id)
                {   // Store Task details in DB
                    await this.processTasksDirectToDB([task]);
                    await this.databaseService.execute('[clickup].[spTask_TaskCreatedMarkImported]', [
                        { name: "taskId", type: mssql.TYPES.NVarChar, value: body.task_id },
                        { name: "isImported", type: mssql.TYPES.Bit, value: 1 },
                    ]);
                }
                else
                    console.info("createTaskToDB", {...task, "task_id": body.task_id});
            }
            return 1;
        }
        catch (e) {
            console.error("createTaskToDB", e);
            return 0;
        }
    }
    public async moveTaskToDB(taskId: string, moveToListId: string, moveToFolderId: string, moveToSpaceId: string) { // Update listId of Task in DB
        try {
            const query = await this.databaseService.execute('[clickup].[spTask_moveTask]', [
                { name: "taskId", type: mssql.TYPES.NVarChar, value: taskId },
                { name: "moveToListId", type: mssql.TYPES.BigInt, value: moveToListId },
                { name: "moveToFolderId", type: mssql.TYPES.BigInt, value: moveToFolderId },
                { name: "moveToSpaceId", type: mssql.TYPES.BigInt, value: moveToSpaceId },
            ]);
            const results = query.results;
            return results;
        }
        catch (e) {
            console.error("moveTaskToDB", e);
            return 0;
        }
    }
    private async getAllParentTasksLists() {
        const query = await this.databaseService.execute('[clickup].[spClickup_GetAllParentTasks]');
        const results = query.results;
        return results;
    }

    private async GetCustomFieldsForCertificationLink() {
        const query = await this.databaseService.execute('[clickup].[spCustomField_SelectForCertificationLink]');
        const results = query.results;
        return results;
    }
    private async GetCustomFieldsByTypeName(name: string, type: string, listId: number) {
        const query = await this.databaseService.execute('[clickup].[spCustomField_SelectByTypeName]', [
            { name: "name", type: mssql.TYPES.NVarChar, value: name },
            { name: "type", type: mssql.TYPES.NVarChar, value: type },
            { name: "listId", type: mssql.TYPES.BigInt, value: listId }
        ]);
        const results = query.results;
        return results;
    }

    private async getTasksToUpdateDueDateTime() {
        const query = await this.databaseService.execute('[clickup].[spClickup_GetTasksWithDueDate]');
        const results = query.results;
        return results;
    }
   
    private async addPersonCompanyToDB(personCompanies: any) {
        const query = await this.databaseService.execute('[clickup].[spClickup_AddPersonCompany]', [
            { name: "task_personcompany_json", type: mssql.TYPES.NVarChar, value: JSON.stringify(personCompanies) },
        ]);
        const results = query.results;
        return results;
    }

    private async addCompanyCertificationToDB(companyCertifications: any) {
        const query = await this.databaseService.execute('[clickup].[spClickup_AddCompanyCertifications]', [
            { name: "task_companycertifications_json", type: mssql.TYPES.NVarChar, value: JSON.stringify(companyCertifications) },
        ]);
        const results = query.results;
        return results;
    }
    public async addCompanyDirectToDB(companyTaskId: string, name: string, description: string) {
        const query = await this.databaseService.execute('[clickup].[spTask_AddCompany]', [
            { name: "companyTaskId", type: mssql.TYPES.NVarChar, value: companyTaskId },
            { name: "name", type: mssql.TYPES.NVarChar, value: name },
            { name: "description", type: mssql.TYPES.NVarChar, value: description },
        ]);
        const results = query.results;
        return results;
    }
    public async addPersonCompanyDirectToDB(companyTaskId: string, personTaskId: string) {
        const query = await this.databaseService.execute('[clickup].[spTask_AddPersonCompany]', [
            { name: "companyTaskId", type: mssql.TYPES.NVarChar, value: companyTaskId },
            { name: "personTaskId", type: mssql.TYPES.NVarChar, value: personTaskId },
        ]);
        const results = query.results;
        return results;
    }
    public async addCompanyCertificationDirectToDB(companyTaskId: string, certificationTaskId: string) {
        const query = await this.databaseService.execute('[clickup].[spTask_AddCompanyCertifications]', [
            { name: "companyTaskId", type: mssql.TYPES.NVarChar, value: companyTaskId },
            { name: "certificationTaskId", type: mssql.TYPES.NVarChar, value: certificationTaskId },
        ]);
        const results = query.results;
        return results;
    }
    private async addCertificationBuyerToDB(certificationBuyer: any) {
        const query = await this.databaseService.execute('[clickup].[spClickup_AddCertificationBuyer]', [
            { name: "data_JSON", type: mssql.TYPES.NVarChar, value: JSON.stringify(certificationBuyer) },
        ]);
        const results = query.results;
        return results;
    }

    private async populateCustomersToDB() {
        const query = await this.databaseService.execute('[clickup].[spJotForm_PopulateCustomer]');
        const results = query.results;
        return results;
    }

    private async updateDeletedTasksToDB() {
        const query = await this.databaseService.execute('[clickup].[spClickup_DeleteTasks]');
        const results = query.results;
        return results;
    }

    private async insertPeopleSnapshotRefresh(){
        const query = await this.databaseService.execute('[DataModel].[spPeopleSnapshot_Refresh]');
        const results = query.results;
        return results;
    }
}
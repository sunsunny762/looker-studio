import { Injectable } from '@nestjs/common';
import { CustomFieldsConstantTypes } from "./customfields-constant-types";
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class CustomFieldsConstants {
  
  private constants: {
    listIds: Array<{ id: string; name: string }>;
    customFields: Array<{ id: string; name: string }>;
    products: Array<{ id: string; name: string }>;
    industries: Array<{ id: string; name: string }>;
    jotformAppIds: Array<{ id: string; name: string }>;
    clickupListDefaultStatusNames: Array<{ id: string; name: string }>;
    webhooks: string,
    customFieldsToKeep: string
  };

  constructor() {
    this.constants = this.loadJson('clickup-customfields.json');
  }

  private loadJson(filename: string) {
    const filePath = './config/' + filename; //path.join(__dirname, filename);
    return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  }
  
  getCustomFieldstoKeep(): string {
    return this.constants.customFieldsToKeep;
  }
  findWebhookId(webhookId: string): boolean
  {
    return this.constants.webhooks.includes(webhookId);
  }

  findConstantIdbyName(constantType: CustomFieldsConstantTypes, name: string) {
    if(constantType == CustomFieldsConstantTypes.Industry) {
        return this.constants.industries.find(item => item.name === name).id;
    }
    else if(constantType == CustomFieldsConstantTypes.CustomField) {
        return this.constants.customFields.find(item => item.name === name).id;
    }
    else if(constantType == CustomFieldsConstantTypes.Product) {
        return this.constants.products.find(item => item.name === name).id;
    }
    else if(constantType == CustomFieldsConstantTypes.ListId) {
        return this.constants.listIds.find(item => item.name === name).id;
    }
    else if(constantType == CustomFieldsConstantTypes.JotformAppId) {
        return this.constants.jotformAppIds.find(item => item.name === name).id;
    }
    else if(constantType == CustomFieldsConstantTypes.ClickupListDefaultStatusNames) {
        return this.constants.clickupListDefaultStatusNames.find(item => item.name === name).id;
    }
    return null;
  }
}
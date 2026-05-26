export enum AwardType {
  RJM = "RJM_DIGITAL",
  APP_GOLD = "APP_GOLD",
  APP_SILVER = "APP_SILVER",
  APP_PLATINUM = "APP_PLATINUM",
  DEFAULT = "DEFAULT"
}

export interface AwardConfig {
  productName: string;
  listName: string;
  statusName: string;
}

export interface TaskResult {
  tasks: any[];
  personTaskId: string;
  certTaskId: string;
  companyTaskId: string;
  certTaskCreated: boolean;
}
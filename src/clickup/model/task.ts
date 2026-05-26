export class Task {
    public id: string;
    public parentId: string;
    public name: string;
    public description: string;
    public folderId: number;
    public listId: number;
    public spaceId: number;
    public status: string;
    public createdBy: number;
    public startDate: number;
    public dueDate: number;
    public dateCreated: number;
    public dateUpdated: number;
    public dateDone: number;
    public isArchived: boolean;
    public creator_JSON: string;
    public status_JSON: string;
    public assignees_JSON: string;
    public customFields_JSON: string;
}
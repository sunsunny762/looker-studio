import { Body, Controller, Get, Param, Post, Req } from '@nestjs/common';
import { ClickUpService } from './clickup.service';

@Controller('clickup')
export class ClickupController {

    constructor(private readonly clickupService: ClickUpService) {}

    @Post('/getTasks')
    getTasks(@Req() req: any, @Body() body: any): Promise<any> {
        return this.clickupService.getTasks(body.listId);
    }

    @Post('/taskComment')
    addTaskComment(@Req() req: any, @Body() body: any): Promise<any> {
        return this.clickupService.addTaskComment(body.taskId, body.commentText, body.assignee);
    }

    @Get('/taskComments/:taskId')
    getTaskComments(@Param('taskId') taskId: string): Promise<any> {
        return this.clickupService.getTaskComments(taskId);
    }
    @Post('/taskDelete/Webhook') 
    deleteTask(@Req() req: any, @Body() body: any): Promise<any> {
        if(!this.clickupService.getWebhookExists(body.webhook_id)) return;
        console.log("Task Deleted: ", body.task_id);
        return this.clickupService.deleteTaskToDB(body.task_id);
    }
    @Post('/taskMoved/Webhook') 
    moveTask(@Req() req: any, @Body() body: any): Promise<any> {
        if(!this.clickupService.getWebhookExists(body.webhook_id)) return;
        console.log(`Task Moved: ${body.task_id}, ToListId: ${body.history_items[0].after.id} ToFolderId: ${body.history_items[0].after.category.id} ToSpaceId: ${body.history_items[0].after.project.id}, FromListId: ${body.history_items[0].before.id} FromFolderId: ${body.history_items[0].before.category.id} FromSpaceId: ${body.history_items[0].before.project.id}`);
        return this.clickupService.moveTaskToDB(body.task_id, 
            body.history_items[0].after.id, body.history_items[0].after.category.id, body.history_items[0].after.project.id);
    }
    @Post('/taskCreated/Webhook') 
    createTask(@Req() req: any, @Body() body: any): Promise<any> {
        if(!this.clickupService.getWebhookExists(body.webhook_id)) return;
        console.log(`Task Created: ${body.task_id}`);
        return this.clickupService.createTaskToDB(body);
    }

}

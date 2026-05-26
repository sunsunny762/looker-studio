import { Injectable, Logger } from '@nestjs/common';
import * as mssql from 'mssql';
import { DatabaseService } from '../database';
import { ErrorLoggerService } from '../error-logger/error-logger.service';
import { NotificationsGateway } from './notifications.gateway';
import { ItemCountPayload, NotificationPayload, BadgeCountPayload } from './notifications.events';

@Injectable()
export class NotificationsService {
    private readonly logger = new Logger(NotificationsService.name);

    constructor(
        private readonly databaseService: DatabaseService,
        private readonly errorLoggerService: ErrorLoggerService,
        private notificationsGateway: NotificationsGateway,
    ) {}

    // async getBlueAwardCertificationsCount(): Promise<any> {

    //     const query = await this.databaseService.execute('portal.spCertificationBlueAwardCount_Get', [
    //     ]);
    //     const results = query.results[0]?.cnt;
    //     return results;
    // }
    
    /**
     * Broadcast Blue Award count to all connected clients
     */
    async broadcastBlueAwardCount(count: number): Promise<void> {
        try {
            //const count = await this.getBlueAwardCertificationsCount();
            
            const payload: ItemCountPayload = {
                count,
                timestamp: new Date().toISOString(),
                source: 'server'
            };

            this.notificationsGateway.broadcastBlueAwardCount(payload);
            
            console.log('clientsCount: ', this.notificationsGateway.server?.engine?.clientsCount || 0);
            this.logger.log(`Broadcasted blue award count update: ${count}`);
        } catch (error) {
            this.logger.error('Error broadcasting blue award count', error);
            await this.errorLoggerService.writeLogToDB('NotificationsService.broadcastBlueAwardCount', error);
        }
    }

    /**
     * Get unread notification count for a user
     * Calls stored procedure: [portal].[spNotification_GetUnreadCount]
     */
    async getUserNotificationCount(userId: string): Promise<number> {
        try {
            // const result = await this.databaseService.execute(
            //     '[portal].[spNotification_GetUnreadCount]',
            //     [
            //         { name: 'userId', type: mssql.TYPES.NVarChar, value: userId }
            //     ]
            // );

            // if (result?.results && result.results.length > 0) {
            //     return result.results[0][0]?.unreadCount || 0;
            // }

            return 0;
        } catch (error) {
            this.logger.error(`Error fetching notification count for user ${userId}`, error);
            await this.errorLoggerService.writeLogToDB('NotificationsService.getUserNotificationCount', error);
            throw error;
        }
    }

    /**
     * Send notification to specific user
     */
    async sendNotificationToUser(userId: string, notification: Omit<NotificationPayload, 'userId' | 'timestamp'>): Promise<void> {
        try {
            // First, save notification to database
            // await this.databaseService.execute(
            //     '[portal].[spNotification_Create]',
            //     [
            //         { name: 'userId', type: mssql.TYPES.NVarChar, value: userId },
            //         { name: 'title', type: mssql.TYPES.NVarChar, value: notification.title },
            //         { name: 'message', type: mssql.TYPES.NVarChar, value: notification.message },
            //         { name: 'type', type: mssql.TYPES.NVarChar, value: notification.type },
            //         { name: 'data', type: mssql.TYPES.NVarChar, value: notification.data ? JSON.stringify(notification.data) : null }
            //     ]
            // );

            // Then broadcast via WebSocket
            const payload: NotificationPayload = {
                ...notification,
                userId,
                timestamp: new Date().toISOString()
            };

            this.notificationsGateway.sendToUser(userId, payload);
            this.logger.log(`Sent notification to user ${userId}: ${notification.title}`);

            // Update badge count
            await this.updateUserBadgeCount(userId);
        } catch (error) {
            this.logger.error(`Error sending notification to user ${userId}`, error);
            await this.errorLoggerService.writeLogToDB('NotificationsService.sendNotificationToUser', error);
        }
    }

    /**
     * Update and broadcast badge count for a user
     */
    async updateUserBadgeCount(userId: string): Promise<void> {
        try {
            const unreadCount = await this.getUserNotificationCount(userId);
            
            const payload: BadgeCountPayload = {
                userId,
                unreadCount,
                timestamp: new Date().toISOString()
            };

            this.notificationsGateway.sendBadgeCount(userId, payload);
        } catch (error) {
            this.logger.error(`Error updating badge count for user ${userId}`, error);
            await this.errorLoggerService.writeLogToDB('NotificationsService.updateUserBadgeCount', error);
        }
    }

    /**
     * Broadcast custom event to all clients
     */
    async broadcastToAll(event: string, payload: any): Promise<void> {
        try {
            this.notificationsGateway.broadcastNotification(event, payload);
            this.logger.log(`Broadcasted event: ${event}`);
        } catch (error) {
            this.logger.error(`Error broadcasting event ${event}`, error);
            await this.errorLoggerService.writeLogToDB('NotificationsService.broadcastToAll', error);
        }
    }

    /**
     * Broadcast to users with specific role
     * Calls stored procedure: [portal].[spUser_GetByRole]
     */
    async broadcastToRole(roleId: string, event: string, payload: any): Promise<void> {
        try {
            const result = await this.databaseService.execute(
                '[portal].[spUser_GetByRole]',
                [
                    { name: 'roleId', type: mssql.TYPES.NVarChar, value: roleId }
                ]
            );

            if (result?.results && result.results.length > 0) {
                const users = result.results[0];
                users.forEach((user: any) => {
                    this.notificationsGateway.sendToUser(user.userId, payload, event);
                });

                this.logger.log(`Broadcasted to role ${roleId}: ${users.length} users`);
            }
        } catch (error) {
            this.logger.error(`Error broadcasting to role ${roleId}`, error);
            await this.errorLoggerService.writeLogToDB('NotificationsService.broadcastToRole', error);
        }
    }

}

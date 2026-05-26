import { Module } from '@nestjs/common';
import { NotificationsGateway } from './notifications.gateway';
import { NotificationsService } from './notifications.service';
import { DatabaseModule } from '../database/database.module';
import { ErrorLoggerModule } from '../error-logger/error-logger.module';

/**
 * Notifications Module
 * 
 * Provides real-time WebSocket communication infrastructure
 * 
 * Features:
 * - WebSocket Gateway for bidirectional communication
 * - Service layer for business logic and database operations
 * - Event-driven architecture for scalability
 * - Room-based targeting (users, roles, companies)
 * - JWT security ready (see ws-jwt.guard.ts)
 * 
 * Usage:
 * 1. Import NotificationsModule in AppModule
 * 2. Inject NotificationsService into your controllers/services
 * 3. Call service methods to broadcast events
 * 
 * Example:
 * ```typescript
 * constructor(private notificationsService: NotificationsService) {}
 * 
 * async createItem() {
 *   // ... create item logic
 *   await this.notificationsService.afterItemCreated();
 * }
 * ```
 */
@Module({
    imports: [
        DatabaseModule,
        ErrorLoggerModule,
    ],
    providers: [
        NotificationsGateway,
        NotificationsService,
    ],
    exports: [
        NotificationsService, // Export for use in other modules
        NotificationsGateway, // Export if direct gateway access is needed
    ],
})
export class NotificationsModule {}

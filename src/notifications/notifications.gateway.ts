import {
    WebSocketGateway,
    WebSocketServer,
    OnGatewayInit,
    OnGatewayConnection,
    OnGatewayDisconnect,
    SubscribeMessage,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { 
    RealtimeEvents, 
    WS_ROOMS, 
    ItemCountPayload, 
    NotificationPayload,
    BadgeCountPayload 
} from './notifications.events';

/**
 * WebSocket Gateway for Real-time Communication
 * 
 * Handles WebSocket connections, disconnections, and broadcasting events
 * No business logic - delegates to NotificationsService
 * 
 * CORS enabled for all origins (configure per environment in production)
 * 
 * TO ENABLE FIREBASE JWT AUTHENTICATION:
 * 1. Uncomment the @UseGuards decorator below
 * 2. Users will be auto-joined to their personal rooms upon connection
 * 3. Client must send Firebase token in connection auth
 */
// import { UseGuards } from '@nestjs/common';
// import { WsJwtGuard } from '../auth/guards/ws-jwt.guard';

// @UseGuards(WsJwtGuard) // Uncomment to enable Firebase JWT auth
@WebSocketGateway({
    cors: {
        origin: '*', // Configure this in production: process.env.FRONTEND_URL
        credentials: true,
    },
    namespace: '/notifications', // WebSocket namespace: ws://localhost:3001/notifications
})
export class NotificationsGateway 
    implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect 
{
    @WebSocketServer()
    server: Server;

    private readonly logger = new Logger(NotificationsGateway.name);
    private connectedClients = new Map<string, Socket>();

    /**
     * Called once when the gateway is initialized
     */
    afterInit(server: Server) {
        this.logger.log('WebSocket Gateway initialized');
        this.logger.log(`WebSocket server running on namespace: /notifications`);
    }

    /**
     * Called when a client connects
     * 
     * If JWT auth is enabled (WsJwtGuard), user will be in client.data.user
     * and will be auto-joined to their personal room
     */
    handleConnection(client: Socket) {
        this.logger.log(`Client connected: ${client.id}`);
        
        // Store client reference
        this.connectedClients.set(client.id, client);

        // If JWT auth is enabled, user will be available
        const user = client.data?.user;
        if (user) {
            const uid = user.uid;
            const userRoom = WS_ROOMS.USER(uid);
            client.join(userRoom);
            this.logger.log(`User ${uid} (${user.email}) joined room: ${userRoom}`);
        }

        // Send connection confirmation
        client.emit(RealtimeEvents.CONNECTION_ESTABLISHED, {
            message: 'Connected to NCZ Portal WebSocket',
            clientId: client.id,
            authenticated: !!user,
            userId: user?.uid,
            timestamp: new Date().toISOString(),
        });

        // Log connection metrics
        this.logger.log(`Total connected clients: ${this.connectedClients.size}`);
    }

    /**
     * Called when a client disconnects
     */
    handleDisconnect(client: Socket) {
        this.logger.log(`Client disconnected: ${client.id}`);
        
        // Remove client reference
        this.connectedClients.delete(client.id);

        // Log connection metrics
        this.logger.log(`Total connected clients: ${this.connectedClients.size}`);
    }

    /**
     * FUTURE: Handle client joining a user-specific room
     * Called from client: socket.emit('joinUserRoom', { userId: 'xxx' })
     */
    @SubscribeMessage('joinUserRoom')
    handleJoinUserRoom(client: Socket, payload: { userId: string }) {
        const room = WS_ROOMS.USER(payload.userId);
        client.join(room);
        this.logger.log(`Client ${client.id} joined room: ${room}`);
        
        return {
            event: 'roomJoined',
            data: { room, userId: payload.userId }
        };
    }

    /**
     * FUTURE: Handle client leaving a user-specific room
     */
    @SubscribeMessage('leaveUserRoom')
    handleLeaveUserRoom(client: Socket, payload: { userId: string }) {
        const room = WS_ROOMS.USER(payload.userId);
        client.leave(room);
        this.logger.log(`Client ${client.id} left room: ${room}`);
        
        return {
            event: 'roomLeft',
            data: { room, userId: payload.userId }
        };
    }

    /**
     * FUTURE: Ping/Pong for connection health check
     */
    @SubscribeMessage('ping')
    handlePing(client: Socket) {
        return {
            event: 'pong',
            data: { timestamp: new Date().toISOString() }
        };
    }

    // ========================================
    // PUBLIC METHODS (called from Service)
    // ========================================

    /**
     * Broadcast blue award count to all connected clients
     */
    broadcastBlueAwardCount(payload: ItemCountPayload): void {
          console.log('========================================');
        console.log('Broadcasting blue award count');
        console.log('Server instance exists:', !!this.server);
        console.log('Connected clients:', this.server?.engine?.clientsCount || 0);
        console.log('Payload:', payload);
        console.log('========================================');
  

        this.server.emit(RealtimeEvents.BLUE_AWARD_COUNT, payload);
        this.logger.debug(`Broadcasted ${RealtimeEvents.BLUE_AWARD_COUNT}: ${payload.count}`);
    }

    /**
     * Broadcast generic notification to all clients
     */
    broadcastNotification(event: string, payload: any): void {
        this.server.emit(event, payload);
        this.logger.debug(`Broadcasted event: ${event}`);
    }

    /**
     * Send notification to specific user
     * User must have joined their room first
     */
    sendToUser(userId: string, payload: NotificationPayload, event: string = RealtimeEvents.NOTIFICATION_RECEIVED): void {
        const room = WS_ROOMS.USER(userId);
        this.server.to(room).emit(event, payload);
        this.logger.debug(`Sent ${event} to user ${userId} in room ${room}`);
    }

    /**
     * Send badge count update to specific user
     */
    sendBadgeCount(userId: string, payload: BadgeCountPayload): void {
        const room = WS_ROOMS.USER(userId);
        this.server.to(room).emit(RealtimeEvents.NOTIFICATION_BADGE_COUNT, payload);
        this.logger.debug(`Sent badge count to user ${userId}: ${payload.unreadCount}`);
    }

    /**
     * Broadcast to a specific role room
     */
    broadcastToRole(roleId: string, event: string, payload: any): void {
        const room = WS_ROOMS.ROLE(roleId);
        this.server.to(room).emit(event, payload);
        this.logger.debug(`Broadcasted ${event} to role ${roleId}`);
    }

    /**
     * Broadcast to a specific company room
     */
    broadcastToCompany(companyId: number, event: string, payload: any): void {
        const room = WS_ROOMS.COMPANY(companyId);
        this.server.to(room).emit(event, payload);
        this.logger.debug(`Broadcasted ${event} to company ${companyId}`);
    }

    /**
     * Get connection statistics
     */
    getConnectionStats() {
        return {
            connectedClients: this.connectedClients.size,
            timestamp: new Date().toISOString(),
        };
    }
}

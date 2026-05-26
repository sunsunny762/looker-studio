import { CanActivate, ExecutionContext, Injectable, Logger } from '@nestjs/common';
import { WsException } from '@nestjs/websockets';
import { Socket } from 'socket.io';
import { FirebaseService } from '../firebase.service';

/**
 * WebSocket JWT Guard
 * 
 * Secures WebSocket connections using Firebase JWT tokens
 * 
 * USAGE:
 * ------
 * In notifications.gateway.ts, add @UseGuards() decorator:
 * 
 * ```typescript
 * import { UseGuards } from '@nestjs/common';
 * import { WsJwtGuard } from '../auth/guards/ws-jwt.guard';
 * 
 * @UseGuards(WsJwtGuard)
 * @WebSocketGateway({ ... })
 * export class NotificationsGateway { ... }
 * ```
 * 
 * CLIENT SIDE:
 * ------------
 * Send JWT token during connection:
 * 
 * ```javascript
 * import io from 'socket.io-client';
 * 
 * const token = 'your-firebase-jwt-token';
 * const socket = io('http://localhost:3001/notifications', {
 *   auth: {
 *     token: token
 *   }
 * });
 * ```
 * 
 * Or via query parameter:
 * ```javascript
 * const socket = io('http://localhost:3001/notifications?token=your-jwt-token');
 * ```
 * 
 * ACCESSING USER IN GATEWAY:
 * --------------------------
 * Once authenticated, access user data:
 * 
 * ```typescript
 * handleConnection(client: Socket) {
 *   const user = client.data.user; // ApplicationUser object
 *   const uid = user.uid; // Firebase user ID
 *   
 *   // Auto-join user to their personal room
 *   const userRoom = WS_ROOMS.USER(uid);
 *   client.join(userRoom);
 * }
 * ```
 */
@Injectable()
export class WsJwtGuard implements CanActivate {
    private readonly logger = new Logger(WsJwtGuard.name);

    constructor(private readonly firebaseService: FirebaseService) {}

    async canActivate(context: ExecutionContext): Promise<boolean> {
        try {
            const client: Socket = context.switchToWs().getClient();
            const token = this.extractToken(client);

            if (!token) {
                this.logger.warn(`WebSocket connection rejected: No token provided`);
                throw new WsException('Unauthorized: No token provided');
            }

            // Verify Firebase JWT token
            const decodedToken = await this.firebaseService.verifyIdToken(token);

            if (!decodedToken) {
                this.logger.warn(`WebSocket connection rejected: Invalid token`);
                throw new WsException('Unauthorized: Invalid token');
            }

            // Convert to ApplicationUser
            const user = this.firebaseService.decodedUserTokenAsUser(decodedToken);

            if (!user) {
                this.logger.warn(`WebSocket connection rejected: User not found`);
                throw new WsException('Unauthorized: User not found');
            }

            // Attach user to socket for later use
            client.data.user = user;
            client.data.uid = user.uid;

            this.logger.log(`WebSocket authenticated: User ${user.uid} (${user.email})`);
            return true;

        } catch (error) {
            this.logger.error('WebSocket authentication error:', error);
            throw new WsException('Unauthorized: Authentication failed');
        }
    }

    /**
     * Extract JWT token from WebSocket handshake
     * Supports both auth.token and query.token
     */
    private extractToken(client: Socket): string | null {
        // Try to get token from auth object (recommended)
        const authToken = client.handshake?.auth?.token;
        if (authToken) {
            return authToken.replace('Bearer ', '');
        }

        // Fallback: try query parameter
        const queryToken = client.handshake?.query?.token;
        if (queryToken && typeof queryToken === 'string') {
            return queryToken.replace('Bearer ', '');
        }

        // Fallback: try Authorization header
        const authHeader = client.handshake?.headers?.authorization;
        if (authHeader) {
            return authHeader.replace('Bearer ', '');
        }

        return null;
    }
}

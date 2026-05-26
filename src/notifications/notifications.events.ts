/**
 * Real-time WebSocket Event Constants
 * 
 * Centralized event definitions for WebSocket communication.
 * Use these constants throughout the application for type safety.
 */
export enum RealtimeEvents {
    // Item-related events
    BLUE_AWARD_COUNT = 'blueAwardCount',
    
    // Notification events (future)
    NOTIFICATION_RECEIVED = 'notificationReceived',
    NOTIFICATION_READ = 'notificationRead',
    NOTIFICATION_BADGE_COUNT = 'notificationBadgeCount',
    
    // Connection events
    CONNECTION_ESTABLISHED = 'connectionEstablished',
    CONNECTION_ERROR = 'connectionError',
}

/**
 * WebSocket Room Prefixes
 * Used to organize users into specific channels
 */
export const WS_ROOMS = {
    USER: (userId: string) => `user_${userId}`,
    ROLE: (roleId: string) => `role_${roleId}`,
    COMPANY: (companyId: number) => `company_${companyId}`,
    BROADCAST: 'broadcast',
} as const;

/**
 * Event Payload Interfaces
 */
export interface ItemCountPayload {
    count: number;
    timestamp: string;
    source?: string;
}

export interface NotificationPayload {
    id?: string;
    userId: string;
    title: string;
    message: string;
    type: 'info' | 'success' | 'warning' | 'error';
    timestamp: string;
    read: boolean;
    data?: any;
}

export interface BadgeCountPayload {
    userId: string;
    unreadCount: number;
    timestamp: string;
}

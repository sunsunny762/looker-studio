export interface DecodedUserToken {
    auth_time: number;
    email?: string;
    email_verified?: boolean;
    exp: number;
    phone_number?: string;
    picture?: string;
    uid: string;
    [key: string]: any;
}
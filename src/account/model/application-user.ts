export interface ApplicationUser {
    uid: string;
    email?: string;
    emailVerified: boolean;
    displayName?: string;
    phoneNumber?: string;
    photoURL?: string;
    disabled: boolean;
    customClaims?: {
        [key: string]: any;
    };    
}
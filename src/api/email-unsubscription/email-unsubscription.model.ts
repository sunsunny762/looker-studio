export interface EmailUnsubscription {
  unsubscribeId: number;
  email: string;
  reason: string;
  details: string | null;
  unsubscribeDate: string;
  resubscribeDate: string | null;
  isUnsubscribed: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateUnsubscriptionDto {
  email: string;
  reason: string;
  details?: string | null;
}

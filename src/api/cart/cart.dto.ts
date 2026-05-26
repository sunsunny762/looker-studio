export interface CartItemDto {
  itemId: number;
  itemKey: string;
  itemLabel: string;
  unitPrice: number;
  quantity: number;
  amount: number;
  currency: string;
}

export interface CartDataDto {
  items: CartItemDto[];
  subtotal: number;
  taxAmount: number;
  couponCode?: string;
  discountType?: 'fixed' | 'percent';
  discountValue?: number;
  discountAmount: number;
  totalPayable: number;
  currency: string;
}

export interface ValidateCouponDto {
  cartConfigId: number;
  couponCode: string;
  orderAmount: number;
}

export interface CreateCheckoutSessionDto {
  formId: number;
  submissionId: number;
  userId?: number | null;
  cartConfigId: number;
  cartData: CartDataDto;
  formData: Record<string, any>;
  returnBaseUrl: string;
  returnUrl?: string;
}

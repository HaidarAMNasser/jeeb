export interface OrderPipelineContext {
  userId: number;
  ownerId: number;
  items?: { productId: number; quantity: number }[];
  offers?: SimpleOfferDto[];
  deliveryCoordinates: {
    latitude: number;
    longitude: number;
    address?: string;
    landmark?: string;
    specialInstructions?: string;
  };
  paymentMethod: string;
  deliveryFee: number;
  tipAmount: number;
  platformCommission: number;
  cityId?: number;
  areaId?: number;
  subtotal?: number;
  totalQuantity?: number;
  productDiscountTotal?: number;
  totalDiscount?: number;
  total?: number;
  orderId?: number;
  validatedProducts?: any[];
  validatedOffers?: any[];
  offerDiscountTotal?: number;
  calculatedOrderItems?: any[];
  calculatedOffers?: CalculatedOffer[];
  customerName?: string;
  phone?: string;
}

export interface CalculatedOffer {
  offerId: number;
  offerName: string;
  subtotal: number;
  totalQuantity: number;
  productDiscountTotal: number;
  discountValue: number;
  totalPrice: number;
}

export interface SimpleOfferDto {
  offerId: number;
  quantity: number;
}

export interface OrderPipelineResult {
  success: boolean;
  data?: OrderPipelineContext;
  error?: string;
  stage?: string;
}

export interface OrderPipelineStage {
  name: string;
  execute(context: OrderPipelineContext): Promise<OrderPipelineResult>;
}

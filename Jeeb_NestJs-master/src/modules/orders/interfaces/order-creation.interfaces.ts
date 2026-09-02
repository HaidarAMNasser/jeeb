import { OrderItem } from '../../../database/entities/order-item.entity';
import { Product } from '../../../database/entities/product.entity';

export interface OrderItemDto {
  productId: number;
  quantity: number;
  specialInstructions?: string;
}

export interface DeliveryCoordinates {
  latitude: number;
  longitude: number;
  address?: string;
}

export interface OrderCalculationResult {
  orderItems: OrderItem[];
  subtotal: number;
  productLevelDiscountTotal: number;
  offerDiscountTotal: number;
  offers: OfferData[];
}

export interface FinalAmountsResult {
  total: number;
  totalDiscount: number;
  deliveryFee: number;
}

export interface ProductValidationResult {
  product: Product;
  itemPrice: number;
  itemTotal: number;
  discountValue: number;
}

export interface OrderData {
  items?: OrderItemDto[];
  ownerId: number;
  deliveryCoordinates: DeliveryCoordinates;
  offers?: SimpleOfferDto[];
}

export interface SimpleOfferDto {
  offerId: number;
  quantity: number;
}

export interface OfferData {
  offer: any;
  quantity: number;
  items: OfferProductData[];
  totalPrice: number;
  discountAmount: number;
}

export interface OfferProductData {
  product: Product;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

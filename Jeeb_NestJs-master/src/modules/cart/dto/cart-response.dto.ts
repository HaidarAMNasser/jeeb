export class CustomerInfoDto {
  id: number;
  firstName: string;
  lastName: string;
  phone: string | null;
}

export class MerchantInfoDto {
  id: number;
  restaurantName: string | null;
  phone: string | null;
  address: string | null;
}

export class ProductImageDto {
  id: number;
  url: string | null;
  mobileUrl: string | null;
  thumbnailUrl: string | null;
  isMain: boolean;
}

export class ProductInfoDto {
  id: number;
  name: string;
  shortDescription: string | null;
  description: string | null;
  personCount: number | null;
  price: number;
  discount: number | null;
  discountType: string | null;
  isAvailable: boolean;
  hasStock: boolean;
  stockQuantity: number | null;
  images: ProductImageDto[];
}

export class CartItemResponseDto {
  id: number;
  product: ProductInfoDto;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
  createdAt: Date;
}

export class OfferProductInfoDto {
  id: number;
  name: string;
  price: number;
  shortDescription: string | null;
  discount: number | null;
  discountType: string | null;
  isAvailable: boolean;
  hasStock: boolean;
  stockQuantity: number | null;
  images: ProductImageDto[];
}

export class OfferInfoDto {
  id: number;
  name: string;
  description: string | null;
  discountType: string;
  discountValue: number;
  isActive: boolean;
  images: ProductImageDto[];
  products: OfferProductInfoDto[];
}

export class CartOfferResponseDto {
  id: number;
  offer: OfferInfoDto;
  quantity: number;
  subtotal: number;
  discount: number;
  createdAt: Date;
}

export class CartSummaryDto {
  itemsSubtotal: number;
  offersSubtotal: number;
  totalSubtotal: number;
  totalDiscount: number;
  finalTotal: number;
  platformCommission: number;
  merchantRevenue: number;
}

export class CartResponseDto {
  id: number;
  customer: CustomerInfoDto;
  merchant: MerchantInfoDto | null;
  items: CartItemResponseDto[];
  offers: CartOfferResponseDto[];
  summary: CartSummaryDto;
}

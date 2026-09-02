import { Order } from '../../../database/entities/order.entity';
import { OrderItem } from '../../../database/entities/order-item.entity';
import { Image } from '../../../database/entities/image.entity';
import { Product } from '../../../database/entities/product.entity';
import { Offer } from '../../../database/entities/offer.entity';
import { DiscountType, OrderStatus, MerchantType } from '../../../common/enums';
import { UserRole } from '../../../common/enums/user-role.enum';

export interface SimplifiedUser {
  id: number;
  firstName: string;
  lastName: string;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  restaurantName?: string | null;
  type?: MerchantType | null;
  location?: { lat: number; lng: number } | null;
}

export interface ProductImageResponse {
  id: number;
  url: string;
  mobileUrl: string | null;
  thumbnailUrl: string | null;
  isMain: boolean;
}

export interface OrderItemResponse {
  id: number;
  productId: number | null;
  originalUnitPrice: number;
  unitPrice: number;
  quantity: number;
  commissionRate: number;
  commissionAmount: number;
  totalCommissionAmount: number;
  productDiscountValue: number;
  totalProductDiscountValue: number;
  totalPrice: number;
}

export interface EnrichedOrderItemResponse {
  id: number;
  productId: number | null;
  product: {
    id: number;
    merchantId: number | null;
    categoryId: number | null;
    category?: any;
    name: string;
    shortDescription: string | null;
    description: string | null;
    personCount: number | null;
    price: number;
    discount: number | null;
    discountType: DiscountType | null;
    isAvailable: boolean;
    hasStock: boolean;
    stockQuantity: number | null;
    isExternal: boolean;
    externalProvider?: string | null;
    externalId?: string | null;
    externalMetadata?: Record<string, unknown> | null;
    commissionRate: number | null;
    commissionConfirmed: boolean;
    images: ProductImageResponse[];
    createdAt?: Date;
    updatedAt?: Date;
  } | null;
  originalUnitPrice: number;
  unitPrice: number;
  quantity: number;
  commissionRate: number;
  commissionAmount: number;
  totalCommissionAmount: number;
  productDiscountValue: number;
  totalProductDiscountValue: number;
  totalPrice: number;
}

export interface OfferProductResponse {
  id: number;
  productId: number;
  product: {
    id: number;
    merchantId: number | null;
    categoryId: number | null;
    category?: any;
    name: string;
    shortDescription: string | null;
    description: string | null;
    personCount: number | null;
    price: number;
    discount: number | null;
    discountType: DiscountType | null;
    isAvailable: boolean;
    hasStock: boolean;
    stockQuantity: number | null;
    isExternal: boolean;
    externalProvider?: string | null;
    externalId?: string | null;
    externalMetadata?: Record<string, unknown> | null;
    commissionRate: number | null;
    commissionConfirmed: boolean;
    images: ProductImageResponse[];
    createdAt?: Date;
    updatedAt?: Date;
  } | null;
  quantity: number;
  originalUnitPrice: number;
  discount: number;
  discountType: DiscountType | null;
  unitPrice: number;
  totalPrice: number;
  commissionRate: number;
  commissionAmount: number;
  productDiscountValue: number;
}

export interface OfferResponse {
  id: number;
  name: string;
  description: string | null;
  discountType: DiscountType | null;
  discountValue: number | null;
  isActive: boolean;
  merchantId: number | null;
  createdAt: Date;
  updatedAt: Date;
  products: OfferProductResponse[];
  totalQuantity: number;
  productInternalQuantity: number;
  subtotal: number;
  productDiscount: number;
  offerDiscount: number;
  total: number;
  commissionRate: number;
  totalCommissionAmount: number;
  totalProductDiscountValue: number;
  images: (ProductImageResponse | Image)[];
}

export interface OrderResponse {
  id: number;
  customerId: number;
  customerName: string | null;
  phone: string | null;
  customer: SimplifiedUser | null;
  ownerId: number | null | undefined;
  areaId?: number | null;
  area?: {
    id: number;
    name: string;
    price: number;
    description: string | null;
  } | null;
  owner: SimplifiedUser | null;
  paymentMethod: string;
  status: string;
  deliveryDeadline: Date | null;
  deliveryCoordinates: any;
  finalLocation: any;
  items: OrderItemResponse[] | EnrichedOrderItemResponse[];
  offers: OfferResponse[];
  itemsTotal: number;
  offersTotal: number;
  subtotal: number;
  priceBeforeDiscount: number;
  discountAmount: number;
  priceAfterProductDiscount: number;
  productDiscount: number;
  offerDiscount: number;
  tipAmount: number;
  platformCommission: number;
  ownerRevenue: number;
  deliveryFee: number;
  totalAmount: number;
  totalCommissionAmount: number;
  currencyCode: string;
  deliveryId?: number | null;
  delivery?: SimplifiedUser | null;
  remainingTime?: { text: string; minutes: number; seconds: number } | null;
  createdAt: Date;
  updatedAt: Date;
}

export class OrderResponseMapper {
  static formatRemainingTime(ms: number): string {
    if (ms <= 0) return '0 ثانية';

    const seconds = Math.floor((ms / 1000) % 60);
    const minutes = Math.floor((ms / (1000 * 60)) % 60);
    const hours = Math.floor(ms / (1000 * 60 * 60));

    const parts: string[] = [];
    if (hours > 0) parts.push(`${hours} ساعة`);
    if (minutes > 0) parts.push(`${minutes} دقيقة`);
    if (seconds > 0) parts.push(`${seconds} ثانية`);

    return parts.join(' و ');
  }

  static getVisibleStatus(status: string, role?: string): string {
    if (role === UserRole.ADMIN || role === UserRole.DELIVERY) {
      return status;
    }
    if (status === OrderStatus.PAID || status === OrderStatus.COMPLETE) {
      return OrderStatus.DELIVERED;
    }
    return status;
  }

  static getRemainingTimeObject(ms: number): {
    text: string;
    minutes: number;
    seconds: number;
  } {
    if (ms <= 0) {
      return { text: '0 ثانية', minutes: 0, seconds: 0 };
    }

    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);

    return {
      text: this.formatRemainingTime(ms),
      minutes,
      seconds: totalSeconds,
    };
  }

  static mapSimplifiedUser(user: any): SimplifiedUser | null {
    if (!user) return null;
    const result: any = {
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      phone: user.phone,
      email: user.email,
      address: user.address,
      location: user.location || null,
    };
    if (user.merchant?.restaurantName) {
      result.restaurantName = user.merchant.restaurantName;
    }
    if (user.merchant?.type) {
      result.type = user.merchant.type;
    }
    return result;
  }

  static mapOrderItem(item: OrderItem): OrderItemResponse {
    return {
      id: item.id,
      productId: item.productId,
      originalUnitPrice: item.originalUnitPrice,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
      commissionRate: 0,
      commissionAmount: 0,
      totalCommissionAmount: 0,
      productDiscountValue: item.productDiscountValue,
      totalProductDiscountValue: item.productDiscountValue * item.quantity,
      totalPrice: item.totalPrice,
    };
  }

  static mapOrderItems(items: OrderItem[]): OrderItemResponse[] {
    return items.map((item) => this.mapOrderItem(item));
  }

  static mapProductImages(images: Image[]): ProductImageResponse[] {
    return images.map((img) => ({
      id: img.id,
      url: img.url || '',
      mobileUrl: img.mobileUrl || null,
      thumbnailUrl: img.thumbnailUrl || null,
      isMain: img.isMain,
    }));
  }

  static enrichOrderItem(
    item: OrderItem,
    productMap: Map<number, Product>,
    productImagesMap: Map<number, Image[]>,
  ): EnrichedOrderItemResponse {
    const product = item.productId ? productMap.get(item.productId) : null;
    const images = item.productId
      ? productImagesMap.get(item.productId) || []
      : [];

    return {
      id: item.id,
      productId: item.productId,
      product: product
        ? {
            id: product.id,
            merchantId: product.merchantId,
            categoryId: product.categoryId,
            category: product.category,
            name: product.name,
            shortDescription: product.shortDescription,
            description: product.description,
            personCount: product.personCount,
            price: product.price,
            discount: product.discount,
            discountType: product.discountType,
            isAvailable: product.isAvailable,
            hasStock: product.hasStock,
            stockQuantity: product.stockQuantity,
            isExternal: product.isExternal,
            externalProvider: product.externalProvider,
            externalId: product.externalId,
            externalMetadata: product.externalMetadata,
            commissionRate: 0,
            commissionConfirmed: product.commissionConfirmed,
            images: this.mapProductImages(images),
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
          }
        : null,
      originalUnitPrice: item.originalUnitPrice,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
      commissionRate: 0,
      commissionAmount: 0,
      totalCommissionAmount: 0,
      productDiscountValue: item.productDiscountValue,
      totalProductDiscountValue: item.productDiscountValue * item.quantity,
      totalPrice: item.totalPrice,
    };
  }

  static enrichOfferProduct(
    op: any,
    orderItem: OrderItem | undefined,
    images: Image[],
  ): OfferProductResponse {
    const product = op.product;
    return {
      id: op.id,
      productId: op.productId,
      product: product
        ? {
            id: product.id,
            merchantId: product.merchantId,
            categoryId: product.categoryId,
            category: product.category,
            name: product.name,
            shortDescription: product.shortDescription,
            description: product.description,
            personCount: product.personCount,
            price: product.price,
            discount: product.discount,
            discountType: product.discountType,
            isAvailable: product.isAvailable,
            hasStock: product.hasStock,
            stockQuantity: product.stockQuantity,
            isExternal: product.isExternal,
            externalProvider: product.externalProvider,
            externalId: product.externalId,
            externalMetadata: product.externalMetadata,
            commissionRate: 0,
            commissionConfirmed: product.commissionConfirmed,
            images: this.mapProductImages(images),
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
          }
        : null,
      quantity: op.quantity || 1,
      originalUnitPrice: product?.price || 0,
      discount: product?.discount || 0,
      discountType: product?.discountType || null,
      unitPrice: orderItem?.unitPrice || product?.price || 0,
      totalPrice: orderItem?.totalPrice || 0,
      commissionRate: orderItem?.commissionRate || 0,
      commissionAmount: 0,
      productDiscountValue: orderItem?.productDiscountValue || 0,
    };
  }

  static enrichOffersWithTotals(
    offers: any[],
    items: OrderItem[],
    productImagesMap: Map<number, Image[]>,
  ): OfferResponse[] {
    if (!offers || offers.length === 0) {
      return [];
    }

    return offers.map((offer) => {
      const offerItems =
        items?.filter((item) => item.offerId === offer.id) || [];

      const totalQuantity = offerItems.reduce(
        (sum, item) => sum + item.quantity,
        0,
      );

      const products = (offer.offerProducts || [])
        .filter((op: any) => op.isActive && op.product)
        .map((op: any) => {
          const orderItem = offerItems.find(
            (i) => i.productId === op.productId,
          );
          const images = productImagesMap.get(op.productId) || [];
          return this.enrichOfferProduct(op, orderItem, images);
        });

      const productInternalQuantity = products.reduce(
        (sum, p) => sum + (p.quantity || 1),
        0,
      );

      const subtotal = products.reduce(
        (sum, p) => sum + (p.originalUnitPrice || 0) * (p.quantity || 1),
        0,
      );

      const productDiscount = products.reduce(
        (sum, p) => sum + (p.productDiscountValue || 0) * (p.quantity || 1),
        0,
      );

      const subtotalAfterProductDiscount = products.reduce(
        (sum, p) => sum + (p.unitPrice || 0) * (p.quantity || 1),
        0,
      );

      const subtotalWithOfferQuantity = subtotal * totalQuantity;
      const subtotalAfterProductDiscountWithQuantity =
        subtotalAfterProductDiscount * totalQuantity;
      const productDiscountWithQuantity = productDiscount * totalQuantity;

      let offerDiscountAmount = 0;
      if (offer.discountValue && offer.discountType) {
        if (offer.discountType === 'PERCENTAGE') {
          offerDiscountAmount = Math.floor(
            (subtotalAfterProductDiscountWithQuantity * offer.discountValue) /
              100,
          );
        } else {
          offerDiscountAmount = offer.discountValue * totalQuantity;
        }
      }

      const totalCommissionAmount = 0;

      const total = Math.max(
        0,
        subtotalAfterProductDiscountWithQuantity - offerDiscountAmount,
      );

      const totalProductDiscountValue = products.reduce(
        (sum, p) =>
          sum +
          (p.productDiscountValue || 0) * (p.quantity || 1) * totalQuantity,
        0,
      );

      const offerCommissionRate =
        products.length > 0 ? products[0].commissionRate || 0 : 0;

      const offerImages = productImagesMap.get(offer.id) || [];

      return {
        id: offer.id,
        name: offer.name,
        description: offer.description,
        discountType: offer.discountType,
        discountValue: offer.discountValue,
        isActive: offer.isActive,
        merchantId: offer.merchantId,
        createdAt: offer.createdAt,
        updatedAt: offer.updatedAt,
        products,
        totalQuantity,
        productInternalQuantity,
        subtotal: subtotalWithOfferQuantity,
        productDiscount: productDiscountWithQuantity,
        offerDiscount: offerDiscountAmount,
        total,
        commissionRate: offerCommissionRate,
        totalCommissionAmount: 0,
        totalProductDiscountValue,
        images: offerImages,
      };
    });
  }

  static mapOrder(order: Order, items: OrderItem[]): OrderResponse {
    const priceBeforeDiscount =
      items?.reduce(
        (sum, item) => sum + item.originalUnitPrice * item.quantity,
        0,
      ) || 0;

    const totalCommissionAmount = 0;

    const subtotal =
      items?.reduce(
        (sum, item) => sum + (item.unitPrice || 0) * item.quantity,
        0,
      ) || 0;

    const itemsTotal =
      items?.reduce((sum, item) => sum + (item.totalPrice || 0), 0) || 0;

    const offersTotal = 0;

    return {
      id: order.id,
      customerId: order.customerId,
      customerName: order.customerName,
      phone: order.phone,
      customer: this.mapSimplifiedUser(order.customer),
      ownerId: order.ownerId,
      areaId: order.areaId,
      area: order.area
        ? {
            id: order.area.id,
            name: order.area.name,
            price: order.area.price,
            description: order.area.description,
          }
        : null,
      owner: this.mapSimplifiedUser(order.owner),
      paymentMethod: order.paymentMethod,
      status: this.getVisibleStatus(order.status),
      deliveryDeadline: order.deliveryDeadline,
      deliveryCoordinates: order.deliveryCoordinates,
      finalLocation: order.finalLocation,
      items: this.mapOrderItems(items),
      offers: [],
      itemsTotal,
      offersTotal,
      subtotal,
      priceBeforeDiscount,
      discountAmount: order.discountAmount || 0,
      priceAfterProductDiscount: subtotal,
      productDiscount: priceBeforeDiscount - itemsTotal,
      offerDiscount: Math.max(
        0,
        (order.discountAmount || 0) - (priceBeforeDiscount - itemsTotal),
      ),
      tipAmount: order.tipAmount || 0,
      platformCommission: order.platformCommission || 0,
      ownerRevenue: order.ownerRevenue || 0,
      deliveryFee: order.deliveryFee || 0,
      totalAmount: order.totalAmount || 0,
      totalCommissionAmount: 0,
      currencyCode: order.currencyCode,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    };
  }

  static mapEnrichedOrder(
    order: Order,
    items: OrderItem[],
    offers: any[],
    productMap: Map<number, Product>,
    productImagesMap: Map<number, Image[]>,
  ): OrderResponse {
    const directItems = items.filter((item) => !item.offerId);
    const enrichedItems = directItems.map((item) =>
      this.enrichOrderItem(item, productMap, productImagesMap),
    );

    const enrichedOffers = this.enrichOffersWithTotals(
      offers,
      items,
      productImagesMap,
    );

    const itemsTotal =
      items?.reduce((sum, item) => sum + (item.totalPrice || 0), 0) || 0;

    const offersTotal =
      enrichedOffers?.reduce((sum, offer) => sum + (offer.total || 0), 0) || 0;

    const subtotal = itemsTotal + offersTotal;

    const priceBeforeDiscount =
      items?.reduce(
        (sum, item) => sum + (item.originalUnitPrice || 0) * item.quantity,
        0,
      ) || 0;

    const productDiscountTotal =
      items?.reduce(
        (sum, item) => sum + (item.productDiscountValue || 0) * item.quantity,
        0,
      ) || 0;

    const totalCommissionAmount = 0;

    return {
      id: order.id,
      customerId: order.customerId,
      customerName: order.customerName,
      phone: order.phone,
      customer: this.mapSimplifiedUser(order.customer),
      ownerId: order.ownerId,
      areaId: order.areaId,
      area: order.area
        ? {
            id: order.area.id,
            name: order.area.name,
            price: order.area.price,
            description: order.area.description,
          }
        : null,
      owner: this.mapSimplifiedUser(order.owner),
      paymentMethod: order.paymentMethod,
      status: this.getVisibleStatus(order.status),
      deliveryDeadline: order.deliveryDeadline,
      deliveryCoordinates: order.deliveryCoordinates,
      finalLocation: order.finalLocation,
      items: enrichedItems,
      offers: enrichedOffers,
      itemsTotal,
      offersTotal,
      subtotal,
      priceBeforeDiscount,
      discountAmount: order.discountAmount || 0,
      priceAfterProductDiscount: subtotal,
      productDiscount: priceBeforeDiscount - itemsTotal,
      offerDiscount: Math.max(
        0,
        (order.discountAmount || 0) - (priceBeforeDiscount - itemsTotal),
      ),
      tipAmount: order.tipAmount || 0,
      platformCommission: order.platformCommission || 0,
      ownerRevenue: order.ownerRevenue || 0,
      deliveryFee: order.deliveryFee || 0,
      totalAmount: order.totalAmount || 0,
      totalCommissionAmount: 0,
      currencyCode: order.currencyCode,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    };
  }
}

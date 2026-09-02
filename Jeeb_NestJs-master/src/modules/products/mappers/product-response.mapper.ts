import { Injectable } from '@nestjs/common';
import { Product } from '../../../database/entities/product.entity';
import { sanitizeMerchantForProduct } from '../../../common/utils/sanitize-merchant.util';

@Injectable()
export class ProductResponseMapper {
  formatProductResponse(
    product: Product,
    reviews?: any[],
    isFavorite?: boolean,
    cartQuantity?: number,
  ): any {
    const sanitizedMerchant = sanitizeMerchantForProduct(
      product.merchant,
      undefined,
    );

    return {
      // Basic information
      id: product.id,
      merchantId: product.merchantId,
      merchant: sanitizedMerchant,
      categoryId: product.categoryId,
      category: product.category,
      name: product.name,
      shortDescription: product.shortDescription,
      description: product.description,
      personCount: product.personCount,

      // Product status
      isAvailable: product.isAvailable,
      hasStock: product.hasStock,
      stockQuantity: product.stockQuantity,
      isExternal: product.isExternal,
      externalProvider: product.externalProvider,
      externalId: product.externalId,
      externalMetadata: product.externalMetadata,

      // Pricing information
      price: product.price,
      discount: product.discount,
      discountType: product.discountType,
      priceAfterDiscount: (product as any).priceAfterDiscount,
      commissionRate: product.commissionRate,
      commissionConfirmed: product.commissionConfirmed,
      commissionAmount: (product as any).commissionAmount,
      finalPrice: (product as any).finalPrice,

      // Favorite status
      isFavorite: isFavorite ?? false,

      // Cart status
      inCart: cartQuantity ? true : false,
      cartQuantity: cartQuantity || 0,

      // Relations (at the end)
      images: product.images,
      reviews: reviews || [],

      // Timestamps
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    };
  }
}

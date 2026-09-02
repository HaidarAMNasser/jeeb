import { Injectable } from '@nestjs/common';
import { Product } from '../../../database/entities/product.entity';
import { DiscountType } from '../../../common/enums/discount-type.enum';

@Injectable()
export class ProductPricingService {
  computePriceAfterDiscount(
    price: number,
    discount?: number | null,
    discountType?: DiscountType | null,
  ): number {
    if (!discount || !discountType) return price;
    if (discountType === DiscountType.PERCENTAGE) {
      const amount = Math.floor((price * discount) / 100);
      return Math.max(0, price - amount);
    }
    if (discountType === DiscountType.FIXED) {
      return Math.max(0, price - discount);
    }
    return price;
  }

  resolveComputedFields(products: Product | Product[]): void {
    const items = Array.isArray(products) ? products : [products];
    items.forEach((product) => {
      const priceAfterDiscount = this.computePriceAfterDiscount(
        product.price,
        product.discount ?? undefined,
        product.discountType ?? undefined,
      );

      // Commission is disabled - set to 0
      const commissionAmount = 0;

      // Final price equals price after discount (no commission added)
      const finalPrice = priceAfterDiscount;

      // Add computed fields to product
      (product as unknown as Record<string, unknown>).priceAfterDiscount =
        priceAfterDiscount;
      (product as unknown as Record<string, unknown>).commissionAmount =
        commissionAmount;
      (product as unknown as Record<string, unknown>).finalPrice = finalPrice;
    });
  }
}

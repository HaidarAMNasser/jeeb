import { Injectable } from '@nestjs/common';
import { OrderStatus } from '../../../../common/enums/order-status.enum';
import { OrderItem } from '../../../../database/entities/order-item.entity';
import {
  UpdateOrderContext,
  UpdateOrderResult,
  UpdateOrderStage,
} from '../update-order-pipeline.interfaces';
import { BaseStage } from './base-stage';
import { OffersHelper } from '../helpers/offers.helper';

@Injectable()
export class ItemManagementStage extends BaseStage {
  constructor(private readonly offersHelper: OffersHelper) {
    super(UpdateOrderStage.ITEM_MANAGEMENT);
  }

  async execute(context: UpdateOrderContext) {
    const {
      items,
      itemsByProductId,
      itemsById,
      deletedProducts,
      deletedOffers,
      order,
    } = context;

    const hasItemModification =
      (items && items.length > 0) ||
      (itemsByProductId && itemsByProductId.length > 0) ||
      (itemsById && itemsById.length > 0) ||
      (deletedProducts && deletedProducts.length > 0);

    if (!hasItemModification) {
      if (deletedOffers && deletedOffers.length > 0) {
        return this.offersHelper.handleOffersModification(
          context,
          this.orderItemRepo,
          this.productRepo,
          this.logger,
        );
      }
      return this.createSuccessResult(context);
    }

    if (!order) {
      return this.createErrorResult('Order not found', this.stageName);
    }

    if (order.status !== OrderStatus.PENDING) {
      return this.createErrorResult(
        `Cannot modify items when order is in status: ${order.status}. Modification is only allowed for PENDING orders.`,
        this.stageName,
      );
    }

    try {
      const updateItems = items || itemsByProductId || [];
      const activeItems = updateItems.filter((i) => i.quantity > 0);

      const finalItemsToProcess = [...activeItems];

      if (itemsById && itemsById.length > 0) {
        const existingItemsMap = new Map<number, OrderItem>(
          order.items.map((i) => [i.id, i]),
        );
        for (const item of itemsById) {
          const existingItem = existingItemsMap.get(item.id);
          if (!existingItem) {
            return this.createErrorResult(
              `Order item with ID ${item.id} not found`,
              this.stageName,
            );
          }
          if (item.quantity === 0) {
            continue;
          }
          finalItemsToProcess.push({
            productId: existingItem.productId,
            quantity: item.quantity,
          });
        }
      }

      if (deletedProducts && deletedProducts.length > 0) {
        for (const productId of deletedProducts) {
          const existingItem = order.items.find(
            (i) => i.productId === productId,
          );
          if (!existingItem) {
            return this.createErrorResult(
              `Product with ID ${productId} not found in order`,
              this.stageName,
            );
          }
        }
      }

      const existingItemsToKeep = order.items.filter((item) => {
        if (item.productId && deletedProducts?.includes(item.productId)) {
          return false;
        }
        const isUpdatedByProductId = activeItems.some(
          (i) => i.productId === item.productId,
        );
        if (isUpdatedByProductId) {
          return false;
        }
        const isUpdatedById = itemsById?.some((i) => i.id === item.id);
        if (isUpdatedById) {
          return false;
        }
        return true;
      });

      const allActiveItems = [
        ...finalItemsToProcess,
        ...existingItemsToKeep.map((i) => ({
          productId: i.productId,
          quantity: i.quantity,
        })),
      ];

      if (allActiveItems.length === 0) {
        return this.createErrorResult(
          'Cannot remove all items from the order. At least one item must remain.',
          this.stageName,
        );
      }

      const productIds = [...new Set(allActiveItems.map((i) => i.productId))];
      const products = await this.productRepo.findByIds(productIds);
      const productMap = new Map(products.map((p) => [p.id, p]));

      for (const item of allActiveItems) {
        const product = productMap.get(item.productId);
        if (!product) {
          return this.createErrorResult(
            `Product with ID ${item.productId} not found`,
            this.stageName,
          );
        }
        if (product.merchantId !== order.ownerId) {
          return this.createErrorResult(
            `Product ${product.name} (ID: ${item.productId}) does not belong to the restaurant associated with this order`,
            this.stageName,
          );
        }
        if (!product.isAvailable) {
          return this.createErrorResult(
            `Product ${product.name} is not available`,
            this.stageName,
          );
        }
      }

      const oldItemsMap = new Map<number, OrderItem>(
        order.items.map((i) => [i.productId!, i]),
      );

      for (const item of allActiveItems) {
        const product = productMap.get(item.productId)!;
        const oldItem = oldItemsMap.get(item.productId);
        const oldQuantity = oldItem ? oldItem.quantity : 0;
        const diff = item.quantity - oldQuantity;

        if (diff > 0 && product.hasStock) {
          const currentStock = product.stockQuantity ?? 0;
          if (currentStock < diff) {
            return this.createErrorResult(
              `Insufficient stock for product "${product.name}". Required additional: ${diff}, Available: ${currentStock}`,
              this.stageName,
            );
          }
          await this.productRepo.decrement(
            { id: product.id },
            'stockQuantity',
            diff,
          );
        } else if (diff < 0 && product.hasStock) {
          await this.productRepo.increment(
            { id: product.id },
            'stockQuantity',
            Math.abs(diff),
          );
        }
      }

      const newProductIds = new Set(allActiveItems.map((i) => i.productId));
      const deletedProductIds = new Set(deletedProducts || []);
      for (const oldItem of order.items) {
        if (
          oldItem.productId &&
          !newProductIds.has(oldItem.productId) &&
          !deletedProductIds.has(oldItem.productId)
        ) {
          const product = await this.productRepo.findOne({
            where: { id: oldItem.productId },
          });
          if (product && product.hasStock) {
            await this.productRepo.increment(
              { id: product.id },
              'stockQuantity',
              oldItem.quantity,
            );
          }
        }
        if (oldItem.productId && deletedProductIds.has(oldItem.productId)) {
          const product = await this.productRepo.findOne({
            where: { id: oldItem.productId },
          });
          if (product && product.hasStock) {
            await this.productRepo.increment(
              { id: product.id },
              'stockQuantity',
              oldItem.quantity,
            );
          }
        }
      }

      let subtotal = 0;
      let productLevelDiscountTotal = 0;
      const newOrderItems: OrderItem[] = [];

      for (const item of allActiveItems) {
        const product = productMap.get(item.productId)!;
        const itemPrice = product.price;
        const itemTotal = Math.round(itemPrice * item.quantity);
        subtotal += itemTotal;

        let bestItemDiscount = 0;
        if (product.discount && product.discount > 0) {
          let discountValue = 0;
          if (product.discountType === 'PERCENTAGE') {
            discountValue = (itemPrice * product.discount) / 100;
          } else if (product.discountType === 'FIXED') {
            discountValue = product.discount;
          }
          bestItemDiscount = Math.min(discountValue, itemPrice);
        }
        productLevelDiscountTotal += Math.round(
          bestItemDiscount * item.quantity,
        );

        const existingOrderItem = order.items.find(
          (i) => i.productId === item.productId,
        );

        const orderItem = this.orderItemRepo.create({
          orderId: order.id,
          productId: product.id,
          productName: product.name,
          quantity: item.quantity,
          originalUnitPrice: Math.round(product.price),
          unitPrice: Math.round(itemPrice),
          totalPrice: itemTotal,
          offerId: existingOrderItem?.offerId,
        });
        newOrderItems.push(orderItem);
      }

      const deliveryFee = order.deliveryFee || 0;
      const platformCommission = order.platformCommission || 0;
      const tax = 0;
      const totalAmount = Math.round(
        subtotal -
          productLevelDiscountTotal +
          deliveryFee +
          platformCommission +
          tax +
          (order.tipAmount || 0),
      );

      order.totalAmount = totalAmount;
      order.discountAmount = Math.round(productLevelDiscountTotal);

      await this.orderItemRepo.delete({ orderId: order.id });
      await this.orderItemRepo.save(newOrderItems);

      context.order = order;
      context.order.items = newOrderItems;

      if (deletedOffers && deletedOffers.length > 0) {
        return this.offersHelper.handleOffersModification(
          context,
          this.orderItemRepo,
          this.productRepo,
          this.logger,
        );
      }

      return this.createSuccessResult(context);
    } catch (error) {
      return this.handleError(error, this.stageName);
    }
  }
}

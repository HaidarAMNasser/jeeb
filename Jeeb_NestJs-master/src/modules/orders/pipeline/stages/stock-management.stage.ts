import { Injectable } from '@nestjs/common';
import { OrderStatus } from '../../../../common/enums/order-status.enum';
import {
  UpdateOrderContext,
  UpdateOrderResult,
  UpdateOrderStage,
} from '../update-order-pipeline.interfaces';
import { BaseStage } from './base-stage';

@Injectable()
export class StockManagementStage extends BaseStage {
  constructor() {
    super(UpdateOrderStage.STOCK_MANAGEMENT);
  }

  async execute(context: UpdateOrderContext) {
    try {
      const { order, newStatus } = context;
      const currentStatus = order?.status;

      if (
        newStatus === OrderStatus.CANCELLED ||
        newStatus === OrderStatus.REJECTED
      ) {
        return this.handleCancellation(context);
      }

      if (currentStatus === OrderStatus.CANCELLED) {
        return this.handleRestore(context);
      }

      return this.createSuccessResult(context);
    } catch (error) {
      return this.handleError(error, this.stageName);
    }
  }

  private async handleCancellation(context: UpdateOrderContext) {
    const { order } = context;

    if (!order?.items || order.items.length === 0) {
      return this.createSuccessResult(context);
    }

    const productIds = order.items
      .map((item) => item.productId)
      .filter((id): id is number => id !== null);

    if (productIds.length === 0) {
      return this.createSuccessResult(context);
    }

    const products = await this.productRepo.findByIds(productIds);
    const productMap = new Map(products.map((p) => [p.id, p]));

    let restoredCount = 0;
    let skippedCount = 0;

    for (const item of order.items) {
      if (!item.productId) continue;

      const product = productMap.get(item.productId);

      if (product && product.hasStock) {
        const currentStock = product.stockQuantity ?? 0;
        await this.productRepo.increment(
          { id: item.productId },
          'stockQuantity',
          item.quantity,
        );
        restoredCount++;

        this.logger.log(
          `Restored ${item.quantity} units to product "${product.name}" (ID: ${item.productId}). Stock: ${currentStock} -> ${currentStock + item.quantity}`,
        );
      } else if (product) {
        skippedCount++;
        this.logger.debug(
          `Skipped stock restoration for product "${product.name}" (ID: ${item.productId}) - hasStock is false or product doesn't track inventory`,
        );
      }
    }

    this.logger.log(
      `Stock restoration complete for order ${context.orderId}. Restored: ${restoredCount}, Skipped: ${skippedCount}`,
    );

    return this.createSuccessResult(context);
  }

  private async handleRestore(context: UpdateOrderContext) {
    const { order, newStatus } = context;

    if (!order?.items || order.items.length === 0) {
      return this.createSuccessResult(context);
    }

    const productIds = order.items
      .map((item) => item.productId)
      .filter((id): id is number => id !== null);

    if (productIds.length === 0) {
      return this.createSuccessResult(context);
    }

    const products = await this.productRepo.findByIds(productIds);
    const productMap = new Map(products.map((p) => [p.id, p]));

    let deductedCount = 0;
    let failedCount = 0;

    for (const item of order.items) {
      if (!item.productId) continue;

      const product = productMap.get(item.productId);

      if (product && product.hasStock) {
        const currentStock = product.stockQuantity ?? 0;

        if (currentStock < item.quantity) {
          this.logger.error(
            `Cannot restore order - insufficient stock for product "${product.name}". Available: ${currentStock}, Required: ${item.quantity}`,
          );
          failedCount++;
          continue;
        }

        await this.productRepo.decrement(
          { id: product.id },
          'stockQuantity',
          item.quantity,
        );
        deductedCount++;

        this.logger.log(
          `Deducted ${item.quantity} units from product "${product.name}" (ID: ${item.productId}). Stock: ${currentStock} -> ${currentStock - item.quantity}`,
        );
      } else if (product) {
        this.logger.debug(
          `Skipped stock deduction for product "${product.name}" (ID: ${item.productId}) - hasStock is false or product doesn't track inventory`,
        );
      }
    }

    if (failedCount > 0) {
      return this.createErrorResult(
        'Cannot restore order - insufficient stock for some products',
        this.stageName,
      );
    }

    this.logger.log(
      `Stock deduction complete for order ${context.orderId}. Deducted: ${deductedCount}`,
    );

    return this.createSuccessResult(context);
  }
}

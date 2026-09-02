import { Injectable, Logger } from '@nestjs/common';
import { Repository } from 'typeorm';
import { OrderItem } from '../../../../database/entities/order-item.entity';
import { Product } from '../../../../database/entities/product.entity';
import { OrderStatus } from '../../../../common/enums/order-status.enum';
import {
  UpdateOrderContext,
  UpdateOrderResult,
  UpdateOrderStage,
} from '../update-order-pipeline.interfaces';

@Injectable()
export class OffersHelper {
  async handleOffersModification(
    context: UpdateOrderContext,
    orderItemRepo: Repository<OrderItem>,
    productRepo: Repository<Product>,
    logger: Logger,
  ): Promise<UpdateOrderResult> {
    const { order, deletedOffers } = context;

    if (!order) {
      return {
        success: false,
        error: 'Order not found',
        stage: UpdateOrderStage.ITEM_MANAGEMENT,
      };
    }

    if (order.status !== OrderStatus.PENDING) {
      return {
        success: false,
        error: `Cannot modify offers when order is in status: ${order.status}. Modification is only allowed for PENDING orders.`,
        stage: UpdateOrderStage.ITEM_MANAGEMENT,
      };
    }

    try {
      if (deletedOffers && deletedOffers.length > 0) {
        const currentOfferIds = order.offers?.map((o) => o.id) || [];
        const invalidOfferIds = deletedOffers.filter(
          (id) => !currentOfferIds.includes(id),
        );

        if (invalidOfferIds.length > 0) {
          return {
            success: false,
            error: `Offers with IDs ${invalidOfferIds.join(', ')} not found in order`,
            stage: UpdateOrderStage.ITEM_MANAGEMENT,
          };
        }

        const offerItemsToRemove = order.items.filter(
          (item) => item.offerId && deletedOffers.includes(item.offerId),
        );

        for (const item of offerItemsToRemove) {
          if (item.productId) {
            const product = await productRepo.findOne({
              where: { id: item.productId },
            });
            if (product && product.hasStock) {
              await productRepo.increment(
                { id: product.id },
                'stockQuantity',
                item.quantity,
              );
            }
          }
        }

        const offerItemIds = order.items
          .filter(
            (item) => item.offerId && deletedOffers.includes(item.offerId),
          )
          .map((item) => item.id);

        if (offerItemIds.length > 0) {
          await orderItemRepo.delete(offerItemIds);
        }
      }

      return { success: true, data: context };
    } catch (error) {
      logger.error(
        `Offers modification failed: ${error instanceof Error ? error.message : String(error)}`,
        error instanceof Error ? error.stack : undefined,
      );
      return {
        success: false,
        error: `Offers modification failed: ${error instanceof Error ? error.message : String(error)}`,
        stage: UpdateOrderStage.ITEM_MANAGEMENT,
      };
    }
  }
}

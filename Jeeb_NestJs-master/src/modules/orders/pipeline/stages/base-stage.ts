import { Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../../../../database/entities/order.entity';
import { OrderItem } from '../../../../database/entities/order-item.entity';
import { Product } from '../../../../database/entities/product.entity';
import {
  UpdateOrderContext,
  UpdateOrderResult,
  UpdateOrderStage,
} from '../update-order-pipeline.interfaces';

export type { UpdateOrderContext, UpdateOrderResult, UpdateOrderStage };

export abstract class BaseStage {
  protected readonly logger: Logger;

  @InjectRepository(Order)
  protected readonly orderRepo: Repository<Order>;

  @InjectRepository(OrderItem)
  protected readonly orderItemRepo: Repository<OrderItem>;

  @InjectRepository(Product)
  protected readonly productRepo: Repository<Product>;

  constructor(protected readonly stageName: UpdateOrderStage) {
    this.logger = new Logger(`${BaseStage.name}-${stageName}`);
  }

  abstract execute(context: UpdateOrderContext): Promise<UpdateOrderResult>;

  protected createSuccessResult(
    context: UpdateOrderContext,
  ): UpdateOrderResult {
    return { success: true, data: context };
  }

  protected createErrorResult(
    error: string,
    stage: UpdateOrderStage,
  ): UpdateOrderResult {
    return { success: false, error, stage };
  }

  protected handleError(
    error: unknown,
    stage: UpdateOrderStage,
  ): UpdateOrderResult {
    const message = error instanceof Error ? error.message : String(error);
    this.logger.error(`Stage ${stage} failed: ${message}`);
    return this.createErrorResult(message, stage);
  }
}

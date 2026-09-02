import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { OrderItem } from '../../../database/entities/order-item.entity';
import { Product } from '../../../database/entities/product.entity';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { UserRole } from '../../../common/enums/user-role.enum';
import {
  UpdateOrderContext,
  UpdateOrderResult,
  UpdateOrderStage,
  UpdateOrderPipelineStage,
} from './update-order-pipeline.interfaces';
import { ValidationStage } from './stages/validation.stage';
import { AuthorizationStage } from './stages/authorization.stage';
import { StatusTransitionStage } from './stages/status-transition.stage';
import { StockManagementStage } from './stages/stock-management.stage';
import { ItemManagementStage } from './stages/item-management.stage';
import { StatusUpdateStage } from './stages/status-update.stage';
import { NotificationStage } from './stages/notification.stage';

@Injectable()
export class UpdateOrderPipeline {
  private readonly logger = new Logger(UpdateOrderPipeline.name);
  private stages: UpdateOrderPipelineStage[] = [];

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(OrderItem)
    private readonly orderItemRepo: Repository<OrderItem>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    private readonly validationStage: ValidationStage,
    private readonly authorizationStage: AuthorizationStage,
    private readonly statusTransitionStage: StatusTransitionStage,
    private readonly stockManagementStage: StockManagementStage,
    private readonly itemManagementStage: ItemManagementStage,
    private readonly statusUpdateStage: StatusUpdateStage,
    private readonly notificationStage: NotificationStage,
  ) {
    this.initializeStages();
  }

  private initializeStages(): void {
    this.stages = [
      {
        stage: UpdateOrderStage.VALIDATION,
        execute: this.validationStage.execute.bind(this.validationStage),
      },
      {
        stage: UpdateOrderStage.AUTHORIZATION,
        execute: this.authorizationStage.execute.bind(this.authorizationStage),
      },
      {
        stage: UpdateOrderStage.STATUS_TRANSITION,
        execute: this.statusTransitionStage.execute.bind(
          this.statusTransitionStage,
        ),
      },
      {
        stage: UpdateOrderStage.STOCK_MANAGEMENT,
        execute: this.stockManagementStage.execute.bind(
          this.stockManagementStage,
        ),
      },
      {
        stage: UpdateOrderStage.ITEM_MANAGEMENT,
        execute: this.itemManagementStage.execute.bind(
          this.itemManagementStage,
        ),
      },
      {
        stage: UpdateOrderStage.STATUS_UPDATE,
        execute: this.statusUpdateStage.execute.bind(this.statusUpdateStage),
      },
      {
        stage: UpdateOrderStage.NOTIFICATION,
        execute: this.notificationStage.execute.bind(this.notificationStage),
      },
    ];
  }

  async execute(
    orderId: number,
    newStatus: OrderStatus,
    userId: number,
    role: UserRole,
    reason?: string,
    finalLocation?: { lat: number; lng: number },
    mealPreparationTime?: number,
    deliveryTime?: number,
    items?: any[],
    itemsByProductId?: any[],
    itemsById?: any[],
    offersByOfferId?: any[],
    offersById?: any[],
    deletedProducts?: number[],
    deletedOffers?: number[],
    customerName?: string,
    phone?: string,
  ): Promise<UpdateOrderResult> {
    const context: UpdateOrderContext = {
      orderId,
      newStatus,
      userId,
      role,
      reason,
      finalLocation,
      mealPreparationTime,
      deliveryTime,
      items,
      itemsByProductId,
      itemsById,
      offersByOfferId,
      offersById,
      deletedProducts,
      deletedOffers,
      customerName,
      phone,
    };

    for (const stage of this.stages) {
      this.logger.debug(`Executing stage: ${stage.stage}`);
      const result = await stage.execute(context);

      if (!result.success) {
        this.logger.warn(`Stage ${stage.stage} failed: ${result.error}`);
        return result;
      }

      if (result.data?.order) {
        context.order = result.data.order;
      }
    }

    return {
      success: true,
      data: context,
    };
  }
}

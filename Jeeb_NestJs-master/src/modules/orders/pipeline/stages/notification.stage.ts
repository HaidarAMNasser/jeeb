import { Injectable } from '@nestjs/common';
import { OrderStatus } from '../../../../common/enums/order-status.enum';
import {
  UpdateOrderContext,
  UpdateOrderResult,
  UpdateOrderStage,
} from '../update-order-pipeline.interfaces';
import { BaseStage } from './base-stage';
import { OrderActionsService } from '../../services/order-actions.service';

@Injectable()
export class NotificationStage extends BaseStage {
  constructor(private readonly orderActionsService: OrderActionsService) {
    super(UpdateOrderStage.NOTIFICATION);
  }

  async execute(context: UpdateOrderContext): Promise<UpdateOrderResult> {
    try {
      if (context.order) {
        this.logger.log(
          `Triggering status notifications for order ${context.orderId} to status ${context.newStatus}`,
        );
        await this.orderActionsService.sendStatusNotifications(
          context.order,
          context.newStatus,
        );
      }

      if (context.newStatus === OrderStatus.READY_FOR_PICKUP) {
        this.logger.log(
          `Order ${context.orderId} is ready for pickup - additional notifications handled by service`,
        );
      }

      return this.createSuccessResult(context);
    } catch (error) {
      return this.handleError(error, this.stageName);
    }
  }
}

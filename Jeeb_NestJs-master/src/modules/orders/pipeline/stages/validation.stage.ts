import { Injectable } from '@nestjs/common';
import { ErrorCodes } from '../../../../common/constants/error-codes';
import {
  UpdateOrderContext,
  UpdateOrderResult,
  UpdateOrderStage,
} from '../update-order-pipeline.interfaces';
import { BaseStage } from './base-stage';

@Injectable()
export class ValidationStage extends BaseStage {
  constructor() {
    super(UpdateOrderStage.VALIDATION);
  }

  async execute(context: UpdateOrderContext): Promise<UpdateOrderResult> {
    try {
      if (!context.orderId || context.orderId <= 0) {
        return this.createErrorResult(
          ErrorCodes.INVALID_ORDER_ID.message,
          this.stageName,
        );
      }

      if (!context.newStatus) {
        return this.createErrorResult(
          ErrorCodes.INVALID_STATUS_TRANSITION.message,
          this.stageName,
        );
      }

      const order = await this.orderRepo.findOne({
        where: { id: context.orderId },
        relations: [
          'customer',
          'owner',
          'items',
          'offers',
          'deliveryAssignments',
        ],
      });

      if (!order) {
        return this.createErrorResult(
          `${ErrorCodes.ORDER_NOT_FOUND.message} (ID: ${context.orderId})`,
          this.stageName,
        );
      }

      return this.createSuccessResult({ ...context, order });
    } catch (error) {
      return this.handleError(error, this.stageName);
    }
  }
}

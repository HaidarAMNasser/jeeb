import { Injectable } from '@nestjs/common';
import { OrderStatus } from '../../../../common/enums/order-status.enum';
import { ErrorCodes } from '../../../../common/constants/error-codes';
import {
  ALLOWED_STATUS_TRANSITIONS,
  CANCELLATION_TIME_LIMIT_MS,
} from '../constants/order-status.constants';
import {
  UpdateOrderContext,
  UpdateOrderResult,
  UpdateOrderStage,
} from '../update-order-pipeline.interfaces';
import { BaseStage } from './base-stage';

@Injectable()
export class StatusTransitionStage extends BaseStage {
  constructor() {
    super(UpdateOrderStage.STATUS_TRANSITION);
  }

  async execute(context: UpdateOrderContext) {
    await Promise.resolve();

    const { order, newStatus } = context;

    if (!order) {
      return this.createErrorResult(
        ErrorCodes.ORDER_NOT_FOUND.message,
        this.stageName,
      );
    }

    const currentStatus = order.status;

    if (currentStatus === OrderStatus.DELIVERED) {
      return this.createErrorResult(
        ErrorCodes.ORDER_ALREADY_DELIVERED.message,
        this.stageName,
      );
    }

    if (currentStatus === OrderStatus.CANCELLED) {
      const allowedRestoreTransitions =
        ALLOWED_STATUS_TRANSITIONS[OrderStatus.CANCELLED] ?? [];

      if (allowedRestoreTransitions.includes(newStatus)) {
        if (order.cancelledAt) {
          const timeSinceCancelled =
            Date.now() - new Date(order.cancelledAt).getTime();

          if (timeSinceCancelled > CANCELLATION_TIME_LIMIT_MS) {
            return this.createErrorResult(
              'Cannot restore order - the 3-minute window has expired',
              this.stageName,
            );
          }
        } else {
          return this.createErrorResult(
            'Cannot restore order - cancellation time not recorded',
            this.stageName,
          );
        }
      } else {
        return this.createErrorResult(
          ErrorCodes.ORDER_ALREADY_CANCELLED.message,
          this.stageName,
        );
      }
    }

    const allowedTransitions = ALLOWED_STATUS_TRANSITIONS[currentStatus] ?? [];

    if (!allowedTransitions.includes(newStatus)) {
      return this.createErrorResult(
        `${ErrorCodes.INVALID_STATUS_TRANSITION.message}: Cannot change from "${currentStatus}" to "${newStatus}". Allowed: ${allowedTransitions.join(', ') || 'none'}`,
        this.stageName,
      );
    }

    return this.createSuccessResult(context);
  }
}

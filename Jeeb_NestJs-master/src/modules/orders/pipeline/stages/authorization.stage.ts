import { Injectable } from '@nestjs/common';
import { UserRole } from '../../../../common/enums/user-role.enum';
import { ErrorCodes } from '../../../../common/constants/error-codes';
import { ROLE_PERMISSIONS } from '../constants/order-status.constants';
import {
  UpdateOrderContext,
  UpdateOrderResult,
  UpdateOrderStage,
} from '../update-order-pipeline.interfaces';
import { BaseStage } from './base-stage';

@Injectable()
export class AuthorizationStage extends BaseStage {
  constructor() {
    super(UpdateOrderStage.AUTHORIZATION);
  }

  async execute(context: UpdateOrderContext) {
    await Promise.resolve();

    const { order, role, userId, newStatus } = context;

    if (!order) {
      return this.createErrorResult(
        ErrorCodes.ORDER_NOT_FOUND.message,
        this.stageName,
      );
    }

    const allowedStatuses = ROLE_PERMISSIONS[role] ?? [];

    if (!allowedStatuses.includes(newStatus)) {
      return this.createErrorResult(
        `${ErrorCodes.UNAUTHORIZED_STATUS_CHANGE.message}. Role "${role}" cannot change status to "${newStatus}"`,
        this.stageName,
      );
    }

    if (role === UserRole.CUSTOMER && order.customerId !== userId) {
      return this.createErrorResult(
        ErrorCodes.CUSTOMER_CANNOT_UPDATE_OTHER_ORDERS.message,
        this.stageName,
      );
    }

    if (role === UserRole.MERCHANT && order.ownerId !== userId) {
      return this.createErrorResult(
        ErrorCodes.MERCHANT_CANNOT_UPDATE_OTHER_RESTAURANT_ORDERS.message,
        this.stageName,
      );
    }

    return this.createSuccessResult(context);
  }
}

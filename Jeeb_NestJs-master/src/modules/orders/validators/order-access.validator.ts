import {
  Injectable,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { SelectQueryBuilder } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { UserRole } from '../../../common/enums/user-role.enum';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { Brackets } from 'typeorm';
import {
  OrderAccessContext,
  OrderValidationResult,
} from '../interfaces/order-management.interfaces';
import { SettingsService } from '../../settings/settings.service';

@Injectable()
export class OrderAccessValidator {
  constructor(private readonly settingsService: SettingsService) {}

  async applyRoleBasedFiltering(
    queryBuilder: SelectQueryBuilder<Order>,
    role: UserRole,
    userId: number,
  ): Promise<void> {
    if (role === UserRole.ADMIN) {
      return;
    }

    if (role === UserRole.MERCHANT) {
      queryBuilder.andWhere('order.ownerId = :userId', { userId });
      // Also show PAID and COMPLETE orders (shown as DELIVERED in response)
      return;
    }

    if (role === UserRole.DELIVERY) {
      queryBuilder.andWhere(
        new Brackets((qb) => {
          // For SEARCHING status: Show orders that this driver was notified about (NOTIFIED or EXPIRED)
          qb.where(
            new Brackets((inner) => {
              inner
                .where('order.status = :searchingStatus', {
                  searchingStatus: OrderStatus.SEARCHING,
                })
                .andWhere('assignment.deliveryId = :driverUserId', {
                  driverUserId: userId,
                })
                .andWhere('assignment.status IN (:...notifiedStatuses)', {
                  notifiedStatuses: [
                    DeliveryStatus.NOTIFIED,
                    DeliveryStatus.EXPIRED,
                  ],
                });
            }),
          ).orWhere(
            // For ASSIGNED, READY_FOR_PICKUP, PICKED_UP, ON_THE_WAY, DELIVERED, PAID, COMPLETE, CANCELLED: Show orders assigned to this driver
            new Brackets((inner) => {
              inner
                .where('order.status IN (:...assignedStatuses)', {
                  assignedStatuses: [
                    OrderStatus.ASSIGNED,
                    OrderStatus.PREPARING,
                    OrderStatus.READY_FOR_PICKUP,
                    OrderStatus.PICKED_UP,
                    OrderStatus.ON_THE_WAY,
                    OrderStatus.DELIVERED,
                    OrderStatus.PAID,
                    OrderStatus.COMPLETE,
                    OrderStatus.CANCELLED,
                  ],
                })
                .andWhere('assignment.deliveryId = :assignedDriverId', {
                  assignedDriverId: userId,
                });
            }),
          );
        }),
      );
      return;
    }

    if (role === UserRole.CUSTOMER) {
      queryBuilder.andWhere('order.customerId = :userId', { userId });
      // Also include PAID and COMPLETE orders when filtering by DELIVERED status
      // because for customer, PAID/COMPLETE should show as DELIVERED in response
    }
  }

  validateOrderAccess(
    order: Order,
    context: OrderAccessContext,
  ): OrderValidationResult {
    const { role, userId } = context;

    if (role === UserRole.ADMIN) {
      return { canAccess: true };
    }

    if (role === UserRole.MERCHANT && order.ownerId === userId) {
      return { canAccess: true };
    }

    if (role === UserRole.CUSTOMER && order.customerId === userId) {
      return { canAccess: true };
    }

    if (
      role === UserRole.DELIVERY &&
      order.deliveryAssignments?.some((a) => a.deliveryId === userId)
    ) {
      return { canAccess: true };
    }

    return {
      canAccess: false,
      reason: 'Access denied: insufficient permissions for this order',
    };
  }

  validateOrderModificationAccess(
    order: Order,
    role: UserRole,
    userId: number,
    action: string,
  ): void {
    if (role === UserRole.ADMIN) {
      return;
    }

    if (role === UserRole.MERCHANT) {
      if (order.ownerId !== userId) {
        throw new ForbiddenException(
          `You can only ${action} orders for your own shop`,
        );
      }
      return;
    }

    throw new ForbiddenException(
      `Only merchants and admins can ${action} orders`,
    );
  }

  validateOrderStatusUpdateAccess(
    order: Order,
    newStatus: OrderStatus,
    role: UserRole,
    userId: number,
  ): void {
    if (role === UserRole.ADMIN) {
      return;
    }

    if (role === UserRole.MERCHANT) {
      if (order.ownerId !== userId) {
        throw new ForbiddenException(
          'You can only update orders for your own shop',
        );
      }
      return;
    }

    if (role === UserRole.CUSTOMER) {
      if (order.customerId !== userId) {
        throw new ForbiddenException('You can only update your own orders');
      }

      if (newStatus !== OrderStatus.CANCELLED) {
        throw new ForbiddenException(
          'Customers can only cancel orders, not change to other statuses',
        );
      }

      const allowedCancelStatuses = [
        OrderStatus.PENDING,
        OrderStatus.CONFIRMED,
        OrderStatus.SEARCHING,
        OrderStatus.ASSIGNED,
        OrderStatus.PREPARING,
        OrderStatus.READY_FOR_PICKUP,
      ];

      if (!allowedCancelStatuses.includes(order.status)) {
        throw new BadRequestException(
          `Customers can only cancel orders in early stages (up to Ready for Pickup). Current status is ${order.status}`,
        );
      }
    }
  }

  validateStatusTransition(
    currentStatus: OrderStatus,
    newStatus: OrderStatus,
  ): void {
    const allowedTransitions: Record<OrderStatus, OrderStatus[]> = {
      [OrderStatus.PENDING]: [
        OrderStatus.CONFIRMED,
        OrderStatus.REJECTED,
        OrderStatus.CANCELLED,
      ],
      [OrderStatus.CONFIRMED]: [
        OrderStatus.SEARCHING,
        OrderStatus.PREPARING,
        OrderStatus.CANCELLED,
      ],
      [OrderStatus.SEARCHING]: [
        OrderStatus.ASSIGNED,
        OrderStatus.PREPARING,
        OrderStatus.READY_FOR_PICKUP,
        OrderStatus.CANCELLED,
      ],
      [OrderStatus.READY_FOR_PICKUP]: [
        OrderStatus.ASSIGNED,
        OrderStatus.CANCELLED,
      ],
      [OrderStatus.ASSIGNED]: [
        OrderStatus.PICKED_UP,
        OrderStatus.PREPARING,
        OrderStatus.CANCELLED,
      ],
      [OrderStatus.PREPARING]: [
        OrderStatus.READY_FOR_PICKUP,
        OrderStatus.SEARCHING,
        OrderStatus.CANCELLED,
      ],
      [OrderStatus.PICKED_UP]: [OrderStatus.ON_THE_WAY, OrderStatus.DELIVERED],
      [OrderStatus.ON_THE_WAY]: [OrderStatus.DELIVERED],
      [OrderStatus.DELIVERED]: [OrderStatus.PAID],
      [OrderStatus.PAID]: [OrderStatus.COMPLETE, OrderStatus.CANCELLED],
      [OrderStatus.COMPLETE]: [],
      [OrderStatus.CANCELLED]: [OrderStatus.PENDING, OrderStatus.CONFIRMED],
      [OrderStatus.REJECTED]: [],
    };

    if (!allowedTransitions[currentStatus].includes(newStatus)) {
      throw new BadRequestException(
        `Cannot transition from ${currentStatus} to ${newStatus}. Allowed transitions: ${allowedTransitions[currentStatus].join(', ')}`,
      );
    }
  }
}

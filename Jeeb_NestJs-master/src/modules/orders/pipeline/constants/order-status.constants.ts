import { OrderStatus } from '../../../../common/enums/order-status.enum';
import { UserRole } from '../../../../common/enums/user-role.enum';

export const ALLOWED_STATUS_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
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
    OrderStatus.READY_FOR_PICKUP,
    OrderStatus.PREPARING,
    OrderStatus.CANCELLED,
  ],
  [OrderStatus.READY_FOR_PICKUP]: [
    OrderStatus.ASSIGNED,
    OrderStatus.PICKED_UP,
    OrderStatus.CANCELLED,
  ],
  [OrderStatus.ASSIGNED]: [
    OrderStatus.PICKED_UP,
    OrderStatus.READY_FOR_PICKUP,
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

export const ROLE_PERMISSIONS: Record<UserRole, OrderStatus[]> = {
  [UserRole.CUSTOMER]: [OrderStatus.CANCELLED],
  [UserRole.MERCHANT]: [
    OrderStatus.CONFIRMED,
    OrderStatus.SEARCHING,
    OrderStatus.READY_FOR_PICKUP,
    OrderStatus.PICKED_UP,
    OrderStatus.REJECTED,
    OrderStatus.PREPARING,
    OrderStatus.CANCELLED,
    OrderStatus.PENDING,
  ],
  [UserRole.DELIVERY]: [
    OrderStatus.PICKED_UP,
    OrderStatus.ON_THE_WAY,
    OrderStatus.DELIVERED,
    OrderStatus.PAID,
    OrderStatus.ASSIGNED,
    OrderStatus.SEARCHING,
    OrderStatus.PREPARING,
    OrderStatus.READY_FOR_PICKUP,
  ],
  [UserRole.ADMIN]: Object.values(OrderStatus),
  [UserRole.OFFICE_OWNER]: [],
  [UserRole.SUPPORT]: [],
};

export const CANCELLATION_TIME_LIMIT_MS = 3 * 60 * 1000;

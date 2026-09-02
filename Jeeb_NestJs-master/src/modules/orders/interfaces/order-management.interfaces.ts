import { Order } from '../../../database/entities/order.entity';
import { UserRole } from '../../../common/enums/user-role.enum';
import { OrderStatus } from '../../../common/enums/order-status.enum';

export interface OrderFilterOptions {
  status?: OrderStatus;
  customerId?: number;
  ownerId?: number;
  startDate?: Date;
  endDate?: Date;
}

export interface OrderAccessContext {
  role: UserRole;
  userId: number;
}

export interface OrderValidationResult {
  canAccess: boolean;
  reason?: string;
}

export interface OrderUpdateData {
  status?: OrderStatus;
  rejectionReason?: string;
  cancellationReason?: string;
}

export interface OrderManagementResult {
  order: Order;
  message: string;
}

import { Order } from '../../../database/entities/order.entity';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { UserRole } from '../../../common/enums/user-role.enum';

export enum UpdateOrderStage {
  VALIDATION = 'Validation',
  AUTHORIZATION = 'Authorization',
  STATUS_TRANSITION = 'StatusTransition',
  STOCK_MANAGEMENT = 'StockManagement',
  STATUS_UPDATE = 'StatusUpdate',
  ITEM_MANAGEMENT = 'ItemManagement',
  NOTIFICATION = 'Notification',
}

export interface UpdateOrderContext {
  orderId: number;
  newStatus: OrderStatus;
  userId: number;
  role: UserRole;
  reason?: string;
  finalLocation?: { lat: number; lng: number };
  mealPreparationTime?: number;
  deliveryTime?: number;
  items?: any[];
  order?: Order;
  itemsByProductId?: any[];
  itemsById?: any[];
  offersByOfferId?: any[];
  offersById?: any[];
  deletedProducts?: number[];
  deletedOffers?: number[];
  customerName?: string;
  phone?: string;
}

export interface UpdateOrderResult {
  success: boolean;
  data?: UpdateOrderContext;
  error?: string;
  stage?: UpdateOrderStage;
}

export interface UpdateOrderPipelineStage {
  stage: UpdateOrderStage;
  execute(context: UpdateOrderContext): Promise<UpdateOrderResult>;
}

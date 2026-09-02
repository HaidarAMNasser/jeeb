import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { OrderItem } from '../../../database/entities/order-item.entity';
import { Product } from '../../../database/entities/product.entity';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { OrderStatus, DeliveryStatus } from '../../../common/enums';
import { UserRole } from '../../../common/enums/user-role.enum';
import { NotificationType } from '../../../common/enums/notification-type.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { OrderAccessValidator } from '../validators/order-access.validator';
import { DeliveryNotificationService } from './delivery-notification.service';
import { FirebaseService } from '../../firebase/firebase.service';
import { DeliveryAssignmentService } from './delivery-assignment.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { forwardRef, Inject } from '@nestjs/common';

@Injectable()
export class OrderActionsService {
  private readonly logger = new Logger(OrderActionsService.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(OrderItem)
    private readonly orderItemRepo: Repository<OrderItem>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(DeliveryAssignment)
    private readonly deliveryAssignmentRepo: Repository<DeliveryAssignment>,
    private readonly orderAccessValidator: OrderAccessValidator,
    private readonly deliveryNotificationService: DeliveryNotificationService,
    private readonly notificationsService: NotificationsService,
    private readonly firebaseService: FirebaseService,
    @Inject(forwardRef(() => DeliveryAssignmentService))
    private readonly deliveryAssignmentService: DeliveryAssignmentService,
  ) {}

  async confirmOrder(
    orderId: number,
    userId: number,
    role: UserRole,
  ): Promise<Order> {
    const order = await this.orderRepo.findOne({
      where: { id: orderId },
      relations: ['owner', 'items', 'deliveryAssignments'],
    });

    if (!order) {
      throw new NotFoundException(`Order with ID ${orderId} not found`);
    }

    this.orderAccessValidator.validateOrderModificationAccess(
      order,
      role,
      userId,
      'confirm',
    );

    if (order.status !== OrderStatus.PENDING) {
      throw new BadRequestException(
        `Cannot confirm order with status ${order.status}. Only PENDING orders can be confirmed.`,
      );
    }

    order.status = OrderStatus.CONFIRMED;
    await this.orderRepo.save(order);

    return order;
  }

  async rejectOrder(
    orderId: number,
    userId: number,
    role: UserRole,
    reason?: string,
  ): Promise<Order> {
    const order = await this.orderRepo.findOne({
      where: { id: orderId },
      relations: ['owner', 'items', 'deliveryAssignments'],
    });

    if (!order) {
      throw new NotFoundException(`Order with ID ${orderId} not found`);
    }

    this.orderAccessValidator.validateOrderModificationAccess(
      order,
      role,
      userId,
      'reject',
    );

    if (order.status !== OrderStatus.PENDING) {
      throw new BadRequestException(
        `Cannot reject order with status ${order.status}. Only PENDING orders can be rejected.`,
      );
    }

    await this.restoreStock(order);

    order.status = OrderStatus.REJECTED;
    await this.orderRepo.save(order);

    return order;
  }

  async updateOrderStatus(
    orderId: number,
    newStatus: OrderStatus,
    userId: number,
    role: UserRole,
    reason?: string,
    finalLocation?: { lat: number; lng: number },
    mealPreparationTime?: number,
    deliveryTime?: number,
  ): Promise<Order> {
    const order = await this.orderRepo.findOne({
      where: { id: orderId },
      relations: ['owner', 'items', 'deliveryAssignments'],
    });

    if (!order) {
      throw new NotFoundException(`Order with ID ${orderId} not found`);
    }

    this.orderAccessValidator.validateOrderStatusUpdateAccess(
      order,
      newStatus,
      role,
      userId,
    );

    this.orderAccessValidator.validateStatusTransition(order.status, newStatus);

    if (
      newStatus === OrderStatus.CANCELLED ||
      newStatus === OrderStatus.REJECTED
    ) {
      await this.restoreStock(order);
      order.previousStatus = order.status;
      order.cancelledAt = new Date();

      // Handle delivery cancellation logic
      if (newStatus === OrderStatus.CANCELLED) {
        await this.handleDeliveryCancellation(order);
      }
    }

    if (newStatus === OrderStatus.CONFIRMED) {
      if (mealPreparationTime !== undefined) {
        order.mealPreparationTime = mealPreparationTime;
      }
      if (deliveryTime !== undefined) {
        order.deliveryTime = deliveryTime;
      }
      if (order.mealPreparationTime && order.deliveryTime) {
        const totalMinutes = order.mealPreparationTime + order.deliveryTime;
        order.deliveryDeadline = new Date(
          Date.now() + totalMinutes * 60 * 1000,
        );
      }
    }

    order.status = newStatus;

    if (newStatus === OrderStatus.PAID || newStatus === OrderStatus.COMPLETE) {
      const deliveryAssignment = await this.deliveryAssignmentRepo.findOne({
        where: { orderId },
        order: { id: 'DESC' },
      });

      if (deliveryAssignment) {
        if (newStatus === OrderStatus.PAID) {
          deliveryAssignment.paidAt = new Date();
        } else if (newStatus === OrderStatus.COMPLETE) {
          deliveryAssignment.completedAt = new Date();
        }
        await this.deliveryAssignmentRepo.save(deliveryAssignment);
      }
    }

    await this.orderRepo.save(order);

    const documentExists =
      await this.firebaseService.orderDocumentExists(orderId);
    if (documentExists) {
      await this.firebaseService.updateOrderDocument(orderId, newStatus);

      if (
        newStatus === OrderStatus.ASSIGNED ||
        newStatus === OrderStatus.READY_FOR_PICKUP ||
        newStatus === OrderStatus.PICKED_UP ||
        newStatus === OrderStatus.ON_THE_WAY
      ) {
        const deliveryAssignment = await this.deliveryAssignmentRepo.findOne({
          where: { orderId },
          order: { id: 'DESC' },
        });
        if (deliveryAssignment && deliveryAssignment.deliveryId) {
          await this.firebaseService.setDeliveryId(
            orderId,
            deliveryAssignment.deliveryId,
          );
        }
      }
    }

    await this.sendStatusNotifications(order, newStatus);

    if (newStatus === OrderStatus.READY_FOR_PICKUP) {
      try {
        await this.deliveryNotificationService.notifyReadyForOrder(order.id);
      } catch (err) {
        this.logger.error(
          'Failed to trigger delivery notification after READY_FOR_PICKUP',
          err,
        );
      }
    }

    this.logger.log(
      `Order ${orderId} status updated from ${order.status} to ${newStatus} by ${role} ${userId}. Reason: ${reason || 'No reason provided'}`,
    );

    return order;
  }

  public async sendStatusNotifications(
    order: Order,
    newStatus: OrderStatus,
  ): Promise<void> {
    try {
      const deliveryAssignment = await this.deliveryAssignmentRepo.findOne({
        where: {
          orderId: order.id,
          status: In([
            DeliveryStatus.ACCEPTED,
            DeliveryStatus.ASSIGNED,
            DeliveryStatus.PICKED,
            DeliveryStatus.COMPLETED,
          ]),
        },
      });

      // إشعارات العميل (Firebase فقط)
      await this.sendCustomerNotification(order, newStatus);

      // إشعارات Merchant (Firebase فقط)
      await this.sendMerchantNotification(order, newStatus);

      // إشعارات الديلفري (Firebase فقط - SEARCHING فقط)
      if (newStatus === OrderStatus.SEARCHING) {
        // إشعار للديلفري سيتم إرساله من خلال DeliveryNotificationService
        this.logger.log(
          `Order ${order.id} is SEARCHING - delivery notifications will be handled by DeliveryNotificationService`,
        );
      }

      // تحديث حالة Delivery Assignment
      if (deliveryAssignment) {
        switch (newStatus) {
          case OrderStatus.PICKED_UP:
            deliveryAssignment.status = DeliveryStatus.PICKED;
            await this.deliveryAssignmentRepo.save(deliveryAssignment);
            this.logger.log(
              `Updated assignment status to PICKED for order ${order.id}`,
            );
            break;
          case OrderStatus.DELIVERED:
            deliveryAssignment.status = DeliveryStatus.COMPLETED;
            await this.deliveryAssignmentRepo.save(deliveryAssignment);
            this.logger.log(
              `Updated assignment status to COMPLETED for order ${order.id}`,
            );
            break;
          case OrderStatus.CANCELLED:
          case OrderStatus.REJECTED:
            deliveryAssignment.status = DeliveryStatus.EXPIRED;
            await this.deliveryAssignmentRepo.save(deliveryAssignment);
            this.logger.log(
              `Updated assignment status to EXPIRED for order ${order.id} due to ${newStatus}`,
            );
            break;
        }
      }

      this.logger.log(
        `Status notifications sent for order ${order.id} to status ${newStatus}`,
      );
    } catch (error) {
      this.logger.error(`Failed to send status notifications: ${error}`);
    }
  }

  private async sendCustomerNotification(
    order: Order,
    newStatus: OrderStatus,
  ): Promise<void> {
    const notificationData = this.getCustomerNotificationData(order, newStatus);
    if (notificationData) {
      await this.notificationsService.sendToUser(
        order.customerId,
        notificationData.type,
        notificationData.title,
        notificationData.body,
        NotificationChannel.FIREBASE,
        { orderId: String(order.id), status: String(newStatus) },
      );
    }
  }

  private async sendMerchantNotification(
    order: Order,
    newStatus: OrderStatus,
  ): Promise<void> {
    const notificationData = this.getMerchantNotificationData(order, newStatus);
    if (notificationData && order.ownerId) {
      await this.notificationsService.sendToUser(
        order.ownerId,
        notificationData.type,
        notificationData.title,
        notificationData.body,
        NotificationChannel.FIREBASE,
        { orderId: String(order.id), status: String(newStatus) },
      );
    }
  }

  private getCustomerNotificationData(
    order: Order,
    status: OrderStatus,
  ): { type: NotificationType; title: string; body: string } | null {
    const orderId = order.id;

    const notifications: Partial<
      Record<
        OrderStatus,
        { type: NotificationType; title: string; body: string }
      >
    > = {
      [OrderStatus.PENDING]: {
        type: NotificationType.ORDER_CREATED,
        title: 'تم استلام طلبك',
        body: `تم استلام طلبك رقم #${orderId}`,
      },
      [OrderStatus.CONFIRMED]: {
        type: NotificationType.ORDER_CONFIRMED,
        title: 'تم تأكيد الطلب',
        body: `تم تأكيد طلبك رقم #${orderId}`,
      },
      [OrderStatus.SEARCHING]: {
        type: NotificationType.ORDER_SEARCHING,
        title: 'البحث عن سائق',
        body: `جاري البحث عن سائق لطلبك #${orderId}`,
      },
      [OrderStatus.ASSIGNED]: {
        type: NotificationType.ORDER_ASSIGNED,
        title: 'تم تعيين سائق',
        body: `تم تعيين سائق لطلبك رقم #${orderId}`,
      },
      [OrderStatus.READY_FOR_PICKUP]: {
        type: NotificationType.ORDER_READY,
        title: 'الطلب جاهز',
        body: `طلبك رقم #${orderId} جاهز للاستلام`,
      },
      [OrderStatus.PICKED_UP]: {
        type: NotificationType.ORDER_PICKED_UP,
        title: 'تم استلام الطلب',
        body: `تم استلام طلبك رقم #${orderId} من المطعم`,
      },
      [OrderStatus.ON_THE_WAY]: {
        type: NotificationType.ORDER_ON_THE_WAY,
        title: 'في الطريق',
        body: `طلبك رقم #${orderId} في الطريق إليك`,
      },
      [OrderStatus.DELIVERED]: {
        type: NotificationType.ORDER_DELIVERED,
        title: 'تم التوصيل',
        body: `تم توصيل طلبك رقم #${orderId} بنجاح 🎉`,
      },
      [OrderStatus.CANCELLED]: {
        type: NotificationType.ORDER_CANCELLED,
        title: 'تم الإلغاء',
        body: `تم إلغاء طلبك رقم #${orderId}`,
      },
      [OrderStatus.REJECTED]: {
        type: NotificationType.ORDER_CANCELLED,
        title: 'تم الرفض',
        body: `تم رفض طلبك رقم #${orderId}`,
      },
    };

    return notifications[status] || null;
  }

  private getMerchantNotificationData(
    order: Order,
    status: OrderStatus,
  ): { type: NotificationType; title: string; body: string } | null {
    const orderId = order.id;

    const notifications: Partial<
      Record<
        OrderStatus,
        { type: NotificationType; title: string; body: string }
      >
    > = {
      [OrderStatus.PENDING]: {
        type: NotificationType.ORDER_CREATED,
        title: 'طلب جديد',
        body: `لديك طلب جديد رقم #${orderId}`,
      },
      [OrderStatus.ASSIGNED]: {
        type: NotificationType.ORDER_ASSIGNED,
        title: 'تم تعيين سائق',
        body: `تم تعيين سائق لطلب رقم #${orderId}`,
      },
      [OrderStatus.PICKED_UP]: {
        type: NotificationType.ORDER_PICKED_UP,
        title: 'تم الاستلام',
        body: `تم استلام طلب رقم #${orderId} من مطعمك`,
      },
      [OrderStatus.ON_THE_WAY]: {
        type: NotificationType.ORDER_ON_THE_WAY,
        title: 'في الطريق',
        body: `طلب رقم #${orderId} في الطريق للعميل`,
      },
      [OrderStatus.DELIVERED]: {
        type: NotificationType.ORDER_DELIVERED,
        title: 'تم التوصيل',
        body: `تم توصيل طلب رقم #${orderId} بنجاح`,
      },
    };

    return notifications[status] || null;
  }

  async cancelOrder(
    orderId: number,
    userId: number,
    role: UserRole,
    reason?: string,
  ): Promise<Order> {
    return this.updateOrderStatus(
      orderId,
      OrderStatus.CANCELLED,
      userId,
      role,
      reason,
    );
  }

  private async restoreStock(order: Order): Promise<void> {
    const items = await this.orderItemRepo.find({
      where: { orderId: order.id },
    });

    const productIds = items
      .map((item) => item.productId)
      .filter((id): id is number => id !== null && id !== undefined);

    if (productIds.length === 0) {
      return;
    }

    const products = await this.productRepo.find({
      where: { id: In(productIds) },
    });
    const productMap = new Map(products.map((p) => [p.id, p]));

    let restoredCount = 0;
    let skippedCount = 0;

    for (const item of items) {
      if (!item.productId) {
        skippedCount++;
        continue;
      }

      const product = productMap.get(item.productId);

      if (product && product.hasStock) {
        await this.productRepo.increment(
          { id: item.productId },
          'stockQuantity',
          item.quantity,
        );
        restoredCount++;
      } else if (product && !product.hasStock) {
        skippedCount++;
      }
    }

    this.logger.log(
      `Stock restoration complete: ${restoredCount} items restored, ${skippedCount} skipped`,
    );
  }

  private async handleDeliveryCancellation(order: Order): Promise<void> {
    try {
      this.logger.log(
        `🗑️ [CANCEL] Handling delivery cancellation for order ${order.id}`,
      );

      // 1. Cancel any pending driver search jobs/notifications
      await this.deliveryAssignmentService.cancelPendingDeliveryNotifications(
        order.id,
      );

      // 2. If it was ASSIGNED/READY/PREPARING, notify the assigned driver
      const assignedAssignment = await this.deliveryAssignmentRepo.findOne({
        where: {
          orderId: order.id,
          status: In([DeliveryStatus.ACCEPTED, DeliveryStatus.NOTIFIED]),
        },
        relations: ['delivery'],
      });

      if (assignedAssignment && assignedAssignment.deliveryId) {
        this.logger.log(
          `🔔 [CANCEL] Notifying driver ${assignedAssignment.deliveryId} about cancellation`,
        );

        await this.notificationsService.sendToUser(
          assignedAssignment.deliveryId,
          NotificationType.ORDER_CANCELLED,
          'طلب ملغي',
          `تم إلغاء الطلب رقم #${order.id} من قبل العميل.`,
          NotificationChannel.FIREBASE,
          { orderId: order.id },
        );

        // Update assignment status to REJECTED or a specific CANCELLED state if exists
        // Since we don't have a CANCELLED status in DeliveryStatus (only ACCEPTED, PICKED, COMPLETED, NOTIFIED, REJECTED, FAILED)
        // we'll mark it as REJECTED for now or just log it.
        // Based on current logic, just revoking or canceling is enough.
      }
    } catch (err) {
      this.logger.error(
        `Failed to handle delivery cancellation for order ${order.id}`,
        err,
      );
    }
  }
}

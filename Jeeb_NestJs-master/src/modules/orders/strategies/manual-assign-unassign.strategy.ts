import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, EntityManager } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { User } from '../../../database/entities/user.entity';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { UserRole } from '../../../common/enums/user-role.enum';
import { ErrorCodes } from '../../../common/constants/error-codes';
import { UnassignAction, UnassignDriverDto } from '../dto/unassign-driver.dto';
import { IUnassignStrategy, UnassignResult } from './unassign-strategy.interface';
import { FirebaseService } from '../../firebase/firebase.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { NotificationType } from '../../../common/enums/notification-type.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';

@Injectable()
export class ManualAssignUnassignStrategy implements IUnassignStrategy {
  readonly action = UnassignAction.MANUAL_ASSIGN;
  private readonly logger = new Logger(ManualAssignUnassignStrategy.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(DeliveryAssignment)
    private readonly assignmentRepo: Repository<DeliveryAssignment>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly firebaseService: FirebaseService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async execute(order: Order, dto: UnassignDriverDto, manager?: EntityManager): Promise<UnassignResult> {
    const newDeliveryId = dto.newDeliveryId!;

    const driver = await this.userRepo.findOne({ where: { id: newDeliveryId } });
    if (!driver) {
      throw new BadRequestException(
        `${ErrorCodes.DELIVERY_DRIVER_NOT_FOUND.message} (ID: ${newDeliveryId})`,
      );
    }
    if (driver.role !== UserRole.DELIVERY) {
      throw new BadRequestException(ErrorCodes.USER_INVALID_ROLE.message);
    }
    if (!driver.isActive) {
      throw new BadRequestException(ErrorCodes.DELIVERY_DRIVER_NOT_AVAILABLE.message);
    }

    const currentDA = order.deliveryAssignments?.find(
      (da) => da.status === DeliveryStatus.ACCEPTED,
    );
    if (currentDA && currentDA.deliveryId === newDeliveryId) {
      throw new BadRequestException(ErrorCodes.DELIVERY_ALREADY_ASSIGNED.message);
    }

    const activeOrders = await this.assignmentRepo
      .createQueryBuilder('da')
      .leftJoin('da.order', 'o')
      .where('da.deliveryId = :deliveryId', { deliveryId: newDeliveryId })
      .andWhere('da.status = :status', { status: DeliveryStatus.ACCEPTED })
      .andWhere('o.status IN (:...statuses)', {
        statuses: [
          OrderStatus.ASSIGNED,
          OrderStatus.READY_FOR_PICKUP,
          OrderStatus.PICKED_UP,
          OrderStatus.ON_THE_WAY,
          OrderStatus.PREPARING,
        ],
      })
      .getCount();

    if (activeOrders >= 1) {
      throw new BadRequestException(ErrorCodes.DELIVERY_DRIVER_BUSY.message);
    }

    const repo = manager ? manager.getRepository(DeliveryAssignment) : this.assignmentRepo;
    const newAssignment = repo.create({
      orderId: order.id,
      deliveryId: newDeliveryId,
      status: DeliveryStatus.ASSIGNED,
      assignedAt: new Date(),
    });
    await repo.save(newAssignment);

    order.status = OrderStatus.ASSIGNED;
    if (manager) {
      await manager.update(Order, order.id, { status: OrderStatus.ASSIGNED });
    } else {
      await this.orderRepo.update(order.id, { status: OrderStatus.ASSIGNED });
    }

    try {
      await this.firebaseService.updateOrderDocument(order.id, OrderStatus.ASSIGNED);
      await this.firebaseService.setDeliveryId(order.id, newDeliveryId);
      await this.firebaseService.createDriverDocument({
        id: driver.id,
        currentLat: driver.currentLat,
        currentLng: driver.currentLng,
        isOnline: driver.isOnline,
      });
    } catch (err) {
      this.logger.warn(`Firebase update failed for order ${order.id}: ${err}`);
    }

    try {
      await this.notificationsService.sendToUser(
        newDeliveryId,
        NotificationType.ORDER_ASSIGNED,
        'تم تعيينك للطلب',
        `تم تعيينك لتوصيل الطلب رقم #${order.id} من قبل الإدارة.`,
        NotificationChannel.FIREBASE,
        { orderId: String(order.id) },
      );
    } catch (err) {
      this.logger.warn(`Failed to notify driver ${newDeliveryId}: ${err}`);
    }

    this.logger.log(
      `Order ${order.id} manually assigned to driver ${newDeliveryId} after unassign`,
    );
    return { newDriverId: newDeliveryId, newStatus: OrderStatus.ASSIGNED };
  }
}

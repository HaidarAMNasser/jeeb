import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { ErrorCodes } from '../../../common/constants/error-codes';
import { AuditAction } from '../../../common/enums/audit-action.enum';
import { AuditService } from '../../audit/audit.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { NotificationType } from '../../../common/enums/notification-type.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { UnassignDriverDto } from '../dto/unassign-driver.dto';
import { UnassignStrategyFactory } from '../strategies/unassign-strategy.factory';
import type { UserPayload } from '../../../common/interfaces/user-payload.interface';

export interface UnassignResponse {
  orderId: number;
  previousDriverId: number;
  newDriverId: number | null;
  newStatus: string;
}

@Injectable()
export class UnassignDriverService {
  private readonly logger = new Logger(UnassignDriverService.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(DeliveryAssignment)
    private readonly assignmentRepo: Repository<DeliveryAssignment>,
    private readonly dataSource: DataSource,
    private readonly unassignStrategyFactory: UnassignStrategyFactory,
    private readonly auditService: AuditService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async execute(id: number, dto: UnassignDriverDto, user: UserPayload): Promise<UnassignResponse> {
    const order = await this.orderRepo.findOne({
      where: { id },
      relations: ['deliveryAssignments'],
    });
    if (!order) {
      throw new NotFoundException(
        `${ErrorCodes.ORDER_NOT_FOUND.message} (ID: ${id})`,
      );
    }

    const currentDA = order.deliveryAssignments?.find(
      (da) => da.status === DeliveryStatus.ACCEPTED,
    );
    if (!currentDA) {
      throw new BadRequestException(ErrorCodes.DELIVERY_INVALID_STATUS.message);
    }

    const oldDeliveryId = currentDA.deliveryId;

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    let result: import('../strategies/unassign-strategy.interface').UnassignResult;

    try {
      currentDA.status = DeliveryStatus.EXPIRED;
      currentDA.unassignedAt = new Date();
      await queryRunner.manager.save(currentDA);

      const strategy = this.unassignStrategyFactory.getStrategy(dto.action);
      result = await strategy.execute(order, dto, queryRunner.manager);

      await queryRunner.commitTransaction();
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }

    try {
      await this.notificationsService.sendToUser(
        oldDeliveryId,
        NotificationType.ORDER_CANCELLED,
        'تم إزالتك من الطلب',
        `تم إزالتك من الطلب رقم #${order.id} من قبل الإدارة.`,
        NotificationChannel.FIREBASE,
        { orderId: String(order.id) },
      );
    } catch (err) {
      this.logger.warn(`Failed to notify removed driver ${oldDeliveryId}: ${err}`);
    }

    try {
      await this.auditService.logAction(
        user.id,
        AuditAction.UNASSIGN_DRIVER,
        'Order',
        id,
        { deliveryId: oldDeliveryId, status: 'ASSIGNED' },
        {
          action: dto.action,
          newDeliveryId: dto.newDeliveryId ?? null,
          newStatus: result!.newStatus,
        },
      );
    } catch (err) {
      this.logger.warn(`Audit log failed for unassign on order ${id}: ${err}`);
    }

    this.logger.log(
      `Order ${id}: Driver ${oldDeliveryId} removed, action=${dto.action}, newDriverId=${dto.newDeliveryId ?? 'none'}`,
    );

    return {
      orderId: id,
      previousDriverId: oldDeliveryId,
      newDriverId: result!.newDriverId ?? null,
      newStatus: result!.newStatus,
    };
  }
}

import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { DELIVERY_RESTRICTIONS } from '../../../common/constants/upload.constants';

@Injectable()
export class DeliveryRestrictionService {
  private readonly logger = new Logger(DeliveryRestrictionService.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(DeliveryAssignment)
    private readonly assignmentRepo: Repository<DeliveryAssignment>,
  ) {}

  async checkIncompleteOrders(deliveryId: number): Promise<{
    hasIncompleteOrders: boolean;
    incompleteCount: number;
  }> {
    const incompleteStatuses = DELIVERY_RESTRICTIONS.INCOMPLETE_STATUSES;

    const assignments = await this.assignmentRepo.find({
      where: { deliveryId, status: DeliveryStatus.ACCEPTED },
      relations: ['order'],
    });

    const incompleteOrders = assignments.filter(
      (assignment) =>
        assignment.order &&
        incompleteStatuses.includes(assignment.order.status),
    );

    return {
      hasIncompleteOrders:
        incompleteOrders.length > DELIVERY_RESTRICTIONS.MAX_INCOMPLETE_ORDERS,
      incompleteCount: incompleteOrders.length,
    };
  }

  async validateDeliveryRestrictions(
    deliveryId: number,
    action: string,
  ): Promise<void> {
    const { hasIncompleteOrders, incompleteCount } =
      await this.checkIncompleteOrders(deliveryId);

    if (hasIncompleteOrders) {
      throw new BadRequestException(
        `Cannot ${action}. You have ${incompleteCount} incomplete order(s). Please complete all orders before ${action}.`,
      );
    }
  }

  async getIncompleteOrdersForDelivery(deliveryId: number): Promise<Order[]> {
    const incompleteStatuses = DELIVERY_RESTRICTIONS.INCOMPLETE_STATUSES;

    const assignments = await this.assignmentRepo.find({
      where: { deliveryId, status: DeliveryStatus.ACCEPTED },
      relations: ['order'],
    });

    return assignments
      .filter(
        (assignment) =>
          assignment.order &&
          incompleteStatuses.includes(assignment.order.status),
      )
      .map((assignment) => assignment.order);
  }
}

import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, EntityManager } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { UnassignAction, UnassignDriverDto } from '../dto/unassign-driver.dto';
import { IUnassignStrategy, UnassignResult } from './unassign-strategy.interface';
import { DeliveryAssignmentService } from '../services/delivery-assignment.service';

@Injectable()
export class AutoSearchUnassignStrategy implements IUnassignStrategy {
  readonly action = UnassignAction.AUTO_SEARCH;
  private readonly logger = new Logger(AutoSearchUnassignStrategy.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    private readonly deliveryAssignmentService: DeliveryAssignmentService,
  ) {}

  async execute(order: Order, _dto: UnassignDriverDto, manager?: EntityManager): Promise<UnassignResult> {
    order.status = OrderStatus.SEARCHING;

    if (manager) {
      await manager.update(Order, order.id, { status: OrderStatus.SEARCHING });
    } else {
      await this.orderRepo.update(order.id, { status: OrderStatus.SEARCHING });
    }

    await this.deliveryAssignmentService.startSearchingForDriver(order.id);

    this.logger.log(`Order ${order.id} returned to SEARCHING after driver unassign`);
    return { newStatus: OrderStatus.SEARCHING };
  }
}

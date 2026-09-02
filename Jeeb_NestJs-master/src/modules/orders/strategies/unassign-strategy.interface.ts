import { Order } from '../../../database/entities/order.entity';
import { EntityManager } from 'typeorm';
import { UnassignAction, UnassignDriverDto } from '../dto/unassign-driver.dto';

export interface UnassignResult {
  newDriverId?: number;
  newStatus: string;
}

export interface IUnassignStrategy {
  readonly action: UnassignAction;
  execute(order: Order, dto: UnassignDriverDto, manager?: EntityManager): Promise<UnassignResult>;
}

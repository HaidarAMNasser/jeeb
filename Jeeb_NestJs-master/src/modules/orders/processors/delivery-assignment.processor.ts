import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { OrdersService } from '../services/orders.service';
import {
  DeliveryTimeoutJobData,
  DeliveryRetryJobData,
  DeliveryJobType,
} from '../interfaces/delivery-processor.interfaces';

@Processor('orders')
export class DeliveryAssignmentProcessor extends WorkerHost {
  private readonly logger = new Logger(DeliveryAssignmentProcessor.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    private readonly ordersService: OrdersService,
  ) {
    super();
  }

  async process(
    job: Job<DeliveryTimeoutJobData | DeliveryRetryJobData>,
  ): Promise<void> {
    const { name, data } = job;

    try {
      switch (name as DeliveryJobType) {
        case 'delivery-timeout':
          await this.handleDeliveryTimeout(data as DeliveryTimeoutJobData);
          break;
        case 'delivery-retry':
          await this.handleDeliveryRetry(data as DeliveryRetryJobData);
          break;
        default:
          this.logger.warn(`Unknown job type: ${name}`);
      }
    } catch (error) {
      this.logger.error(`Failed to process job ${name}`, error);
      throw error;
    }
  }

  /**
   * Handle delivery timeout — if no driver accepted within timeout period.
   * Schedules a retry with expanded search radius.
   */
  private async handleDeliveryTimeout(
    data: DeliveryTimeoutJobData,
  ): Promise<void> {
    const { orderId, attempt, currentRadius } = data;

    try {
      const order = await this.orderRepo.findOne({
        where: { id: orderId },
      });

      if (!order) {
        return;
      }

      // If order is already assigned, no action needed
      if (order.status === OrderStatus.ASSIGNED) {
        return;
      }

      // If order is still SEARCHING or READY_FOR_PICKUP after timeout, try next batch with expanded radius
      if (
        order.status === OrderStatus.SEARCHING ||
        order.status === OrderStatus.READY_FOR_PICKUP
      ) {
        // Schedule retry — radius will be expanded automatically by the service
        await this.ordersService.scheduleDeliveryRetry(
          orderId,
          attempt + 1,
          currentRadius,
        );
      }
    } catch (error) {
      this.logger.error(
        `Failed to process delivery timeout for order ${orderId}`,
        error,
      );
      throw error;
    }
  }

  /**
   * Handle delivery retry — find next batch of drivers with expanded radius.
   */
  private async handleDeliveryRetry(data: DeliveryRetryJobData): Promise<void> {
    const { orderId, attempt, currentRadius } = data;
    const MAX_RETRY_ATTEMPTS = 10;

    if (attempt > MAX_RETRY_ATTEMPTS) {
      return;
    }

    try {
      const order = await this.orderRepo.findOne({
        where: { id: orderId },
      });

      if (!order) {
        return;
      }

      // If order is already assigned, no action needed
      if (order.status === OrderStatus.ASSIGNED) {
        return;
      }

      // If order is in SEARCHING or READY_FOR_PICKUP, send notifications to next batch
      if (
        order.status === OrderStatus.SEARCHING ||
        order.status === OrderStatus.READY_FOR_PICKUP
      ) {
        // Send notifications with expanded radius
        await this.ordersService.sendDeliveryNotifications(
          orderId,
          currentRadius,
        );
      }
    } catch (error) {
      this.logger.error(
        `Failed to process delivery retry for order ${orderId}`,
        error,
      );
      throw error;
    }
  }
}

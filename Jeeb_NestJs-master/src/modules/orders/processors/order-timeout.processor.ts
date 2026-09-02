import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { UserRole } from '../../../common/enums/user-role.enum';
import { UpdateOrderPipeline } from '../pipeline/update-order-pipeline';

@Processor('orders')
export class OrderTimeoutProcessor extends WorkerHost {
  private readonly logger = new Logger(OrderTimeoutProcessor.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    private readonly updateOrderPipeline: UpdateOrderPipeline,
  ) {
    super();
  }

  async process(job: Job<{ orderId: number }>): Promise<void> {
    const { orderId } = job.data;
    this.logger.debug(`Processing timeout check for order ${orderId}...`);

    try {
      const order = await this.orderRepo.findOne({ where: { id: orderId } });

      if (!order) {
        this.logger.warn(`Order ${orderId} not found during timeout check`);
        return;
      }

      if (order.status === OrderStatus.PENDING) {
        this.logger.log(
          `Order ${orderId} timed out (still PENDING). Cancelling...`,
        );

        const result = await this.updateOrderPipeline.execute(
          orderId,
          OrderStatus.CANCELLED,
          0,
          UserRole.ADMIN,
          'Order timed out',
        );

        if (result.success) {
          this.logger.log(
            `Order ${orderId} has been cancelled automatically via pipeline.`,
          );
        } else {
          this.logger.error(
            `Failed to cancel order ${orderId} via pipeline: ${result.error}`,
          );
        }
      } else {
        this.logger.debug(
          `Order ${orderId} status is ${order.status}. No action needed.`,
        );
      }
    } catch (error) {
      this.logger.error(
        `Failed to process timeout for order ${orderId}`,
        error,
      );
      throw error;
    }
  }
}

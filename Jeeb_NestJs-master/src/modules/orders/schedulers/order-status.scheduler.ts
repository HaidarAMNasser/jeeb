import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { Cron } from '@nestjs/schedule';
import { Order } from '../../../database/entities/order.entity';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { UserRole } from '../../../common/enums/user-role.enum';
import { UpdateOrderPipeline } from '../pipeline/update-order-pipeline';

const ORDER_STATUS_TIMEOUT_MINUTES = 120;

@Injectable()
export class OrderStatusScheduler {
  private readonly logger = new Logger(OrderStatusScheduler.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    private readonly updateOrderPipeline: UpdateOrderPipeline,
  ) {}

  @Cron('*/5 * * * *')
  async handleConfirmedOrdersTimeout() {
    const timeoutDate = new Date(
      Date.now() - ORDER_STATUS_TIMEOUT_MINUTES * 60 * 1000,
    );

    try {
      const expiredOrders = await this.orderRepo.find({
        where: {
          status: OrderStatus.CONFIRMED,
          createdAt: LessThan(timeoutDate),
        },
      });

      if (expiredOrders.length === 0) {
        return;
      }

      this.logger.log(
        `Found ${expiredOrders.length} CONFIRMED orders older than ${ORDER_STATUS_TIMEOUT_MINUTES} minutes`,
      );

      for (const order of expiredOrders) {
        try {
          const result = await this.updateOrderPipeline.execute(
            order.id,
            OrderStatus.CANCELLED,
            0,
            UserRole.ADMIN,
            'Order timed out after confirmation',
          );

          if (result.success) {
            this.logger.log(
              `Order ${order.id} cancelled due to confirmation timeout`,
            );
          } else {
            this.logger.error(
              `Failed to cancel order ${order.id}: ${result.error}`,
            );
          }
        } catch (error) {
          this.logger.error(
            `Error cancelling order ${order.id}:`,
            error instanceof Error ? error.message : error,
          );
        }
      }
    } catch (error) {
      this.logger.error(
        'Error in handleConfirmedOrdersTimeout:',
        error instanceof Error ? error.message : error,
      );
    }
  }

  @Cron('*/5 * * * *')
  async handleSearchingOrdersTimeout() {
    const timeoutDate = new Date(
      Date.now() - ORDER_STATUS_TIMEOUT_MINUTES * 60 * 1000,
    );

    try {
      const expiredOrders = await this.orderRepo.find({
        where: {
          status: OrderStatus.SEARCHING,
          createdAt: LessThan(timeoutDate),
        },
      });

      if (expiredOrders.length === 0) {
        return;
      }

      this.logger.log(
        `Found ${expiredOrders.length} SEARCHING orders older than ${ORDER_STATUS_TIMEOUT_MINUTES} minutes without driver assignment`,
      );

      for (const order of expiredOrders) {
        try {
          const result = await this.updateOrderPipeline.execute(
            order.id,
            OrderStatus.CANCELLED,
            0,
            UserRole.ADMIN,
            'No delivery driver accepted within timeout',
          );

          if (result.success) {
            this.logger.log(
              `Order ${order.id} cancelled due to no driver acceptance`,
            );
          } else {
            this.logger.error(
              `Failed to cancel order ${order.id}: ${result.error}`,
            );
          }
        } catch (error) {
          this.logger.error(
            `Error cancelling order ${order.id}:`,
            error instanceof Error ? error.message : error,
          );
        }
      }
    } catch (error) {
      this.logger.error(
        'Error in handleSearchingOrdersTimeout:',
        error instanceof Error ? error.message : error,
      );
    }
  }
}

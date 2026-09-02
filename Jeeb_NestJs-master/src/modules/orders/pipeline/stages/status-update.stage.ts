import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../../../../database/entities/order.entity';
import { OrderStatus } from '../../../../common/enums/order-status.enum';
import { UserRole } from '../../../../common/enums/user-role.enum';
import {
  UpdateOrderContext,
  UpdateOrderResult,
  UpdateOrderStage,
} from '../update-order-pipeline.interfaces';
import { BaseStage } from './base-stage';
import { DeliveryAssignmentService } from '../../services/delivery-assignment.service';
import { FirebaseService } from '../../../firebase/firebase.service';
import { LoyaltyService } from '../../../loyalty/loyalty.service';

@Injectable()
export class StatusUpdateStage extends BaseStage {
  constructor(
    private readonly deliveryAssignmentService: DeliveryAssignmentService,
    private readonly firebaseService: FirebaseService,
    private readonly loyaltyService: LoyaltyService,
  ) {
    super(UpdateOrderStage.STATUS_UPDATE);
  }

  async execute(context: UpdateOrderContext) {
    try {
      const { order, newStatus, userId, role, reason, customerName, phone } =
        context;

      if (!order) {
        return this.createErrorResult('Order not found', this.stageName);
      }

      const currentStatus = order.status;

      order.status = newStatus;

      if (customerName !== undefined) {
        order.customerName = customerName || null;
      }
      if (phone !== undefined) {
        order.phone = phone || null;
      }

      if (currentStatus === OrderStatus.CANCELLED) {
        order.previousStatus = null;
        order.cancelledAt = null;
      }

      if (newStatus === OrderStatus.CONFIRMED) {
        if (context.mealPreparationTime !== undefined) {
          order.mealPreparationTime = context.mealPreparationTime;
        }
        if (context.deliveryTime !== undefined) {
          order.deliveryTime = context.deliveryTime;
        }

        if (order.mealPreparationTime && order.deliveryTime) {
          const totalMinutes = order.mealPreparationTime + order.deliveryTime;
          order.deliveryDeadline = new Date(
            Date.now() + totalMinutes * 60 * 1000,
          );
        }
      }

      if (newStatus === OrderStatus.DELIVERED) {
        if (context.finalLocation) {
          order.finalLocation = context.finalLocation;
        } else if (order.deliveryCoordinates) {
          order.finalLocation = {
            lat: order.deliveryCoordinates.latitude,
            lng: order.deliveryCoordinates.longitude,
          };
        }

        await this.loyaltyService.processOrderDelivery(
          order.customerId,
          order.id,
        );
      }

      await this.orderRepo.save(order);

      // Firebase RTDB: Create or update order document
      // Document should exist from PENDING, but ensure it exists for any status transition
      const documentExists = await this.firebaseService.orderDocumentExists(
        order.id,
      );

      if (!documentExists) {
        // Document doesn't exist - create it with full data
        await this.firebaseService.createOrderDocument(order);
      } else {
        // Document exists - just update status
        await this.firebaseService.updateOrderDocument(order.id, newStatus);
      }

      // Firebase RTDB: Delete order document when order is completed/cancelled/rejected
      // Note: Driver document is NOT deleted - it remains for tracking/history
      if (newStatus === OrderStatus.DELIVERED) {
        setTimeout(async () => {
          await this.firebaseService.deleteOrderDocument(order.id);
        }, 5000);
      } else if (
        newStatus === OrderStatus.CANCELLED ||
        newStatus === OrderStatus.REJECTED
      ) {
        await this.firebaseService.deleteOrderDocument(order.id);
      }

      if (newStatus === OrderStatus.CONFIRMED) {
        order.status = OrderStatus.SEARCHING;
        await this.orderRepo.save(order);

        try {
          await this.deliveryAssignmentService.startSearchingForDriver(
            context.orderId,
          );
        } catch (deliveryError) {}
      }

      return this.createSuccessResult(context);
    } catch (error) {
      return this.handleError(error, this.stageName);
    }
  }
}

import { Injectable, Logger } from '@nestjs/common';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { ErrorCodes } from '../../../common/constants/error-codes';

@Injectable()
export class DeliveryNotificationService {
  private readonly logger = new Logger(DeliveryNotificationService.name);

  constructor(
    @InjectRepository(DeliveryAssignment)
    private readonly deliveryAssignmentRepo: Repository<DeliveryAssignment>,
  ) {}

  /**
   * Send notifications to drivers when order is ready for pickup
   * This is an MVP stub - full implementation would use Firebase
   */
  async notifyReadyForOrder(orderId: number): Promise<void> {
    this.logger.log(
      `${ErrorCodes.DRIVER_LOCATOR_MOCK_MODE.message} - notifyReadyForOrder called for order ${orderId}`,
    );

    // Full implementation would:
    // 1. Read order location
    // 2. Fetch 3 nearest drivers from Firebase
    // 3. Create DeliveryAssignment entries with groupIndex = 0
    // 4. Set status to NOTIFIED
    // 5. Schedule TTL (2 minutes) via BullMQ

    this.logger.debug(
      `Order ${orderId} ready for pickup - drivers would be notified in production`,
    );
  }

  /**
   * Handle notification delivery result
   */
  async handleNotificationResult(
    assignmentId: number,
    success: boolean,
    error?: string,
  ): Promise<void> {
    if (!success) {
      this.logger.error(
        `${ErrorCodes.NOTIFICATION_FAILED.message} for assignment ${assignmentId}: ${error || 'Unknown error'}`,
      );
      return;
    }

    this.logger.log(
      `Notification sent successfully for assignment ${assignmentId}`,
    );
  }
}

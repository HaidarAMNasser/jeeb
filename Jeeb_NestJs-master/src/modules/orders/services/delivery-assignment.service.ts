import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../../../database/entities/order.entity';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { User } from '../../../database/entities/user.entity';
import {
  NotificationLog,
  NotificationStatus,
} from '../../../database/entities/notification-log.entity';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import {
  DELIVERY_RESTRICTIONS,
  DRIVER_SEARCH_CONFIG,
} from '../../../common/constants/upload.constants';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { NotificationType } from '../../../common/enums/notification-type.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { UserRole } from '../../../common/enums/user-role.enum';
import { NotificationsService } from '../../notifications/notifications.service';
import { DistanceService } from '../../distance/distance.service';
import { FirebaseService } from '../../firebase/firebase.service';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import {
  DriverLocation,
  DriverDistance,
  QueueJobData,
  SmartSearchConfig,
  DriverScoreResult,
} from '../interfaces/delivery-assignment.interfaces';
import { ErrorCodes } from '../../../common/constants/error-codes';
import { SettingsService } from '../../settings/settings.service';
import { DriverScoringService } from './driver-scoring.service';

@Injectable()
export class DeliveryAssignmentService {
  private readonly logger = new Logger(DeliveryAssignmentService.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(DeliveryAssignment)
    private readonly assignmentRepo: Repository<DeliveryAssignment>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(NotificationLog)
    private readonly notificationLogRepo: Repository<NotificationLog>,
    private readonly notificationsService: NotificationsService,
    private readonly distanceService: DistanceService,
    private readonly firebaseService: FirebaseService,
    private readonly settingsService: SettingsService,
    private readonly driverScoringService: DriverScoringService,
    @InjectQueue('orders') private readonly ordersQueue: Queue,
  ) {}

  // ─────────────────────────────────────────────────────────
  //  Load Smart Search Configuration from Settings
  // ─────────────────────────────────────────────────────────

  private async getMaxIncompleteOrdersForSearch(): Promise<number> {
    try {
      const setting = await this.settingsService.getSettingByKey(
        'maxIncompleteOrdersForDriverSearch',
      );
      return (
        Number(setting?.value) ||
        DRIVER_SEARCH_CONFIG.MAX_INCOMPLETE_ORDERS_FOR_SEARCH
      );
    } catch {
      return DRIVER_SEARCH_CONFIG.MAX_INCOMPLETE_ORDERS_FOR_SEARCH;
    }
  }

  private async loadSearchConfig(): Promise<SmartSearchConfig> {
    const getNum = async (key: string, fallback: number): Promise<number> => {
      try {
        const s = await this.settingsService.getSettingByKey(key);
        return Number(s?.value) || fallback;
      } catch {
        return fallback;
      }
    };

    return {
      initialSearchRadius: await getNum('initialSearchRadius', 5.0),
      searchRadiusIncrement: await getNum('searchRadiusIncrement', 2.0),
      maxSearchRadius: await getNum('maxSearchRadius', 20.0),
      batchSize: await getNum('driverRequestBatchSize', 3),
      timeoutSeconds: await getNum('driverRequestTimeoutSeconds', 180),
    };
  }

  /**
   * Calculate the current search radius based on attempt number.
   */
  private calculateCurrentRadius(
    config: SmartSearchConfig,
    attempt: number,
  ): number {
    const radius =
      config.initialSearchRadius + (attempt - 1) * config.searchRadiusIncrement;
    return Math.min(radius, config.maxSearchRadius);
  }

  // ─────────────────────────────────────────────────────────
  //  Start Searching For Driver (Entry Point)
  // ─────────────────────────────────────────────────────────

  /**
   * Start searching for delivery drivers — called when order enters SEARCHING.
   */
  async startSearchingForDriver(
    orderId: number,
    attempt: number = 1,
  ): Promise<void> {
    const order = await this.orderRepo.findOne({
      where: { id: orderId },
      relations: ['owner', 'deliveryAssignments'],
    });

    if (!order || !order.deliveryCoordinates) {
      throw new NotFoundException(ErrorCodes.DELIVERY_ORDER_NOT_FOUND.message);
    }

    if (order.status !== OrderStatus.SEARCHING) {
      return;
    }

    if (!order.owner?.location?.lat || !order.owner?.location?.lng) {
      throw new BadRequestException('Merchant location is not available');
    }

    const merchantCoordinates = {
      latitude: order.owner.location.lat,
      longitude: order.owner.location.lng,
    };

    const config = await this.loadSearchConfig();
    const currentRadius = this.calculateCurrentRadius(config, attempt);

    this.logger.log(
      `🔍 [DELIVERY] Attempt #${attempt} - Search radius: ${currentRadius}km for order ${orderId}`,
    );
    this.logger.log(
      `📍 Merchant: lat=${merchantCoordinates.latitude}, lng=${merchantCoordinates.longitude}`,
    );

    const scoredDrivers = await this.findNearestDriversSmart(
      orderId,
      merchantCoordinates,
      currentRadius,
      config.batchSize,
    );

    if (scoredDrivers.length === 0) {
      this.logger.log(
        `⚠️ [DELIVERY] No drivers found in attempt #${attempt}. Scheduling retry...`,
      );
      await this.scheduleDeliveryRetry(orderId, attempt, currentRadius);
      return;
    }

    const nearestDrivers = scoredDrivers.map((r) => r.driver);

    for (const driver of nearestDrivers) {
      await this.sendDeliveryNotificationToDriver(order, driver);
      this.logger.log(
        `📢 [DELIVERY] Notified driver: ${driver.firstName} ${driver.lastName} (ID: ${driver.id})`,
      );
    }

    await this.scheduleDeliveryTimeout(
      orderId,
      nearestDrivers.map((d) => d.id),
      currentRadius,
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Smart Search: Find Nearest Drivers with Scoring
  // ─────────────────────────────────────────────────────────

  /**
   * Find nearest drivers using smart scoring algorithm:
   * 1. Haversine pre-filter within radius
   * 2. Exclude notified + blocked drivers
   * 3. Google Directions API for top candidates
   * 4. Multi-criteria scoring (distance + ETA + acceptance rate)
   */
  private async findNearestDriversSmart(
    orderId: number,
    merchantCoordinates: { latitude: number; longitude: number },
    searchRadiusKm: number,
    batchSize: number,
  ): Promise<DriverScoreResult[]> {
    const merchantCoord = {
      lat: merchantCoordinates.latitude,
      lng: merchantCoordinates.longitude,
    };

    const blockedDriverIds = await this.getBlockedDriverIds(orderId);
    if (blockedDriverIds.length > 0) {
      this.logger.log(
        `🚫 [DELIVERY] Blocked drivers: [${blockedDriverIds.join(', ')}]`,
      );
    }

    // ── Step 2: Get active drivers from PostgreSQL ──
    const activeDrivers = await this.userRepo
      .createQueryBuilder('user')
      .where('user.role = :role', { role: UserRole.DELIVERY })
      .andWhere('user.isActive = :isActive', { isActive: true })
      .getMany();

    this.logger.log(
      `📊 [DELIVERY] Total active drivers in DB: ${activeDrivers.length}`,
    );

    const firebaseDriverLocations =
      await this.firebaseService.getAllDriverLocations();

    this.logger.log(
      `📊 [DELIVERY] Total driver locations from Firebase: ${firebaseDriverLocations.size}`,
    );

    const availableDrivers = activeDrivers
      .filter((driver) => {
        const fbData = firebaseDriverLocations.get(driver.id);
        return (
          fbData?.isOnline === true && fbData?.currentLat && fbData?.currentLng
        );
      })
      .map((driver) => {
        const fbData = firebaseDriverLocations.get(driver.id)!;
        return {
          ...driver,
          currentLat: fbData.currentLat,
          currentLng: fbData.currentLng,
          isOnline: fbData.isOnline,
        };
      });

    this.logger.log(
      `📊 [DELIVERY] Available drivers (online with location): ${availableDrivers.length}`,
    );

    const filteredDrivers = availableDrivers.filter(
      (driver) => !blockedDriverIds.includes(driver.id),
    );

    const driversInRadius = this.distanceService.filterByRadius(
      merchantCoord,
      filteredDrivers,
      (d) => ({ lat: d.currentLat, lng: d.currentLng }),
      searchRadiusKm,
    );

    this.logger.log(
      `📍 [DELIVERY] Drivers within ${searchRadiusKm}km radius: ${driversInRadius.length}`,
    );

    if (driversInRadius.length === 0) return [];

    const driversWithCapacity =
      await this.filterDriversByCapacity(driversInRadius);

    this.logger.log(
      `📊 [DELIVERY] Drivers after capacity filter: ${driversWithCapacity.length}`,
    );

    if (driversWithCapacity.length === 0) return [];

    // ── Step 9: Take top candidates for scoring ──
    // We take more than batchSize for scoring, then return top batchSize
    const candidateCount = Math.min(driversWithCapacity.length, batchSize * 2);
    const candidates = driversWithCapacity.slice(0, candidateCount);

    // Build DriverLocation objects + haversine distance map
    const driverLocations: DriverLocation[] = candidates.map((c) => ({
      id: c.item.id,
      firstName: c.item.firstName,
      lastName: c.item.lastName,
      phone: c.item.phone,
      email: c.item.email,
      currentLat: c.item.currentLat!,
      currentLng: c.item.currentLng!,
      notificationChannel: c.item.notificationChannel,
      fcmToken: c.item.firebaseToken || undefined,
    }));

    const haversineDistances = new Map<number, number>();
    candidates.forEach((c) => {
      haversineDistances.set(c.item.id, c.distanceMeters);
    });

    // ── Step 10: Smart scoring (Google Directions + acceptance rate) ──
    const scoredDrivers = await this.driverScoringService.scoreDrivers(
      merchantCoord,
      driverLocations,
      haversineDistances,
    );

    this.logger.log(
      `📊 [DELIVERY] Drivers after scoring: ${scoredDrivers.length}`,
    );

    const topDrivers = scoredDrivers.slice(0, batchSize);

    this.logger.log(`✅ [DELIVERY] Top ${topDrivers.length} selected drivers:`);
    for (const result of topDrivers) {
      this.logger.log(
        `  🚗 ${result.driver.firstName} ${result.driver.lastName} (ID: ${result.driver.id}) | ` +
          `Distance: ${result.routeDetails.realDistanceKm}km | ` +
          `ETA: ${result.routeDetails.etaMinutes}min | ` +
          `Score: ${result.finalScore} | ` +
          `AcceptRate: ${Math.round(result.acceptanceRate * 100)}%`,
      );
    }

    return topDrivers;
  }

  /**
   * Filter out drivers who have more incomplete orders than allowed.
   * This prevents assigning new orders to drivers who are already overwhelmed.
   */
  private async filterDriversByCapacity(
    drivers: { item: any; distanceMeters: number }[],
  ): Promise<{ item: any; distanceMeters: number }[]> {
    const maxIncomplete = await this.getMaxIncompleteOrdersForSearch();

    if (maxIncomplete === 0) {
      return drivers;
    }

    const incompleteStatuses = DELIVERY_RESTRICTIONS.INCOMPLETE_STATUSES;

    const assignments = await this.assignmentRepo.find({
      where: { status: DeliveryStatus.ACCEPTED },
      relations: ['order'],
    });

    const driverOrderCounts = new Map<number, number>();
    for (const assignment of assignments) {
      if (
        assignment.deliveryId &&
        assignment.order &&
        incompleteStatuses.includes(assignment.order.status)
      ) {
        const currentCount = driverOrderCounts.get(assignment.deliveryId) || 0;
        driverOrderCounts.set(assignment.deliveryId, currentCount + 1);
      }
    }

    const filteredDrivers = drivers.filter((d) => {
      const count = driverOrderCounts.get(d.item.id) || 0;
      if (count >= maxIncomplete) {
        return false;
      }
      return true;
    });

    return filteredDrivers;
  }

  /**
   * Get all blocked driver IDs for a given order.
   * Combines: already notified + active assignments + active orders + preparing with accepted.
   */
  private async getBlockedDriverIds(orderId: number): Promise<number[]> {
    // 1. Drivers already notified for this order
    const notifiedAssignments = await this.assignmentRepo.find({
      where: { orderId },
    });
    const notifiedDriverIds = notifiedAssignments.map((a) => a.deliveryId);

    // 2. Drivers with active delivery assignments
    const activeAssignments = await this.assignmentRepo
      .createQueryBuilder('assignment')
      .select('assignment.deliveryId')
      .where('assignment.status IN (:...activeStatuses)', {
        activeStatuses: [
          DeliveryStatus.ASSIGNED,
          DeliveryStatus.ACCEPTED,
          DeliveryStatus.PICKED,
        ],
      })
      .getRawMany();
    const activeDriverIds = activeAssignments.map(
      (a: any) => a.assignment_deliveryId,
    );

    // 3. Drivers with active orders
    const activeOrders = await this.orderRepo
      .createQueryBuilder('order')
      .select('deliveryAssignment.deliveryId', 'deliveryId')
      .leftJoin('order.deliveryAssignments', 'deliveryAssignment')
      .where('order.status IN (:...activeOrderStatuses)', {
        activeOrderStatuses: [
          OrderStatus.ASSIGNED,
          OrderStatus.READY_FOR_PICKUP,
          OrderStatus.PICKED_UP,
          OrderStatus.ON_THE_WAY,
        ],
      })
      .getRawMany();
    const driversWithActiveOrders = activeOrders
      .map((o: any) => o.deliveryId)
      .filter(Boolean);

    // 4. Drivers with PREPARING orders where they already accepted
    const preparingOrders = await this.orderRepo
      .createQueryBuilder('order')
      .select('deliveryAssignment.deliveryId', 'deliveryId')
      .leftJoin('order.deliveryAssignments', 'deliveryAssignment')
      .where('order.status = :preparingStatus', {
        preparingStatus: OrderStatus.PREPARING,
      })
      .andWhere('deliveryAssignment.acceptedAt IS NOT NULL')
      .getRawMany();
    const driversWithPreparingOrders = preparingOrders
      .map((o: any) => o.deliveryId)
      .filter(Boolean);

    // Combine all into unique set
    return [
      ...new Set([
        ...notifiedDriverIds,
        ...activeDriverIds,
        ...driversWithActiveOrders,
        ...driversWithPreparingOrders,
      ]),
    ];
  }

  // ─────────────────────────────────────────────────────────
  //  Send Delivery Notifications (READY_FOR_PICKUP / SEARCHING)
  // ─────────────────────────────────────────────────────────

  /**
   * Send delivery notifications to nearest drivers when order is ready for pickup.
   */
  async sendDeliveryNotifications(
    orderId: number,
    currentRadius?: number,
  ): Promise<void> {
    const order = await this.orderRepo.findOne({
      where: { id: orderId },
      relations: ['owner', 'deliveryAssignments'],
    });

    if (!order || !order.deliveryCoordinates) {
      throw new NotFoundException(ErrorCodes.DELIVERY_ORDER_NOT_FOUND.message);
    }

    if (
      order.status !== OrderStatus.READY_FOR_PICKUP &&
      order.status !== OrderStatus.SEARCHING
    ) {
      throw new BadRequestException(ErrorCodes.DELIVERY_INVALID_STATUS.message);
    }

    if (
      order.deliveryAssignment?.status === DeliveryStatus.ACCEPTED &&
      order.status === OrderStatus.READY_FOR_PICKUP
    ) {
      return;
    }

    if (!order.owner?.location?.lat || !order.owner?.location?.lng) {
      throw new BadRequestException('Merchant location is not available');
    }

    const merchantCoordinates = {
      latitude: order.owner.location.lat,
      longitude: order.owner.location.lng,
    };

    const config = await this.loadSearchConfig();

    const notifiedCount = order.deliveryAssignments?.length ?? 0;
    const estimatedAttempt = Math.floor(notifiedCount / config.batchSize) + 1;
    const searchRadius =
      currentRadius ?? this.calculateCurrentRadius(config, estimatedAttempt);

    // Smart search
    const scoredDrivers = await this.findNearestDriversSmart(
      orderId,
      merchantCoordinates,
      searchRadius,
      config.batchSize,
    );

    if (scoredDrivers.length === 0) {
      await this.scheduleDeliveryRetry(orderId, estimatedAttempt, searchRadius);
      return;
    }

    const nearestDrivers = scoredDrivers.map((r) => r.driver);

    for (const driver of nearestDrivers) {
      await this.sendDeliveryNotificationToDriver(order, driver);
    }

    await this.scheduleDeliveryTimeout(
      orderId,
      nearestDrivers.map((d) => d.id),
      searchRadius,
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Accept Delivery Assignment
  // ─────────────────────────────────────────────────────────

  /**
   * Accept delivery assignment
   */
  async acceptDeliveryAssignment(
    orderId: number,
    deliveryId: number,
    deliveryTime?: number,
  ): Promise<DeliveryAssignment> {
    const order = await this.orderRepo.findOne({
      where: { id: orderId },
      relations: ['deliveryAssignments', 'owner'],
    });

    if (!order) {
      throw new NotFoundException(
        `${ErrorCodes.DELIVERY_ORDER_NOT_FOUND.message} (ID: ${orderId})`,
      );
    }

    if (
      order.status !== OrderStatus.READY_FOR_PICKUP &&
      order.status !== OrderStatus.SEARCHING
    ) {
      throw new BadRequestException(ErrorCodes.DELIVERY_INVALID_STATUS.message);
    }

    // Check if already assigned (only for READY_FOR_PICKUP status)
    if (
      order.deliveryAssignment &&
      order.status === OrderStatus.READY_FOR_PICKUP
    ) {
      throw new BadRequestException(
        ErrorCodes.DELIVERY_ALREADY_ASSIGNED.message,
      );
    }

    // Check if driver has an active order
    const activeOrderCheck = await this.orderRepo
      .createQueryBuilder('order')
      .leftJoin('order.deliveryAssignments', 'assignment')
      .where('assignment.deliveryId = :deliveryId', { deliveryId })
      .andWhere('assignment.status = :acceptedStatus', {
        acceptedStatus: DeliveryStatus.ACCEPTED,
      })
      .andWhere('order.status IN (:...activeStatuses)', {
        activeStatuses: [
          OrderStatus.ASSIGNED,
          OrderStatus.READY_FOR_PICKUP,
          OrderStatus.PICKED_UP,
          OrderStatus.ON_THE_WAY,
        ],
      })
      .getOne();

    // Check for PREPARING orders where driver already accepted
    const preparingOrderCheck = await this.orderRepo
      .createQueryBuilder('order')
      .leftJoin('order.deliveryAssignments', 'assignment')
      .where('assignment.deliveryId = :deliveryId', { deliveryId })
      .andWhere('assignment.status = :acceptedStatus', {
        acceptedStatus: DeliveryStatus.ACCEPTED,
      })
      .andWhere('assignment.acceptedAt IS NOT NULL')
      .andWhere('order.status = :preparingStatus', {
        preparingStatus: OrderStatus.PREPARING,
      })
      .getOne();

    if (activeOrderCheck || preparingOrderCheck) {
      const activeOrder = activeOrderCheck ?? preparingOrderCheck;
      throw new BadRequestException(
        'لديك طلب نشط بالفعل. لا يمكنك قبول طلب جديد حتى تكمل الطلب الحالي.',
      );
    }

    // Create or update delivery assignment
    let assignment = await this.assignmentRepo.findOne({
      where: { orderId, deliveryId },
    });

    // Validate that driver was notified for SEARCHING orders
    if (order.status === OrderStatus.SEARCHING) {
      if (
        !assignment ||
        (assignment.status !== DeliveryStatus.NOTIFIED &&
          assignment.status !== DeliveryStatus.EXPIRED)
      ) {
        throw new BadRequestException(
          'عذراً، لم يتم إرسال طلب التوصيل هذا إليك. يمكنك قبول الطلبات المرسلة إليك فقط.',
        );
      }
    }

    if (assignment) {
      assignment.status = DeliveryStatus.ACCEPTED;
      assignment.acceptedAt = new Date();
    } else {
      assignment = this.assignmentRepo.create({
        orderId,
        deliveryId,
        status: DeliveryStatus.ACCEPTED,
        acceptedAt: new Date(),
        assignedAt: new Date(),
      });
    }

    const savedAssignment = await this.assignmentRepo.save(assignment);

    // Mark other notifications as EXPIRED
    await this.assignmentRepo
      .createQueryBuilder()
      .update(DeliveryAssignment)
      .set({ status: DeliveryStatus.EXPIRED })
      .where('orderId = :orderId', { orderId })
      .andWhere('id != :id', { id: savedAssignment.id })
      .andWhere('status = :notifiedStatus', {
        notifiedStatus: DeliveryStatus.NOTIFIED,
      })
      .execute();

    // Mark all other notifications for this driver as EXPIRED
    await this.assignmentRepo
      .createQueryBuilder()
      .update(DeliveryAssignment)
      .set({ status: DeliveryStatus.EXPIRED })
      .where('deliveryId = :deliveryId', { deliveryId })
      .andWhere('status = :notifiedStatus', {
        notifiedStatus: DeliveryStatus.NOTIFIED,
      })
      .execute();

    // Update order status
    const updateData: any = { status: OrderStatus.ASSIGNED };
    if (deliveryTime !== undefined && deliveryTime !== null) {
      updateData.deliveryTime = deliveryTime;
    }

    await this.orderRepo.update(orderId, updateData);

    order.status = OrderStatus.ASSIGNED;
    if (deliveryTime !== undefined && deliveryTime !== null) {
      order.deliveryTime = deliveryTime;
    }

    // Firebase RTDB: Update order status
    const documentExists =
      await this.firebaseService.orderDocumentExists(orderId);
    if (documentExists) {
      await this.firebaseService.updateOrderDocument(
        orderId,
        OrderStatus.ASSIGNED,
      );
      await this.firebaseService.setDeliveryId(orderId, deliveryId);
    }

    // Cancel any pending delivery notifications
    await this.cancelPendingDeliveryNotifications(orderId);

    // Firebase RTDB: Create driver document when delivery is accepted
    try {
      const driver = await this.userRepo.findOne({ where: { id: deliveryId } });
      if (driver) {
        await this.firebaseService.createDriverDocument({
          id: driver.id,
          currentLat: driver.currentLat,
          currentLng: driver.currentLng,
          isOnline: driver.isOnline,
        });
      }
    } catch {}

    this.logger.log(
      `Order ${orderId} assigned to delivery driver ${deliveryId}`,
    );

    return savedAssignment;
  }

  // ─────────────────────────────────────────────────────────
  //  Reject Delivery Assignment
  // ─────────────────────────────────────────────────────────

  /**
   * Reject delivery assignment
   */
  async rejectDeliveryAssignment(
    orderId: number,
    deliveryId: number,
    reason?: string,
  ): Promise<void> {
    // Log rejection
    await this.notificationLogRepo.save({
      userId: deliveryId,
      recipient: `Driver ${deliveryId}`,
      channel: NotificationChannel.WHATSAPP,
      type: NotificationType.ORDER_UPDATE,
      content: `Rejected delivery request for order #${orderId}`,
      status: NotificationStatus.FAILED,
      orderId,
      metadata: { reason },
    });

    this.logger.log(
      `Driver ${deliveryId} rejected delivery for order ${orderId}. Reason: ${reason}`,
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Legacy: Find Nearest Drivers (non-smart, kept for reference)
  // ─────────────────────────────────────────────────────────

  /**
   * @deprecated Use findNearestDriversSmart instead.
   * Kept for backward compatibility.
   */
  private async findNearestDeliveryDrivers(merchantCoordinates: {
    latitude: number;
    longitude: number;
  }): Promise<DriverLocation[]> {
    const activeDrivers = await this.userRepo
      .createQueryBuilder('user')
      .where('user.role = :role', { role: UserRole.DELIVERY })
      .andWhere('user.isActive = :isActive', { isActive: true })
      .getMany();

    const firebaseDriverLocations =
      await this.firebaseService.getAllDriverLocations();

    const availableDrivers = activeDrivers
      .filter((driver) => {
        const fbData = firebaseDriverLocations.get(driver.id);
        return (
          fbData?.isOnline === true && fbData?.currentLat && fbData?.currentLng
        );
      })
      .map((driver) => {
        const fbData = firebaseDriverLocations.get(driver.id)!;
        return {
          ...driver,
          currentLat: fbData.currentLat,
          currentLng: fbData.currentLng,
          isOnline: fbData.isOnline,
        };
      });

    const driversWithDistance: DriverDistance[] = availableDrivers.map(
      (driver) => {
        const distance = this.distanceService.calculateDistance(
          {
            lat: merchantCoordinates.latitude,
            lng: merchantCoordinates.longitude,
          },
          { lat: driver.currentLat, lng: driver.currentLng },
        );

        return {
          driver: {
            id: driver.id,
            firstName: driver.firstName,
            lastName: driver.lastName,
            phone: driver.phone,
            email: driver.email,
            currentLat: driver.currentLat,
            currentLng: driver.currentLng,
            notificationChannel: driver.notificationChannel,
            fcmToken: driver.firebaseToken || undefined,
          },
          distance,
        };
      },
    );

    driversWithDistance.sort((a, b) => a.distance - b.distance);
    return driversWithDistance.slice(0, 3).map((item) => item.driver);
  }

  // ─────────────────────────────────────────────────────────
  //  Notification Helpers
  // ─────────────────────────────────────────────────────────

  /**
   * Send notification to specific driver
   */
  private async sendDeliveryNotificationToDriver(
    order: Order,
    driver: DriverLocation,
  ): Promise<void> {
    try {
      // Create a delivery assignment record
      const assignment = this.assignmentRepo.create({
        orderId: order.id,
        deliveryId: driver.id,
        status: DeliveryStatus.NOTIFIED,
        notifiedAt: new Date(),
        assignedAt: new Date(),
      });
      await this.assignmentRepo.save(assignment);

      if (driver.fcmToken) {
        this.logger.log(
          `📱 [DELIVERY] Sending Firebase notification to driver ${driver.id} (${driver.firstName} ${driver.lastName})`,
        );
        await this.notificationsService.sendOrderNotificationToDriver(
          driver.fcmToken,
          order.id,
          order.totalAmount,
          order.deliveryCoordinates?.address || 'عنوان العميل',
        );
        this.logger.log(
          `✅ [DELIVERY] Firebase notification sent to driver ${driver.id} for order ${order.id} - Total: ${order.totalAmount}`,
        );
      } else {
        this.logger.log(
          `⚠️ [DELIVERY] No FCM token for driver ${driver.id} (${driver.firstName} ${driver.lastName}) - notification SKIPPED!`,
        );
      }

      if (driver.fcmToken) {
        // Log successful Firebase notification
        await this.notificationLogRepo.save({
          userId: driver.id,
          recipient: driver.fcmToken,
          channel: NotificationChannel.FIREBASE,
          type: NotificationType.ORDER_UPDATE,
          content: `Delivery request for order #${order.id}`,
          status: NotificationStatus.SENT,
          orderId: order.id,
        });
      }
    } catch (error) {
      this.logger.error(
        `Failed to send delivery notification to driver ${driver.id}`,
        error,
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Scheduling: Timeout & Retry
  // ─────────────────────────────────────────────────────────

  /**
   * Schedule delivery timeout check
   */
  private async scheduleDeliveryTimeout(
    orderId: number,
    driverIds: number[],
    currentRadius?: number,
  ): Promise<void> {
    const config = await this.loadSearchConfig();
    const timeoutMs = config.timeoutSeconds * 1000;

    await this.ordersQueue.add(
      'delivery-timeout',
      {
        orderId,
        driverIds,
        attempt: 1,
        currentRadius,
      } as QueueJobData,
      {
        delay: timeoutMs,
        attempts: 3,
        backoff: {
          type: 'exponential',
          delay: 2000,
        },
      },
    );
  }

  /**
   * Schedule delivery retry with next batch of drivers.
   * Expands search radius progressively.
   */
  async scheduleDeliveryRetry(
    orderId: number,
    attempt: number,
    currentRadius?: number,
  ): Promise<void> {
    const config = await this.loadSearchConfig();
    const nextRadius = this.calculateCurrentRadius(config, attempt + 1);

    // Stop if we exceeded max radius AND max attempts
    if (nextRadius >= config.maxSearchRadius && attempt > 5) {
      return;
    }

    try {
      const timeoutMs = config.timeoutSeconds * 1000;

      await this.ordersQueue.add(
        'delivery-retry',
        {
          orderId,
          attempt,
          currentRadius: nextRadius,
        } as QueueJobData,
        { delay: timeoutMs },
      );
      this.logger.log(
        `Scheduled delivery retry ${attempt} for order ${orderId} (nextRadius: ${nextRadius}km)`,
      );
    } catch (error) {
      this.logger.error(
        `Failed to schedule delivery retry for order ${orderId}`,
        error,
      );
    }
  }

  /**
   * Cancel pending delivery notifications
   */
  public async cancelPendingDeliveryNotifications(
    orderId: number,
  ): Promise<void> {
    try {
      const jobs = await this.ordersQueue.getJobs(['waiting', 'delayed']);
      const orderJobs = jobs.filter(
        (job) => (job.data as QueueJobData).orderId === orderId,
      );

      for (const job of orderJobs) {
        await job.remove();
      }

      this.logger.log(
        `Cancelled ${orderJobs.length} pending delivery notifications for order ${orderId}`,
      );
    } catch (error) {
      this.logger.error(
        `Failed to cancel pending notifications for order ${orderId}`,
        error,
      );
    }
  }
}

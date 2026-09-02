import {
  Injectable,
  BadRequestException,
  Logger,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In, DataSource } from 'typeorm';
import { DeliveryAssignmentService } from './delivery-assignment.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { CreateOrderDto } from '../dto/create-order.dto';
import { UserRole } from '../../../common/enums/user-role.enum';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { ImageEntityType } from '../../../common/enums/image-entity-type.enum';
import { NotificationType } from '../../../common/enums/notification-type.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { PaginationQueryDto } from '../../../common/dto/pagination-query.dto';
import { PaginatedResult } from '../../../common/interfaces/paginated-result.interface';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { Order } from '../../../database/entities/order.entity';
import { User } from '../../../database/entities/user.entity';
import { Image } from '../../../database/entities/image.entity';
import { OrderPaymentReceipt } from '../../../database/entities/order-payment-receipt.entity';
import { OrderPipeline } from '../pipeline/order-pipeline';
import { UpdateOrderPipeline } from '../pipeline/update-order-pipeline';
import { OrderManagementService } from './order-management.service';
import {
  ImageProcessingService,
  ProcessedImage,
} from '../../../common/image-processing/image-processing.service';
import { StorageService } from '../../../common/storage/storage.service';

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @Inject(forwardRef(() => DeliveryAssignmentService))
    private readonly deliveryAssignmentService: DeliveryAssignmentService,
    private readonly notificationsService: NotificationsService,
    private readonly orderPipeline: OrderPipeline,
    private readonly updateOrderPipeline: UpdateOrderPipeline,
    private readonly orderManagementService: OrderManagementService,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly storageService: StorageService,
    private readonly dataSource: DataSource,
  ) {}

  async create(
    createOrderDto: CreateOrderDto,
    userId: number,
  ): Promise<{
    order: {
      id: number;
      customerId: number;
      customer?: any;
      ownerId: number;
      owner?: any;
      tipAmount: number;
      platformCommission: number;
      ownerRevenue: number;
      currencyCode: string;
      paymentMethod: any;
      status: any;
      deliveryDeadline: Date;
      deliveryCoordinates: any;
      finalLocation: any;
      createdAt: Date;
      updatedAt: Date;
      items?: any;
      offers?: any;
      deliveryAssignment?: any;
      paymentTransaction?: any;
      priceBeforeDiscount: number;
      priceAfterProductDiscount: number;
      totalAmount: number;
      deliveryFee: number;
      discountAmount: number;
    };
  }> {
    const result = await this.orderPipeline.execute(createOrderDto, userId);

    if (!result.success) {
      this.logger.error(
        `Order creation failed at stage ${result.stage}: ${result.error}`,
      );
      throw new BadRequestException(result.error);
    }

    const order = await this.orderManagementService.findOne(
      result.data!.orderId!,
      userId,
      UserRole.CUSTOMER,
    );

    try {
      if (order.ownerId) {
        const merchant = await this.userRepo.findOne({
          where: { id: order.ownerId },
        });

        if (merchant) {
          await this.notificationsService.sendToUser(
            order.ownerId,
            NotificationType.ORDER_CREATED,
            'طلب جديد',
            `لديك طلب جديد #${order.id}`,
            merchant.notificationChannel || NotificationChannel.WHATSAPP,
            { orderId: String(order.id), amount: String(order.totalAmount) },
          );
          this.logger.log(
            `Notification sent to merchant ${order.ownerId} for order ${order.id}`,
          );
        }
      }
    } catch (error) {
      this.logger.error(`Failed to send notification to merchant: ${error}`);
    }

    return {
      order: {
        id: order.id,
        customerId: order.customerId,
        customer: order.customer,
        ownerId: order.ownerId ?? 0,
        owner: order.owner,
        paymentMethod: order.paymentMethod,
        status: order.status,
        deliveryDeadline: order.deliveryDeadline ?? new Date(),
        deliveryCoordinates: order.deliveryCoordinates,
        finalLocation: order.finalLocation,
        items: order.items,
        offers: order.offers,
        currencyCode: order.currencyCode,
        priceBeforeDiscount: order.priceBeforeDiscount,
        discountAmount: order.discountAmount ?? 0,
        priceAfterProductDiscount: order.priceAfterProductDiscount,
        tipAmount: order.tipAmount ?? 0,
        platformCommission: order.platformCommission ?? 0,
        ownerRevenue: order.ownerRevenue ?? 0,
        deliveryFee: order.deliveryFee ?? 0,
        totalAmount: order.totalAmount ?? 0,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
      },
    };
  }

  async findAll(
    query: {
      page: number;
      limit: number;
      search?: string;
      categoryId?: number;
      status?: OrderStatus | OrderStatus[];
      statuses?: OrderStatus | OrderStatus[];
    },
    userId: number,
    role: UserRole,
    status?: OrderStatus | OrderStatus[],
  ): Promise<PaginatedResult<any>> {
    return this.orderManagementService.findAll(query, userId, role, status);
  }

  async findOne(id: number, userId: number, role: UserRole): Promise<any> {
    return this.orderManagementService.findOne(id, userId, role);
  }

  async confirmOrder(
    orderId: number,
    userId: number,
    role: UserRole,
  ): Promise<Order> {
    const result = await this.updateOrderPipeline.execute(
      orderId,
      OrderStatus.CONFIRMED,
      userId,
      role,
      undefined,
      undefined,
      undefined,
      undefined,
    );

    if (!result.success) {
      this.logger.error(
        `Order confirm failed at stage ${result.stage}: ${result.error}`,
      );
      throw new BadRequestException(result.error);
    }

    return this.orderManagementService.findOne(orderId, userId, role) as any;
  }

  async rejectOrder(
    orderId: number,
    userId: number,
    role: UserRole,
    reason?: string,
  ): Promise<Order> {
    const result = await this.updateOrderPipeline.execute(
      orderId,
      OrderStatus.REJECTED,
      userId,
      role,
      reason,
    );

    if (!result.success) {
      this.logger.error(
        `Order reject failed at stage ${result.stage}: ${result.error}`,
      );
      throw new BadRequestException(result.error);
    }

    return this.orderManagementService.findOne(orderId, userId, role) as any;
  }

  async updateOrderStatus(
    orderId: number,
    newStatus: OrderStatus,
    userId: number,
    role: UserRole,
    reason?: string,
    finalLocation?: { lat: number; lng: number },
    mealPreparationTime?: number,
    deliveryTime?: number,
  ): Promise<Order> {
    const result = await this.updateOrderPipeline.execute(
      orderId,
      newStatus,
      userId,
      role,
      reason,
      finalLocation,
      mealPreparationTime,
      deliveryTime,
    );

    if (!result.success) {
      this.logger.error(
        `Order update failed at stage ${result.stage}: ${result.error}`,
      );
      throw new BadRequestException(result.error);
    }

    if (newStatus === OrderStatus.READY_FOR_PICKUP) {
      try {
        await this.deliveryAssignmentService.sendDeliveryNotifications(orderId);
      } catch (err) {
        this.logger.error('Failed to trigger delivery notification', err);
      }
    }

    return this.orderManagementService.findOne(orderId, userId, role) as any;
  }

  async updateOrder(
    orderId: number,
    userId: number,
    role: UserRole,
    updateOrderDto: any,
  ): Promise<Order> {
    const order = await this.orderManagementService.findOne(
      orderId,
      userId,
      role,
    );
    const result = await this.updateOrderPipeline.execute(
      orderId,
      order.status as OrderStatus,
      userId,
      role,
      undefined,
      undefined,
      undefined,
      undefined,
      updateOrderDto.items,
      updateOrderDto.itemsByProductId,
      updateOrderDto.itemsById,
      updateOrderDto.offersByOfferId,
      updateOrderDto.offersById,
      updateOrderDto.deletedProducts,
      updateOrderDto.deletedOffers,
      updateOrderDto.customerName,
      updateOrderDto.phone,
    );

    if (!result.success) {
      this.logger.error(
        `Order update failed at stage ${result.stage}: ${result.error}`,
      );
      throw new BadRequestException(result.error);
    }

    return this.orderManagementService.findOne(orderId, userId, role) as any;
  }

  async cancelOrder(
    orderId: number,
    userId: number,
    role: UserRole,
    reason?: string,
  ): Promise<Order> {
    return this.updateOrderStatus(
      orderId,
      OrderStatus.CANCELLED,
      userId,
      role,
      reason,
    );
  }

  async sendDeliveryNotifications(
    orderId: number,
    currentRadius?: number,
  ): Promise<void> {
    return this.deliveryAssignmentService.sendDeliveryNotifications(
      orderId,
      currentRadius,
    );
  }

  async acceptDeliveryAssignment(
    orderId: number,
    deliveryId: number,
    deliveryTime?: number,
  ): Promise<DeliveryAssignment> {
    return this.deliveryAssignmentService.acceptDeliveryAssignment(
      orderId,
      deliveryId,
      deliveryTime,
    );
  }

  async rejectDeliveryAssignment(
    orderId: number,
    deliveryId: number,
    reason?: string,
  ): Promise<void> {
    return this.deliveryAssignmentService.rejectDeliveryAssignment(
      orderId,
      deliveryId,
      reason,
    );
  }

  async scheduleDeliveryRetry(
    orderId: number,
    attempt: number,
    currentRadius?: number,
  ): Promise<void> {
    return this.deliveryAssignmentService.scheduleDeliveryRetry(
      orderId,
      attempt,
      currentRadius,
    );
  }

  async uploadPaid(
    orderIds: number[],
    files: Express.Multer.File[],
    userId: number,
    role: UserRole,
  ): Promise<{
    success: boolean;
    orders: {
      orderId: number;
      status: string;
      receipts: {
        id: number;
        imageId: number;
        url: string;
        thumbnailUrl: string;
        mobileUrl: string;
      }[];
    }[];
  }> {
    const results: {
      orderId: number;
      status: string;
      receipts: {
        id: number;
        imageId: number;
        url: string;
        thumbnailUrl: string;
        mobileUrl: string;
      }[];
    }[] = [];

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const imageRepo = queryRunner.manager.getRepository(Image);
      const receiptRepo =
        queryRunner.manager.getRepository(OrderPaymentReceipt);
      const deliveryAssignmentRepo =
        queryRunner.manager.getRepository(DeliveryAssignment);

      for (const orderId of orderIds) {
        const order = await queryRunner.manager.findOne(Order, {
          where: { id: orderId },
        });

        if (!order) {
          throw new BadRequestException({
            statusCode: 400,
            message: `Order with ID ${orderId} not found`,
            error: 'ERROR_4101',
            timestamp: new Date().toISOString(),
            path: '',
          });
        }

        if (order.status !== OrderStatus.DELIVERED) {
          throw new BadRequestException({
            statusCode: 400,
            message: `Order ${orderId} is not in DELIVERED status to upload receipt. Current status: ${order.status}`,
            error: 'ERROR_4108',
            timestamp: new Date().toISOString(),
            path: '',
          });
        }

        const createdImages: Image[] = [];

        for (const file of files) {
          const basePath = `payment-receipts/order-${orderId}`;

          const processed: ProcessedImage =
            await this.imageProcessingService.processAndUpload(file, basePath);

          const image = imageRepo.create({
            url: processed.original,
            thumbnailUrl: processed.thumbnail,
            mobileUrl: processed.mobile,
            entityType: ImageEntityType.PAYMENT_RECEIPT,
            entityId: orderId,
            isMain: false,
          });
          const savedImage = await imageRepo.save(image);
          createdImages.push(savedImage);
        }

        const receipts: Array<{
          id: number;
          imageId: number;
          url: string;
          thumbnailUrl: string;
          mobileUrl: string;
        }> = [];
        for (const image of createdImages) {
          const receipt = receiptRepo.create({
            orderId: orderId,
            imageId: image.id,
          });
          const savedReceipt = await receiptRepo.save(receipt);

          const imageUrl =
            this.storageService.resolveUrl(image.url) || image.url;
          const thumbnailUrl = (this.storageService.resolveUrl(
            image.thumbnailUrl || '',
          ) || image.thumbnailUrl) as string;
          const mobileUrl = (this.storageService.resolveUrl(
            image.mobileUrl || '',
          ) || image.mobileUrl) as string;

          receipts.push({
            id: savedReceipt.id,
            imageId: image.id,
            url: imageUrl,
            thumbnailUrl: thumbnailUrl || '',
            mobileUrl: mobileUrl || '',
          });
        }

        await queryRunner.manager.update(
          Order,
          { id: orderId },
          { status: OrderStatus.PAID },
        );

        const assignment = await deliveryAssignmentRepo.findOne({
          where: { orderId: orderId },
        });
        if (assignment) {
          assignment.paidAt = new Date();
          await deliveryAssignmentRepo.save(assignment);
        }

        results.push({
          orderId: orderId,
          status: OrderStatus.PAID,
          receipts: receipts,
        });
      }

      await queryRunner.commitTransaction();

      return {
        success: true,
        orders: results,
      };
    } catch (error) {
      await queryRunner.rollbackTransaction();

      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      this.logger.error(`Failed to upload paid receipt: ${errorMessage}`);

      throw new BadRequestException(
        `Failed to upload paid receipt: ${errorMessage}`,
      );
    } finally {
      await queryRunner.release();
    }
  }
}

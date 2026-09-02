import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { BadRequestException } from '@nestjs/common';
import { DataSource, Repository } from 'typeorm';
import { OrdersService } from '../../../../src/modules/orders/services/orders.service';
import { DeliveryAssignmentService } from '../../../../src/modules/orders/services/delivery-assignment.service';
import { NotificationsService } from '../../../../src/modules/notifications/notifications.service';
import { OrderPipeline } from '../../../../src/modules/orders/pipeline/order-pipeline';
import { UpdateOrderPipeline } from '../../../../src/modules/orders/pipeline/update-order-pipeline';
import { OrderManagementService } from '../../../../src/modules/orders/services/order-management.service';
import { ImageProcessingService } from '../../../../src/common/image-processing/image-processing.service';
import { StorageService } from '../../../../src/common/storage/storage.service';
import { CreateOrderDto } from '../../../../src/modules/orders/dto/create-order.dto';
import { OrderStatus } from '../../../../src/common/enums/order-status.enum';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { Order } from '../../../../src/database/entities/order.entity';
import { User } from '../../../../src/database/entities/user.entity';
import { DeliveryAssignment } from '../../../../src/database/entities/delivery-assignment.entity';
import { OrderPaymentReceipt } from '../../../../src/database/entities/order-payment-receipt.entity';
import { NotificationChannel } from '../../../../src/common/enums/notification-channel.enum';
import { NotificationType } from '../../../../src/common/enums/notification-type.enum';

describe('OrdersService', () => {
  let service: OrdersService;
  let orderRepo: jest.Mocked<Repository<Order>>;
  let userRepo: jest.Mocked<Repository<User>>;
  let deliveryAssignmentService: jest.Mocked<DeliveryAssignmentService>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let orderPipeline: jest.Mocked<OrderPipeline>;
  let updateOrderPipeline: jest.Mocked<UpdateOrderPipeline>;
  let orderManagementService: jest.Mocked<OrderManagementService>;
  let imageProcessingService: jest.Mocked<ImageProcessingService>;
  let storageService: jest.Mocked<StorageService>;
  let dataSource: jest.Mocked<DataSource>;

  const mockOrderId = 1;
  const mockUserId = 10;
  const mockMerchantId = 20;

  const mockOrder = {
    id: mockOrderId,
    customerId: mockUserId,
    ownerId: mockMerchantId,
    status: OrderStatus.PENDING,
    totalAmount: 5000,
    deliveryFee: 1000,
    discountAmount: 0,
    tipAmount: 0,
    platformCommission: 500,
    ownerRevenue: 3500,
    paymentMethod: 'CASH',
    currencyCode: 'SAR',
    deliveryDeadline: new Date(),
    deliveryCoordinates: { latitude: 24.7, longitude: 46.7 },
    finalLocation: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    items: [],
    offers: [],
    customer: { id: mockUserId },
    owner: { id: mockMerchantId },
    priceBeforeDiscount: 5000,
    priceAfterProductDiscount: 5000,
  } as any;

  const mockMerchant = {
    id: mockMerchantId,
    notificationChannel: NotificationChannel.WHATSAPP,
  } as User;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrdersService,
        {
          provide: getRepositoryToken(Order),
          useValue: { findOne: jest.fn(), find: jest.fn() },
        },
        {
          provide: getRepositoryToken(User),
          useValue: { findOne: jest.fn() },
        },
        {
          provide: DeliveryAssignmentService,
          useValue: {
            sendDeliveryNotifications: jest.fn(),
            acceptDeliveryAssignment: jest.fn(),
            rejectDeliveryAssignment: jest.fn(),
            scheduleDeliveryRetry: jest.fn(),
          },
        },
        {
          provide: NotificationsService,
          useValue: { sendToUser: jest.fn() },
        },
        {
          provide: OrderPipeline,
          useValue: { execute: jest.fn() },
        },
        {
          provide: UpdateOrderPipeline,
          useValue: { execute: jest.fn() },
        },
        {
          provide: OrderManagementService,
          useValue: {
            findOne: jest.fn(),
            findAll: jest.fn(),
          },
        },
        {
          provide: ImageProcessingService,
          useValue: { processAndUpload: jest.fn() },
        },
        {
          provide: StorageService,
          useValue: { resolveUrl: jest.fn() },
        },
        {
          provide: DataSource,
          useValue: { createQueryRunner: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<OrdersService>(OrdersService);
    orderRepo = module.get(getRepositoryToken(Order));
    userRepo = module.get(getRepositoryToken(User));
    deliveryAssignmentService = module.get(DeliveryAssignmentService);
    notificationsService = module.get(NotificationsService);
    orderPipeline = module.get(OrderPipeline);
    updateOrderPipeline = module.get(UpdateOrderPipeline);
    orderManagementService = module.get(OrderManagementService);
    imageProcessingService = module.get(ImageProcessingService);
    storageService = module.get(StorageService);
    dataSource = module.get(DataSource);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    const createDto = {
      ownerId: mockMerchantId,
      paymentMethod: 'CASH',
    } as CreateOrderDto;

    it('ينشئ طلباً ويعيد بياناته', async () => {
      orderPipeline.execute.mockResolvedValue({
        success: true,
        data: { orderId: mockOrderId },
      } as any);
      orderManagementService.findOne.mockResolvedValue(mockOrder);
      userRepo.findOne.mockResolvedValue(mockMerchant);
      notificationsService.sendToUser.mockResolvedValue(undefined);

      const result = await service.create(createDto, mockUserId);

      expect(result).toBeDefined();
      expect(result.order).toBeDefined();
      expect(result.order.id).toBe(mockOrderId);
      expect(orderPipeline.execute).toHaveBeenCalledWith(createDto, mockUserId);
      expect(notificationsService.sendToUser).toHaveBeenCalledWith(
        mockMerchantId,
        NotificationType.ORDER_CREATED,
        'طلب جديد',
        expect.any(String),
        NotificationChannel.WHATSAPP,
        expect.any(Object),
      );
    });

    it('يرمي BadRequestException إذا فشل الـ pipeline', async () => {
      orderPipeline.execute.mockResolvedValue({
        success: false,
        stage: 'validation',
        error: 'Invalid data',
      } as any);

      await expect(service.create(createDto, mockUserId)).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('findAll', () => {
    it('يفوض إلى OrderManagementService.findAll', async () => {
      const query = { page: 1, limit: 10 };
      const expected = { data: [], total: 0 };
      orderManagementService.findAll.mockResolvedValue(expected as any);

      const result = await service.findAll(query, mockUserId, UserRole.ADMIN);

      expect(result).toBe(expected);
      expect(orderManagementService.findAll).toHaveBeenCalledWith(
        query,
        mockUserId,
        UserRole.ADMIN,
        undefined,
      );
    });
  });

  describe('findOne', () => {
    it('يفوض إلى OrderManagementService.findOne', async () => {
      orderManagementService.findOne.mockResolvedValue(mockOrder);

      const result = await service.findOne(
        mockOrderId,
        mockUserId,
        UserRole.CUSTOMER,
      );

      expect(result).toBe(mockOrder);
      expect(orderManagementService.findOne).toHaveBeenCalledWith(
        mockOrderId,
        mockUserId,
        UserRole.CUSTOMER,
      );
    });
  });

  describe('confirmOrder', () => {
    it('يؤكد الطلب ويعيد بياناته', async () => {
      updateOrderPipeline.execute.mockResolvedValue({ success: true } as any);
      orderManagementService.findOne.mockResolvedValue({
        ...mockOrder,
        status: OrderStatus.CONFIRMED,
      });

      const result = await service.confirmOrder(
        mockOrderId,
        mockUserId,
        UserRole.MERCHANT,
      );

      expect(result).toBeDefined();
      expect(updateOrderPipeline.execute).toHaveBeenCalledWith(
        mockOrderId,
        OrderStatus.CONFIRMED,
        mockUserId,
        UserRole.MERCHANT,
        undefined,
        undefined,
        undefined,
        undefined,
      );
    });

    it('يرمي BadRequestException إذا فشل التأكيد', async () => {
      updateOrderPipeline.execute.mockResolvedValue({
        success: false,
        stage: 'authorization',
        error: 'Unauthorized',
      } as any);

      await expect(
        service.confirmOrder(mockOrderId, mockUserId, UserRole.CUSTOMER),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('rejectOrder', () => {
    it('يرفض الطلب ويعيد بياناته', async () => {
      updateOrderPipeline.execute.mockResolvedValue({ success: true } as any);
      orderManagementService.findOne.mockResolvedValue({
        ...mockOrder,
        status: OrderStatus.REJECTED,
      });

      const result = await service.rejectOrder(
        mockOrderId,
        mockUserId,
        UserRole.MERCHANT,
        'Out of stock',
      );

      expect(result).toBeDefined();
      expect(updateOrderPipeline.execute).toHaveBeenCalledWith(
        mockOrderId,
        OrderStatus.REJECTED,
        mockUserId,
        UserRole.MERCHANT,
        'Out of stock',
      );
    });
  });

  describe('updateOrderStatus', () => {
    it('يحدّث حالة الطلب ويعيد بياناته', async () => {
      updateOrderPipeline.execute.mockResolvedValue({ success: true } as any);
      orderManagementService.findOne.mockResolvedValue({
        ...mockOrder,
        status: OrderStatus.CONFIRMED,
      });

      const result = await service.updateOrderStatus(
        mockOrderId,
        OrderStatus.CONFIRMED,
        mockUserId,
        UserRole.MERCHANT,
      );

      expect(result).toBeDefined();
      expect(updateOrderPipeline.execute).toHaveBeenCalledWith(
        mockOrderId,
        OrderStatus.CONFIRMED,
        mockUserId,
        UserRole.MERCHANT,
        undefined,
        undefined,
        undefined,
        undefined,
      );
    });

    it('يُرسل إشعارات التوصيل عندما تكون الحالة READY_FOR_PICKUP', async () => {
      updateOrderPipeline.execute.mockResolvedValue({ success: true } as any);
      orderManagementService.findOne.mockResolvedValue({
        ...mockOrder,
        status: OrderStatus.READY_FOR_PICKUP,
      });

      await service.updateOrderStatus(
        mockOrderId,
        OrderStatus.READY_FOR_PICKUP,
        mockUserId,
        UserRole.MERCHANT,
      );

      expect(
        deliveryAssignmentService.sendDeliveryNotifications,
      ).toHaveBeenCalledWith(mockOrderId);
    });

    it('يرمي BadRequestException إذا فشل التحديث', async () => {
      updateOrderPipeline.execute.mockResolvedValue({
        success: false,
        stage: 'statusTransition',
        error: 'Invalid transition',
      } as any);

      await expect(
        service.updateOrderStatus(
          mockOrderId,
          OrderStatus.DELIVERED,
          mockUserId,
          UserRole.CUSTOMER,
        ),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('updateOrder', () => {
    it('يحدّث الطلب ويعيد بياناته', async () => {
      orderManagementService.findOne.mockResolvedValue(mockOrder);
      updateOrderPipeline.execute.mockResolvedValue({ success: true } as any);
      orderManagementService.findOne.mockResolvedValue(mockOrder);

      const dto = { customerName: 'Updated' };

      const result = await service.updateOrder(
        mockOrderId,
        mockUserId,
        UserRole.ADMIN,
        dto,
      );

      expect(result).toBeDefined();
      expect(updateOrderPipeline.execute).toHaveBeenCalledWith(
        mockOrderId,
        OrderStatus.PENDING,
        mockUserId,
        UserRole.ADMIN,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        undefined,
        'Updated',
        undefined,
      );
    });
  });

  describe('cancelOrder', () => {
    it('يلغي الطلب عبر updateOrderStatus', async () => {
      updateOrderPipeline.execute.mockResolvedValue({ success: true } as any);
      orderManagementService.findOne.mockResolvedValue({
        ...mockOrder,
        status: OrderStatus.CANCELLED,
      });

      const result = await service.cancelOrder(
        mockOrderId,
        mockUserId,
        UserRole.CUSTOMER,
        'Changed mind',
      );

      expect(result).toBeDefined();
      expect(updateOrderPipeline.execute).toHaveBeenCalledWith(
        mockOrderId,
        OrderStatus.CANCELLED,
        mockUserId,
        UserRole.CUSTOMER,
        'Changed mind',
        undefined,
        undefined,
        undefined,
      );
    });
  });

  describe('sendDeliveryNotifications', () => {
    it('يفوض إلى DeliveryAssignmentService', async () => {
      await service.sendDeliveryNotifications(mockOrderId);

      expect(
        deliveryAssignmentService.sendDeliveryNotifications,
      ).toHaveBeenCalledWith(mockOrderId, undefined);
    });
  });

  describe('acceptDeliveryAssignment', () => {
    it('يفوض إلى DeliveryAssignmentService', async () => {
      const mockAssignment = {
        id: 1,
        orderId: mockOrderId,
        deliveryId: 5,
      } as DeliveryAssignment;
      deliveryAssignmentService.acceptDeliveryAssignment.mockResolvedValue(
        mockAssignment,
      );

      const result = await service.acceptDeliveryAssignment(mockOrderId, 5, 30);

      expect(result).toBe(mockAssignment);
      expect(
        deliveryAssignmentService.acceptDeliveryAssignment,
      ).toHaveBeenCalledWith(mockOrderId, 5, 30);
    });
  });

  describe('rejectDeliveryAssignment', () => {
    it('يفوض إلى DeliveryAssignmentService', async () => {
      await service.rejectDeliveryAssignment(mockOrderId, 5, 'Too far');

      expect(
        deliveryAssignmentService.rejectDeliveryAssignment,
      ).toHaveBeenCalledWith(mockOrderId, 5, 'Too far');
    });
  });

  describe('scheduleDeliveryRetry', () => {
    it('يفوض إلى DeliveryAssignmentService', async () => {
      await service.scheduleDeliveryRetry(mockOrderId, 1, 5);

      expect(
        deliveryAssignmentService.scheduleDeliveryRetry,
      ).toHaveBeenCalledWith(mockOrderId, 1, 5);
    });
  });

  describe('uploadPaid', () => {
    const mockFile = {
      originalname: 'receipt.jpg',
      buffer: Buffer.from('test'),
    } as Express.Multer.File;
    const mockProcessedImage = {
      original: '/uploads/original.jpg',
      thumbnail: '/uploads/thumb.jpg',
      mobile: '/uploads/mobile.jpg',
    };

    it('يرفع إيصال الدفع بنجاح', async () => {
      const mockImageRepo = {
        create: jest.fn().mockReturnValue({ id: 1 }),
        save: jest.fn().mockResolvedValue({ id: 1 }),
      } as any;
      const mockReceiptRepo = {
        create: jest.fn().mockReturnValue({ id: 1 }),
        save: jest.fn().mockResolvedValue({ id: 1 }),
      } as any;
      const mockDABase = {
        findOne: jest.fn(),
        save: jest.fn(),
      } as any;
      const mockQueryRunner = {
        connect: jest.fn(),
        startTransaction: jest.fn(),
        commitTransaction: jest.fn(),
        rollbackTransaction: jest.fn(),
        release: jest.fn(),
        manager: {
          findOne: jest
            .fn()
            .mockResolvedValue({ ...mockOrder, status: OrderStatus.DELIVERED }),
          getRepository: jest.fn().mockImplementation((entity: any) => {
            if (entity === OrderPaymentReceipt) return mockReceiptRepo;
            if (entity === DeliveryAssignment) return mockDABase;
            return mockImageRepo;
          }),
          update: jest.fn().mockResolvedValue({ affected: 1 }),
        },
      } as any;

      dataSource.createQueryRunner.mockReturnValue(mockQueryRunner);
      imageProcessingService.processAndUpload.mockResolvedValue(
        mockProcessedImage,
      );
      storageService.resolveUrl.mockReturnValue(
        'https://cdn.example.com/image.jpg',
      );

      const result = await service.uploadPaid(
        [mockOrderId],
        [mockFile],
        mockUserId,
        UserRole.DELIVERY,
      );

      expect(result.success).toBe(true);
      expect(result.orders).toHaveLength(1);
      expect(mockQueryRunner.commitTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.release).toHaveBeenCalled();
    });

    it('يرمي BadRequestException إذا لم يكن الطلب DELIVERED', async () => {
      const mockQueryRunner = {
        connect: jest.fn(),
        startTransaction: jest.fn(),
        commitTransaction: jest.fn(),
        rollbackTransaction: jest.fn(),
        release: jest.fn(),
        manager: {
          findOne: jest
            .fn()
            .mockResolvedValue({ ...mockOrder, status: OrderStatus.PENDING }),
          getRepository: jest.fn().mockReturnValue({}),
        },
      } as any;
      dataSource.createQueryRunner.mockReturnValue(mockQueryRunner);

      await expect(
        service.uploadPaid(
          [mockOrderId],
          [mockFile],
          mockUserId,
          UserRole.DELIVERY,
        ),
      ).rejects.toThrow(BadRequestException);

      expect(mockQueryRunner.rollbackTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.release).toHaveBeenCalled();
    });
  });
});

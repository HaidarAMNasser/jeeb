import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { getQueueToken } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { Repository } from 'typeorm';
import { DeliveryAssignmentService } from '../../../../src/modules/orders/services/delivery-assignment.service';
import { NotificationsService } from '../../../../src/modules/notifications/notifications.service';
import { DistanceService } from '../../../../src/modules/distance/distance.service';
import { FirebaseService } from '../../../../src/modules/firebase/firebase.service';
import { SettingsService } from '../../../../src/modules/settings/settings.service';
import { DriverScoringService } from '../../../../src/modules/orders/services/driver-scoring.service';
import { OrderStatus, DeliveryStatus } from '../../../../src/common/enums';
import { NotificationType } from '../../../../src/common/enums/notification-type.enum';
import { NotificationChannel } from '../../../../src/common/enums/notification-channel.enum';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { Order } from '../../../../src/database/entities/order.entity';
import { DeliveryAssignment } from '../../../../src/database/entities/delivery-assignment.entity';
import { User } from '../../../../src/database/entities/user.entity';
import { NotificationLog } from '../../../../src/database/entities/notification-log.entity';
import { ErrorCodes } from '../../../../src/common/constants/error-codes';

describe('DeliveryAssignmentService', () => {
  let service: DeliveryAssignmentService;
  let orderRepo: jest.Mocked<Repository<Order>>;
  let assignmentRepo: jest.Mocked<Repository<DeliveryAssignment>>;
  let userRepo: jest.Mocked<Repository<User>>;
  let notificationLogRepo: jest.Mocked<Repository<NotificationLog>>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let distanceService: jest.Mocked<DistanceService>;
  let firebaseService: jest.Mocked<FirebaseService>;
  let settingsService: jest.Mocked<SettingsService>;
  let driverScoringService: jest.Mocked<DriverScoringService>;
  let ordersQueue: jest.Mocked<Queue>;

  const mockOrderId = 1;
  const mockDeliveryId = 30;
  const mockMerchantId = 20;

  const mockOrder: Partial<Order> = {
    id: mockOrderId,
    ownerId: mockMerchantId,
    status: OrderStatus.SEARCHING,
    deliveryCoordinates: {
      latitude: 24.7,
      longitude: 46.7,
      address: 'العنوان',
    },
    totalAmount: 5000,
    owner: {
      id: mockMerchantId,
      location: { lat: 24.71, lng: 46.71 },
    } as any,
    deliveryAssignments: [],
  };

  const mockDriver: Partial<User> = {
    id: mockDeliveryId,
    firstName: 'Driver',
    lastName: 'Test',
    role: UserRole.DELIVERY,
    isActive: true,
  };

  const mockAssignment: Partial<DeliveryAssignment> = {
    id: 1,
    orderId: mockOrderId,
    deliveryId: mockDeliveryId,
    status: DeliveryStatus.NOTIFIED,
    notifiedAt: new Date(),
    assignedAt: new Date(),
  };

  // Shared query builder mock for all createQueryBuilder calls
  let mockQB: any;

  beforeEach(async () => {
    mockQB = {
      select: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      leftJoin: jest.fn().mockReturnThis(),
      leftJoinAndSelect: jest.fn().mockReturnThis(),
      getRawMany: jest.fn().mockResolvedValue([]),
      getMany: jest.fn().mockResolvedValue([]),
      getOne: jest.fn().mockResolvedValue(null),
      update: jest.fn().mockReturnThis(),
      set: jest.fn().mockReturnThis(),
      execute: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeliveryAssignmentService,
        {
          provide: getRepositoryToken(Order),
          useValue: {
            findOne: jest.fn(),
            createQueryBuilder: jest.fn().mockReturnValue(mockQB),
            update: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(DeliveryAssignment),
          useValue: {
            find: jest.fn(),
            findOne: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
            createQueryBuilder: jest.fn().mockReturnValue(mockQB),
          },
        },
        {
          provide: getRepositoryToken(User),
          useValue: {
            createQueryBuilder: jest.fn().mockReturnValue(mockQB),
            findOne: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(NotificationLog),
          useValue: { save: jest.fn() },
        },
        {
          provide: NotificationsService,
          useValue: {
            sendToUser: jest.fn(),
            sendOrderNotificationToDriver: jest.fn(),
          },
        },
        {
          provide: DistanceService,
          useValue: {
            filterByRadius: jest.fn(),
            calculateDistance: jest.fn(),
          },
        },
        {
          provide: FirebaseService,
          useValue: {
            getAllDriverLocations: jest.fn(),
            orderDocumentExists: jest.fn(),
            updateOrderDocument: jest.fn(),
            setDeliveryId: jest.fn(),
            createDriverDocument: jest.fn(),
          },
        },
        {
          provide: SettingsService,
          useValue: { getSettingByKey: jest.fn() },
        },
        {
          provide: DriverScoringService,
          useValue: { scoreDrivers: jest.fn() },
        },
        {
          provide: getQueueToken('orders'),
          useValue: {
            add: jest.fn(),
            getJobs: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<DeliveryAssignmentService>(DeliveryAssignmentService);
    orderRepo = module.get(getRepositoryToken(Order));
    assignmentRepo = module.get(getRepositoryToken(DeliveryAssignment));
    userRepo = module.get(getRepositoryToken(User));
    notificationLogRepo = module.get(getRepositoryToken(NotificationLog));
    notificationsService = module.get(NotificationsService);
    distanceService = module.get(DistanceService);
    firebaseService = module.get(FirebaseService);
    settingsService = module.get(SettingsService);
    driverScoringService = module.get(DriverScoringService);
    ordersQueue = module.get(getQueueToken('orders'));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('startSearchingForDriver', () => {
    beforeEach(() => {
      settingsService.getSettingByKey.mockResolvedValue(null);
    });

    it('يبدأ البحث عن سائق ويعيد النتيجة', async () => {
      orderRepo.findOne.mockResolvedValue(mockOrder as Order);
      assignmentRepo.find.mockResolvedValue([]);
      mockQB.getMany.mockResolvedValue([mockDriver as User]);

      const mockFbLocations = new Map<number, any>();
      mockFbLocations.set(mockDeliveryId, {
        isOnline: true,
        currentLat: 24.8,
        currentLng: 46.8,
      });
      firebaseService.getAllDriverLocations.mockResolvedValue(mockFbLocations);

      distanceService.filterByRadius.mockReturnValue([
        {
          item: {
            id: mockDeliveryId,
            firstName: 'Driver',
            lastName: 'Test',
            phone: '123',
            email: 'd@t.com',
            currentLat: 24.8,
            currentLng: 46.8,
            notificationChannel: 'FIREBASE',
            firebaseToken: 'token',
          },
          distanceMeters: 1000,
        },
      ]);

      driverScoringService.scoreDrivers.mockResolvedValue([
        {
          driver: {
            id: mockDeliveryId,
            firstName: 'Driver',
            lastName: 'Test',
            phone: '123',
            email: 'd@t.com',
            currentLat: 24.8,
            currentLng: 46.8,
            notificationChannel: 'FIREBASE',
            fcmToken: 'token',
          },
          routeDetails: { realDistanceKm: 1, etaMinutes: 5 },
          finalScore: 0.2,
          acceptanceRate: 0.8,
        },
      ]);

      assignmentRepo.create.mockReturnValue(
        mockAssignment as DeliveryAssignment,
      );
      assignmentRepo.save.mockResolvedValue(
        mockAssignment as DeliveryAssignment,
      );

      await service.startSearchingForDriver(mockOrderId);

      expect(orderRepo.findOne).toHaveBeenCalledWith({
        where: { id: mockOrderId },
        relations: ['owner', 'deliveryAssignments'],
      });
      expect(ordersQueue.add).toHaveBeenCalled();
    });

    it('يرمي NotFoundException إذا كان الطلب غير موجود', async () => {
      orderRepo.findOne.mockResolvedValue(null);

      await expect(service.startSearchingForDriver(999)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('يعود مباشرة إذا لم يكن الطلب SEARCHING', async () => {
      orderRepo.findOne.mockResolvedValue({
        ...mockOrder,
        status: OrderStatus.PENDING,
      } as Order);

      await service.startSearchingForDriver(mockOrderId);

      expect(userRepo.createQueryBuilder).not.toHaveBeenCalled();
    });

    it('يُجدد المحاولة إذا لم يُعثر على سائقين', async () => {
      orderRepo.findOne.mockResolvedValue(mockOrder as Order);
      assignmentRepo.find.mockResolvedValue([]);
      mockQB.getMany.mockResolvedValue([]);
      firebaseService.getAllDriverLocations.mockResolvedValue(new Map());
      distanceService.filterByRadius.mockReturnValue([]);

      await service.startSearchingForDriver(mockOrderId);

      expect(ordersQueue.add).toHaveBeenCalledWith(
        'delivery-retry',
        expect.objectContaining({ orderId: mockOrderId }),
        expect.any(Object),
      );
    });
  });

  describe('sendDeliveryNotifications', () => {
    beforeEach(() => {
      settingsService.getSettingByKey.mockResolvedValue(null);
    });

    it('يُرسل إشعارات التوصيل', async () => {
      const readyOrder = {
        ...mockOrder,
        deliveryAssignment: null,
        status: OrderStatus.READY_FOR_PICKUP,
      } as Order;
      orderRepo.findOne.mockResolvedValue(readyOrder);
      assignmentRepo.find.mockResolvedValue([]);
      mockQB.getMany.mockResolvedValue([mockDriver as User]);

      const mockFbLocations = new Map<number, any>();
      mockFbLocations.set(mockDeliveryId, {
        isOnline: true,
        currentLat: 24.8,
        currentLng: 46.8,
      });
      firebaseService.getAllDriverLocations.mockResolvedValue(mockFbLocations);

      distanceService.filterByRadius.mockReturnValue([
        {
          item: {
            id: mockDeliveryId,
            firstName: 'Driver',
            lastName: 'Test',
            phone: '123',
            email: 'd@t.com',
            currentLat: 24.8,
            currentLng: 46.8,
            notificationChannel: 'FIREBASE',
            firebaseToken: 'token',
          },
          distanceMeters: 1000,
        },
      ]);

      driverScoringService.scoreDrivers.mockResolvedValue([
        {
          driver: {
            id: mockDeliveryId,
            firstName: 'Driver',
            lastName: 'Test',
            phone: '123',
            email: 'd@t.com',
            currentLat: 24.8,
            currentLng: 46.8,
            notificationChannel: 'FIREBASE',
            fcmToken: 'token',
          },
          routeDetails: { realDistanceKm: 1, etaMinutes: 5 },
          finalScore: 0.2,
          acceptanceRate: 0.8,
        },
      ]);

      assignmentRepo.create.mockReturnValue(
        mockAssignment as DeliveryAssignment,
      );
      assignmentRepo.save.mockResolvedValue(
        mockAssignment as DeliveryAssignment,
      );

      await service.sendDeliveryNotifications(mockOrderId);

      expect(orderRepo.findOne).toHaveBeenCalled();
      expect(
        notificationsService.sendOrderNotificationToDriver,
      ).toHaveBeenCalled();
      expect(ordersQueue.add).toHaveBeenCalled();
    });

    it('يرمي NotFoundException إذا كان الطلب غير موجود', async () => {
      orderRepo.findOne.mockResolvedValue(null);

      await expect(service.sendDeliveryNotifications(999)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('يرمي BadRequestException إذا كانت الحالة غير صالحة', async () => {
      orderRepo.findOne.mockResolvedValue({
        ...mockOrder,
        status: OrderStatus.PENDING,
      } as Order);

      await expect(
        service.sendDeliveryNotifications(mockOrderId),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('acceptDeliveryAssignment', () => {
    it('يقبل السائق التعيين', async () => {
      orderRepo.findOne.mockResolvedValue(mockOrder as Order);
      assignmentRepo.findOne.mockResolvedValue(
        mockAssignment as DeliveryAssignment,
      );
      assignmentRepo.save.mockResolvedValue({
        ...mockAssignment,
        status: DeliveryStatus.ACCEPTED,
      } as DeliveryAssignment);
      mockQB.getOne.mockResolvedValue(null);
      orderRepo.update.mockResolvedValue({ affected: 1 } as any);
      firebaseService.orderDocumentExists.mockResolvedValue(false);
      userRepo.findOne.mockResolvedValue(mockDriver as User);

      const result = await service.acceptDeliveryAssignment(
        mockOrderId,
        mockDeliveryId,
      );

      expect(result.status).toBe(DeliveryStatus.ACCEPTED);
      expect(orderRepo.update).toHaveBeenCalledWith(mockOrderId, {
        status: OrderStatus.ASSIGNED,
      });
    });

    it('يرمي NotFoundException إذا كان الطلب غير موجود', async () => {
      orderRepo.findOne.mockResolvedValue(null);

      await expect(
        service.acceptDeliveryAssignment(999, mockDeliveryId),
      ).rejects.toThrow(NotFoundException);
    });

    it('يرمي BadRequestException إذا كان السائق لديه طلب نشط', async () => {
      orderRepo.findOne.mockResolvedValue(mockOrder as Order);
      mockQB.getOne.mockResolvedValue({ id: 5 } as Order);

      await expect(
        service.acceptDeliveryAssignment(mockOrderId, mockDeliveryId),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('rejectDeliveryAssignment', () => {
    it('يسجل رفض السائق', async () => {
      notificationLogRepo.save.mockResolvedValue({} as NotificationLog);

      await service.rejectDeliveryAssignment(
        mockOrderId,
        mockDeliveryId,
        'Too far',
      );

      expect(notificationLogRepo.save).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: mockDeliveryId,
          orderId: mockOrderId,
          status: 'FAILED',
        }),
      );
    });
  });

  describe('scheduleDeliveryRetry', () => {
    it('يُجدد محاولة البحث', async () => {
      settingsService.getSettingByKey.mockResolvedValue(null);

      await service.scheduleDeliveryRetry(mockOrderId, 1, 5);

      expect(ordersQueue.add).toHaveBeenCalledWith(
        'delivery-retry',
        expect.objectContaining({ orderId: mockOrderId, attempt: 1 }),
        expect.any(Object),
      );
    });

    it('يتوقف إذا تجاوز أقصى نصف قطر وأقصى محاولات', async () => {
      settingsService.getSettingByKey.mockResolvedValue(null);

      await service.scheduleDeliveryRetry(mockOrderId, 10, 20);

      expect(ordersQueue.add).not.toHaveBeenCalled();
    });
  });

  describe('cancelPendingDeliveryNotifications', () => {
    it('يلغي إشعارات التوصيل المعلقة', async () => {
      const mockJob = {
        remove: jest.fn(),
        data: { orderId: mockOrderId },
      } as any;
      ordersQueue.getJobs.mockResolvedValue([mockJob]);

      await service.cancelPendingDeliveryNotifications(mockOrderId);

      expect(mockJob.remove).toHaveBeenCalled();
    });
  });
});

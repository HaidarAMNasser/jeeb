import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { NotificationsService } from '../../../../src/modules/notifications/notifications.service';
import { CleanupService } from '../../../../src/common/services/cleanup.service';
import { WhatsappNotificationStrategy } from '../../../../src/modules/notifications/strategies/whatsapp-notification.strategy';
import { EmailNotificationStrategy } from '../../../../src/modules/notifications/strategies/email-notification.strategy';
import { FirebaseNotificationStrategy } from '../../../../src/modules/notifications/strategies/firebase-notification.strategy';
import { REDIS_CLIENT } from '../../../../src/common/redis/redis.constants';
import {
  NotificationLog,
  NotificationStatus,
} from '../../../../src/database/entities/notification-log.entity';
import {
  NotificationRecipient,
  RecipientStatus,
} from '../../../../src/database/entities/notification-recipient.entity';
import { User } from '../../../../src/database/entities/user.entity';
import { NotificationChannel } from '../../../../src/common/enums/notification-channel.enum';
import { NotificationType } from '../../../../src/common/enums/notification-type.enum';
import { NotificationTopic } from '../../../../src/common/enums/notification-topic.enum';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { Repository } from 'typeorm';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let notificationLogRepo: jest.Mocked<Repository<NotificationLog>>;
  let notificationRecipientRepo: jest.Mocked<Repository<NotificationRecipient>>;
  let userRepo: jest.Mocked<Repository<User>>;
  let whatsappStrategy: jest.Mocked<WhatsappNotificationStrategy>;
  let emailStrategy: jest.Mocked<EmailNotificationStrategy>;
  let firebaseStrategy: jest.Mocked<FirebaseNotificationStrategy>;
  let redis: jest.Mocked<any>;

  const mockUser: Partial<User> = {
    id: 1,
    email: 'user@test.com',
    phone: '+963900000001',
    firebaseToken: 'fcm-token',
    role: UserRole.CUSTOMER,
    notificationChannel: NotificationChannel.FIREBASE,
  };

  const mockNotificationLog: Partial<NotificationLog> = {
    id: 1,
    userId: 1,
    recipient: 'fcm-token',
    channel: NotificationChannel.FIREBASE,
    type: NotificationType.CUSTOM,
    title: 'Test Title',
    body: 'Test Body',
    status: NotificationStatus.PENDING,
    createdAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        {
          provide: getRepositoryToken(NotificationLog),
          useValue: {
            create: jest.fn(),
            save: jest.fn(),
            findOne: jest.fn(),
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(NotificationRecipient),
          useValue: {
            create: jest.fn(),
            save: jest.fn(),
            find: jest.fn(),
            findOne: jest.fn(),
            findAndCount: jest.fn(),
            update: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(User),
          useValue: {
            find: jest.fn(),
            findOne: jest.fn(),
          },
        },
        {
          provide: CleanupService,
          useValue: {
            cleanupOldRecords: jest.fn(),
          },
        },
        {
          provide: WhatsappNotificationStrategy,
          useValue: {
            sendOtp: jest.fn(),
            sendWelcomeMessage: jest.fn(),
          },
        },
        {
          provide: EmailNotificationStrategy,
          useValue: {
            sendOtp: jest.fn(),
            sendWelcomeMessage: jest.fn(),
            sendNotification: jest.fn(),
          },
        },
        {
          provide: FirebaseNotificationStrategy,
          useValue: {
            sendOtp: jest.fn(),
            sendWelcomeMessage: jest.fn(),
            sendNotification: jest.fn(),
            sendBatch: jest.fn(),
          },
        },
        {
          provide: REDIS_CLIENT,
          useValue: {
            set: jest.fn(),
            get: jest.fn(),
            del: jest.fn(),
            ttl: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<NotificationsService>(NotificationsService);
    notificationLogRepo = module.get(getRepositoryToken(NotificationLog));
    notificationRecipientRepo = module.get(
      getRepositoryToken(NotificationRecipient),
    );
    userRepo = module.get(getRepositoryToken(User));
    whatsappStrategy = module.get(WhatsappNotificationStrategy);
    emailStrategy = module.get(EmailNotificationStrategy);
    firebaseStrategy = module.get(FirebaseNotificationStrategy);
    redis = module.get(REDIS_CLIENT);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('sendOtp', () => {
    it('يرسل OTP عبر WhatsApp ويخزنه في Redis ويسجله في DB', async () => {
      notificationLogRepo.create.mockReturnValue(
        mockNotificationLog as NotificationLog,
      );
      notificationLogRepo.save.mockResolvedValue(
        mockNotificationLog as NotificationLog,
      );

      await service.sendOtp(
        '+963900000001',
        '123456',
        NotificationChannel.WHATSAPP,
        1,
      );

      expect(redis.set).toHaveBeenCalledWith(
        'otp:+963900000001',
        '123456',
        'EX',
        300,
      );
      expect(whatsappStrategy.sendOtp).toHaveBeenCalledWith(
        '+963900000001',
        '123456',
      );
      expect(notificationLogRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          recipient: '+963900000001',
          channel: NotificationChannel.WHATSAPP,
          type: NotificationType.OTP,
        }),
      );
    });

    it('يرمي خطأ إذا القناة غير مدعومة', async () => {
      await expect(
        service.sendOtp('to', '123456', 'INVALID' as NotificationChannel),
      ).rejects.toThrow('Notification channel INVALID not supported');
    });
  });

  describe('verifyOtp', () => {
    it('يعيد true لـ OTP صحيح ويستهلكه', async () => {
      redis.get.mockResolvedValue('123456');
      notificationLogRepo.findOne.mockResolvedValue({
        ...mockNotificationLog,
        isUsed: false,
      } as NotificationLog);

      const result = await service.verifyOtp('+963900000001', '123456');

      expect(result).toBe(true);
      expect(redis.del).toHaveBeenCalledWith('otp:+963900000001');
    });

    it('يعيد false لـ OTP خاطئ', async () => {
      redis.get.mockResolvedValue('654321');

      const result = await service.verifyOtp('+963900000001', '123456');

      expect(result).toBe(false);
      expect(redis.del).not.toHaveBeenCalled();
    });

    it('يعيد false إذا OTP غير موجود في Redis', async () => {
      redis.get.mockResolvedValue(null);

      const result = await service.verifyOtp('+963900000001', '123456');

      expect(result).toBe(false);
    });
  });

  describe('sendWelcomeMessage', () => {
    it('يرسل ترحيب عبر القناة المحددة ويسجله', async () => {
      notificationLogRepo.save.mockResolvedValue(
        mockNotificationLog as NotificationLog,
      );

      await service.sendWelcomeMessage(
        'to@test.com',
        'John',
        NotificationChannel.EMAIL,
      );

      expect(emailStrategy.sendWelcomeMessage).toHaveBeenCalledWith(
        'to@test.com',
        'John',
      );
      expect(notificationLogRepo.save).toHaveBeenCalledWith(
        expect.objectContaining({
          recipient: 'to@test.com',
          channel: NotificationChannel.EMAIL,
          type: NotificationType.WELCOME,
        }),
      );
    });
  });

  describe('sendOrderNotificationToDriver', () => {
    it('يرسل إشعار طلب للسائق عبر Firebase', async () => {
      await service.sendOrderNotificationToDriver(
        'driver-fcm',
        123,
        5000,
        'Pickup St',
      );

      expect(firebaseStrategy.sendNotification).toHaveBeenCalledWith(
        'driver-fcm',
        expect.stringContaining('طلب توصيل جديد'),
        expect.stringContaining('#123'),
        expect.objectContaining({
          type: 'NEW_DELIVERY',
          orderId: '123',
        }),
      );
    });
  });

  describe('sendToUser', () => {
    it('يرسل إشعار لمستخدم معين', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);
      notificationLogRepo.create.mockReturnValue(
        mockNotificationLog as NotificationLog,
      );
      notificationLogRepo.save.mockResolvedValue(
        mockNotificationLog as NotificationLog,
      );
      notificationRecipientRepo.save.mockResolvedValue({} as any);

      const result = await service.sendToUser(
        1,
        NotificationType.CUSTOM,
        'Title',
        'Body',
        NotificationChannel.FIREBASE,
      );

      expect(result).toHaveProperty('status', NotificationStatus.SENT);
      expect(firebaseStrategy.sendNotification).toHaveBeenCalled();
    });

    it('يرمي NotFoundException إذا المستخدم غير موجود', async () => {
      userRepo.findOne.mockResolvedValue(null);

      await expect(
        service.sendToUser(999, NotificationType.CUSTOM, 'Title', 'Body'),
      ).rejects.toThrow(NotFoundException);
    });

    it('يسجل فشل الإرسال إذا الـ Firebase فشل', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);
      notificationLogRepo.create.mockReturnValue(
        mockNotificationLog as NotificationLog,
      );
      notificationLogRepo.save.mockResolvedValue(
        mockNotificationLog as NotificationLog,
      );
      firebaseStrategy.sendNotification.mockRejectedValue(
        new Error('FCM error'),
      );

      const result = await service.sendToUser(
        1,
        NotificationType.CUSTOM,
        'Title',
        'Body',
        NotificationChannel.FIREBASE,
      );

      expect(result).toHaveProperty('status', NotificationStatus.FAILED);
      expect(result.metadata).toHaveProperty('error', 'FCM error');
    });
  });

  describe('sendToAll', () => {
    const customers = [
      { id: 1, firebaseToken: 'fcm-1' },
      { id: 2, firebaseToken: 'fcm-2' },
      { id: 3, firebaseToken: null },
    ] as User[];

    it('يرسل للكل ويعيد إحصائيات التوصيل', async () => {
      userRepo.find.mockResolvedValue(customers);
      notificationLogRepo.create.mockReturnValue(
        mockNotificationLog as NotificationLog,
      );
      notificationLogRepo.save.mockResolvedValue(
        mockNotificationLog as NotificationLog,
      );
      notificationRecipientRepo.save.mockResolvedValue([]);
      firebaseStrategy.sendBatch.mockResolvedValue([
        { success: true },
        { success: true },
      ]);

      const result = await service.sendToAll(
        NotificationTopic.ALL_CUSTOMERS,
        NotificationType.CUSTOM,
        'Title',
        'Body',
        NotificationChannel.FIREBASE,
      );

      expect(result).toEqual({
        notification: expect.objectContaining({
          status: NotificationStatus.SENT,
        }),
        totalTargeted: 3,
        deliveredCount: 2,
        undeliveredCount: 1,
      });
      expect(firebaseStrategy.sendBatch).toHaveBeenCalledTimes(1);
    });

    it('يرسل لكل المستخدمين إذا لم يُحدد topic', async () => {
      userRepo.find.mockResolvedValue(customers);
      notificationLogRepo.create.mockReturnValue(
        mockNotificationLog as NotificationLog,
      );
      notificationLogRepo.save.mockResolvedValue(
        mockNotificationLog as NotificationLog,
      );
      notificationRecipientRepo.save.mockResolvedValue([]);
      firebaseStrategy.sendBatch.mockResolvedValue([
        { success: true },
        { success: true },
      ]);

      await service.sendToAll(
        undefined,
        NotificationType.CUSTOM,
        'Title',
        'Body',
        NotificationChannel.FIREBASE,
      );

      expect(userRepo.find).toHaveBeenCalledWith(); // no where clause = all users
    });

    it('يحدد الدور الصحيح من topic', async () => {
      const drivers = [
        { id: 5, firebaseToken: 'fcm-5', role: UserRole.DELIVERY },
      ] as User[];
      userRepo.find.mockResolvedValue(drivers);
      notificationLogRepo.create.mockReturnValue(
        mockNotificationLog as NotificationLog,
      );
      notificationLogRepo.save.mockResolvedValue(
        mockNotificationLog as NotificationLog,
      );
      notificationRecipientRepo.save.mockResolvedValue([]);
      firebaseStrategy.sendBatch.mockResolvedValue([{ success: true }]);

      const result = await service.sendToAll(
        NotificationTopic.ALL_DRIVERS,
        NotificationType.CUSTOM,
        'Title',
        'Body',
        NotificationChannel.FIREBASE,
      );

      expect(userRepo.find).toHaveBeenCalledWith({
        where: { role: UserRole.DELIVERY },
      });
      expect(result.totalTargeted).toBe(1);
    });
  });

  describe('getNotificationsForUser', () => {
    it('يعيد إشعارات المستخدم مع pagination', async () => {
      const recipients = [
        {
          notification: {
            id: 1,
            type: NotificationType.CUSTOM,
            title: 'Title',
            body: 'Body',
            topic: null,
            channel: NotificationChannel.FIREBASE,
            status: NotificationStatus.SENT,
            createdAt: new Date(),
          },
          readAt: null,
        },
      ];
      notificationRecipientRepo.findAndCount.mockResolvedValue([
        recipients as any,
        1,
      ]);

      const result = await service.getNotificationsForUser(1, 1, 20);

      expect(result.data).toHaveLength(1);
      expect(result.total).toBe(1);
      expect(result.data[0]).toHaveProperty('title', 'Title');
    });
  });

  describe('getNotificationById', () => {
    it('يعيد إشعار محدد', async () => {
      const recipient = {
        notification: {
          id: 5,
          type: NotificationType.CUSTOM,
          title: 'Specific',
          body: 'Details',
          topic: null,
          channel: NotificationChannel.FIREBASE,
          status: NotificationStatus.SENT,
          createdAt: new Date(),
        },
        readAt: null,
      };
      notificationRecipientRepo.findOne.mockResolvedValue(recipient as any);

      const result = await service.getNotificationById(5, 1);

      expect(result).toHaveProperty('title', 'Specific');
    });

    it('يرمي NotFoundException إذا الإشعار غير موجود', async () => {
      notificationRecipientRepo.findOne.mockResolvedValue(null);

      await expect(service.getNotificationById(999, 1)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('markAsRead', () => {
    it('يحدّث الإشعارات كمقروءة', async () => {
      await service.markAsRead([1, 2, 3], 1);

      expect(notificationRecipientRepo.update).toHaveBeenCalledWith(
        { notificationId: { $in: [1, 2, 3] } as any, userId: 1 },
        { readAt: expect.any(Date), status: RecipientStatus.READ },
      );
    });
  });
});

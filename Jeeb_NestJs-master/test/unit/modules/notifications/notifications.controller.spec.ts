import { Test, TestingModule } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { NotificationsController } from '../../../../src/modules/notifications/notifications.controller';
import { NotificationsService } from '../../../../src/modules/notifications/notifications.service';
import { TokenService } from '../../../../src/modules/auth/token.service';
import { NotificationChannel } from '../../../../src/common/enums/notification-channel.enum';
import { NotificationType } from '../../../../src/common/enums/notification-type.enum';
import { NotificationTopic } from '../../../../src/common/enums/notification-topic.enum';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { User } from '../../../../src/database/entities/user.entity';

describe('NotificationsController', () => {
  let controller: NotificationsController;
  let notificationsService: jest.Mocked<NotificationsService>;

  const mockUser = {
    id: 1,
    email: 'test@test.com',
    role: UserRole.CUSTOMER,
  } as User;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [NotificationsController],
      providers: [
        {
          provide: NotificationsService,
          useValue: {
            sendToUser: jest.fn(),
            sendToAll: jest.fn(),
            getNotificationsForUser: jest.fn(),
            getNotificationById: jest.fn(),
            markAsRead: jest.fn(),
          },
        },
        {
          provide: JwtService,
          useValue: { signAsync: jest.fn(), decode: jest.fn() },
        },
        { provide: ConfigService, useValue: { get: jest.fn() } },
        { provide: TokenService, useValue: { isTokenRevoked: jest.fn() } },
        Reflector,
      ],
    }).compile();

    controller = module.get<NotificationsController>(NotificationsController);
    notificationsService = module.get(NotificationsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('sendToUser', () => {
    it('يرسل إشعار لمستخدم ويعيد success', async () => {
      notificationsService.sendToUser.mockResolvedValue({
        id: 1,
        channel: NotificationChannel.FIREBASE,
        type: NotificationType.CUSTOM,
        title: 'Test',
        body: 'Body',
        status: 'SENT',
      } as any);

      const result = await controller.sendToUser({
        userId: 1,
        type: NotificationType.CUSTOM,
        title: 'Test',
        body: 'Body',
      });

      expect(result).toHaveProperty('success', true);
      expect(result.data).toHaveProperty('id', 1);
    });
  });

  describe('sendToAll', () => {
    it('يرسل للكل ويعيد الإشعار', async () => {
      notificationsService.sendToAll.mockResolvedValue({
        notification: { id: 1, title: 'Test' },
        totalTargeted: 10,
        deliveredCount: 8,
        undeliveredCount: 2,
      } as any);

      const result = await controller.sendToAll({
        topic: NotificationTopic.ALL_CUSTOMERS,
        type: NotificationType.CUSTOM,
        title: 'Test',
        body: 'Body',
      });

      expect(result).toHaveProperty('success', true);
      expect(result.data).toHaveProperty('id', 1);
    });
  });

  describe('getNotifications', () => {
    it('يعيد إشعارات المستخدم', async () => {
      notificationsService.getNotificationsForUser.mockResolvedValue({
        data: [{ id: 1, title: 'Test' }],
        total: 1,
      });

      const result = await controller.getNotifications(mockUser, 1, 20);

      expect(result).toHaveProperty('success', true);
      expect(result.total).toBe(1);
    });
  });

  describe('getNotification', () => {
    it('يعيد إشعار محدد', async () => {
      notificationsService.getNotificationById.mockResolvedValue({
        id: 5,
        title: 'Specific',
      });

      const result = await controller.getNotification(5, mockUser);

      expect(result).toHaveProperty('success', true);
      expect(result.data).toHaveProperty('title', 'Specific');
    });
  });

  describe('markAsRead', () => {
    it('يحدد إشعارات كمقروءة', async () => {
      const result = await controller.markAsRead(
        { notificationIds: [1, 2, 3] },
        mockUser,
      );

      expect(result).toHaveProperty('message', 'Notifications marked as read');
      expect(notificationsService.markAsRead).toHaveBeenCalledWith(
        [1, 2, 3],
        1,
      );
    });
  });

  describe('sendToCustomers', () => {
    it('يرسل للكل ويعيد إحصائيات التوصيل', async () => {
      notificationsService.sendToAll.mockResolvedValue({
        notification: {
          id: 1,
          channel: NotificationChannel.FIREBASE,
          type: NotificationType.CUSTOM,
          title: 'Title',
          body: 'Body',
          topic: NotificationTopic.ALL_CUSTOMERS,
          sentAt: new Date(),
          createdAt: new Date(),
        },
        totalTargeted: 50,
        deliveredCount: 40,
        undeliveredCount: 10,
      } as any);

      const result = await controller.sendToCustomers({
        title: 'Title',
        body: 'Body',
      });

      expect(result).toHaveProperty('success', true);
      expect(result.data).toHaveProperty('totalTargeted', 50);
      expect(result.data).toHaveProperty('deliveredCount', 40);
      expect(result.data).toHaveProperty('undeliveredCount', 10);
      expect(notificationsService.sendToAll).toHaveBeenCalledWith(
        NotificationTopic.ALL_CUSTOMERS,
        NotificationType.CUSTOM,
        'Title',
        'Body',
        NotificationChannel.FIREBASE,
      );
    });
  });
});

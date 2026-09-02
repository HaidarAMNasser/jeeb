import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { SecurityNotificationService } from '../../../../src/modules/notifications/security-notification.service';
import { NotificationsService } from '../../../../src/modules/notifications/notifications.service';
import { GeoLocationService } from '../../../../src/modules/notifications/geo-location.service';
import { User } from '../../../../src/database/entities/user.entity';
import { Repository } from 'typeorm';

describe('SecurityNotificationService', () => {
  let service: SecurityNotificationService;
  let notificationsService: jest.Mocked<NotificationsService>;
  let geoLocationService: jest.Mocked<GeoLocationService>;
  let userRepo: jest.Mocked<Repository<User>>;

  const mockUser: Partial<User> = {
    id: 1,
    email: 'user@test.com',
    notificationChannel: 'FIREBASE' as any,
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SecurityNotificationService,
        {
          provide: NotificationsService,
          useValue: {
            sendToUser: jest.fn(),
          },
        },
        {
          provide: GeoLocationService,
          useValue: {
            getLocationFromIp: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(User),
          useValue: {
            findOne: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<SecurityNotificationService>(
      SecurityNotificationService,
    );
    notificationsService = module.get(NotificationsService);
    geoLocationService = module.get(GeoLocationService);
    userRepo = module.get(getRepositoryToken(User));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('sendFailedAttemptsWarning', () => {
    it('يرسل تحذير عند فشل تسجيل الدخول', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);

      await service.sendFailedAttemptsWarning(1, 'user@test.com', 3);

      expect(notificationsService.sendToUser).toHaveBeenCalledWith(
        1,
        expect.any(String),
        expect.stringContaining('تنبيه'),
        expect.stringContaining('3/5'),
        'FIREBASE',
        expect.objectContaining({
          type: 'security_alert',
          action: 'failed_login_attempts',
          attempts: '3',
        }),
      );
    });

    it('يتخطى إذا المستخدم غير موجود', async () => {
      userRepo.findOne.mockResolvedValue(null);

      await service.sendFailedAttemptsWarning(999, 'unknown@test.com', 3);

      expect(notificationsService.sendToUser).not.toHaveBeenCalled();
    });
  });

  describe('sendAccountLockedNotification', () => {
    it('يرسل إشعار قفل مؤقت', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);

      await service.sendAccountLockedNotification(
        1,
        'user@test.com',
        3,
        '2 hours',
      );

      expect(notificationsService.sendToUser).toHaveBeenCalledWith(
        1,
        expect.any(String),
        expect.stringContaining('مقفل'),
        expect.stringContaining('2 hours'),
        'FIREBASE',
        expect.objectContaining({ blockLevel: '3' }),
      );
    });

    it('يرسل إشعار حظر نهائي عند blockLevel = 5', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);

      await service.sendAccountLockedNotification(
        1,
        'user@test.com',
        5,
        'Permanent',
      );

      expect(notificationsService.sendToUser).toHaveBeenCalledWith(
        1,
        expect.any(String),
        expect.stringContaining('محظور'),
        expect.stringContaining('نهائياً'),
        'FIREBASE',
        expect.objectContaining({ blockLevel: '5' }),
      );
    });
  });

  describe('sendAccountUnlockedNotification', () => {
    it('يرسل إشعار فتح الحساب', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);

      await service.sendAccountUnlockedNotification(1);

      expect(notificationsService.sendToUser).toHaveBeenCalledWith(
        1,
        expect.any(String),
        expect.stringContaining('مفتح'),
        expect.stringContaining('إعادة تفعيل'),
        'FIREBASE',
        expect.objectContaining({ action: 'account_unlocked' }),
      );
    });
  });

  describe('sendNewDeviceLoginNotification', () => {
    it('يرسل إشعار تسجيل دخول من جهاز جديد مع الموقع', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);
      geoLocationService.getLocationFromIp.mockResolvedValue('دمشق، سوريا');

      await service.sendNewDeviceLoginNotification(1, '1.2.3.4');

      expect(notificationsService.sendToUser).toHaveBeenCalledWith(
        1,
        expect.any(String),
        expect.stringContaining('تسجيل دخول جديد'),
        expect.stringContaining('دمشق، سوريا'),
        'FIREBASE',
        expect.objectContaining({ ip: '1.2.3.4', location: 'دمشق، سوريا' }),
      );
    });

    it('يعرض الـ IP fallback إذا فشل تحديد الموقع', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);
      geoLocationService.getLocationFromIp.mockResolvedValue('1.2.3.4');

      await service.sendNewDeviceLoginNotification(1, '1.2.3.4');

      expect(notificationsService.sendToUser).toHaveBeenCalledWith(
        1,
        expect.any(String),
        expect.stringContaining('تسجيل دخول جديد'),
        expect.stringContaining('1.2.3.4'),
        'FIREBASE',
        expect.objectContaining({ ip: '1.2.3.4', location: '1.2.3.4' }),
      );
    });
  });
});

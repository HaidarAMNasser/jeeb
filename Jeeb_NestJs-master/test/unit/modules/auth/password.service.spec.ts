import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { PasswordService } from '../../../../src/modules/auth/services/password.service';
import { UsersService } from '../../../../src/modules/users/users.service';
import { NotificationsService } from '../../../../src/modules/notifications/notifications.service';
import { REDIS_CLIENT } from '../../../../src/common/redis/redis.constants';
import { User } from '../../../../src/database/entities/user.entity';

jest.mock('bcrypt', () => ({
  hash: jest.fn().mockResolvedValue('new_hashed_password'),
}));

describe('PasswordService', () => {
  let service: PasswordService;
  let usersService: jest.Mocked<UsersService>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let redis: jest.Mocked<any>;

  const mockUser: Partial<User> = {
    id: 1,
    email: 'user@test.com',
    notificationChannel: 'EMAIL',
  };

  const mockPhoneUser: Partial<User> = {
    id: 2,
    email: null,
    phone: '+963900000001',
    notificationChannel: 'WHATSAPP',
  };

  beforeEach(async () => {
    const redisMock = {
      ttl: jest.fn(),
      set: jest.fn(),
      get: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PasswordService,
        {
          provide: UsersService,
          useValue: {
            findOneByEmail: jest.fn(),
            findOneByPhone: jest.fn(),
            update: jest.fn(),
          },
        },
        {
          provide: NotificationsService,
          useValue: {
            sendOtp: jest.fn(),
            verifyOtp: jest.fn(),
          },
        },
        {
          provide: REDIS_CLIENT,
          useValue: redisMock,
        },
      ],
    }).compile();

    service = module.get<PasswordService>(PasswordService);
    usersService = module.get(UsersService);
    notificationsService = module.get(NotificationsService);
    redis = module.get(REDIS_CLIENT);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('forgotPassword', () => {
    it('يرسل OTP للبريد', async () => {
      usersService.findOneByEmail.mockResolvedValue(mockUser as User);

      const result = await service.forgotPassword({ email: 'user@test.com' });

      expect(result).toEqual({
        message: 'OTP sent successfully to your email.',
        data: { message: 'OTP sent successfully to your email.' },
      });
      expect(notificationsService.sendOtp).toHaveBeenCalledWith(
        'user@test.com',
        expect.any(String),
        'EMAIL',
        1,
      );
    });

    it('يرسل OTP عبر WhatsApp عند استخدام رقم هاتف', async () => {
      usersService.findOneByEmail.mockResolvedValue(null);
      usersService.findOneByPhone.mockResolvedValue({
        ...mockPhoneUser,
        verifiedAt: null,
      } as User);

      const result = await service.forgotPassword({
        phone: '+963900000001',
      });

      expect(result).toEqual({
        message: 'OTP sent successfully to your phone.',
        data: { message: 'OTP sent successfully to your phone.' },
      });
      expect(notificationsService.sendOtp).toHaveBeenCalledWith(
        '+963900000001',
        expect.any(String),
        'WHATSAPP',
        2,
      );
    });

    it('يرفض بريد غير موجود', async () => {
      usersService.findOneByEmail.mockResolvedValue(null);

      await expect(
        service.forgotPassword({ email: 'unknown@test.com' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('يرفض هاتف غير موجود', async () => {
      usersService.findOneByEmail.mockResolvedValue(null);
      usersService.findOneByPhone.mockResolvedValue(null);

      await expect(
        service.forgotPassword({ phone: '+963999999999' }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('resendOtp', () => {
    it('يعيد إرسال OTP', async () => {
      usersService.findOneByEmail.mockResolvedValue({
        ...mockUser,
        verifiedAt: null,
      } as User);
      redis.ttl.mockResolvedValue(-2);

      const result = await service.resendOtp('user@test.com');

      expect(result).toEqual({
        message: 'OTP resent successfully to your email.',
        data: { message: 'OTP resent successfully to your email.' },
      });
      expect(redis.set).toHaveBeenCalledWith(
        'cooldown:otp:user@test.com',
        '1',
        'EX',
        60,
      );
    });

    it('يرفض بريد غير موجود', async () => {
      usersService.findOneByEmail.mockResolvedValue(null);

      await expect(service.resendOtp('unknown@test.com')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('يرفض إعادة الإرسال أثناء فترة الانتظار (cooldown)', async () => {
      usersService.findOneByEmail.mockResolvedValue({
        ...mockUser,
        verifiedAt: null,
      } as User);
      redis.ttl.mockResolvedValue(30);

      await expect(service.resendOtp('user@test.com')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('يعيد إرسال OTP عبر WhatsApp عند استخدام رقم هاتف', async () => {
      usersService.findOneByEmail.mockResolvedValue(null);
      usersService.findOneByPhone.mockResolvedValue({
        ...mockPhoneUser,
        verifiedAt: null,
      } as User);
      redis.ttl.mockResolvedValue(-2);

      const result = await service.resendOtp('+963900000001');

      expect(result).toEqual({
        message: 'OTP resent successfully to your phone.',
        data: { message: 'OTP resent successfully to your phone.' },
      });
      expect(notificationsService.sendOtp).toHaveBeenCalledWith(
        '+963900000001',
        expect.any(String),
        'WHATSAPP',
        2,
      );
    });

    it('يرفض رقم هاتف غير موجود', async () => {
      usersService.findOneByEmail.mockResolvedValue(null);
      usersService.findOneByPhone.mockResolvedValue(null);

      await expect(
        service.resendOtp('+963999999999'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('resetPassword', () => {
    it('يعيد تعيين كلمة المرور بنجاح', async () => {
      usersService.findOneByEmail.mockResolvedValue(mockUser as User);
      notificationsService.verifyOtp.mockResolvedValue(true);

      const result = await service.resetPassword({
        email: 'user@test.com',
        otp: '123456',
        password: 'newPass123',
      });

      expect(result).toEqual({
        message: 'Password reset successfully. You can now login.',
        data: { message: 'Password reset successfully. You can now login.' },
      });
      expect(usersService.update).toHaveBeenCalledWith(1, {
        password: 'new_hashed_password',
      });
    });

    it('يرفض مستخدم غير موجود', async () => {
      usersService.findOneByEmail.mockResolvedValue(null);

      await expect(
        service.resetPassword({
          email: 'unknown@test.com',
          otp: '123456',
          password: 'newPass123',
        }),
      ).rejects.toThrow(NotFoundException);
    });

    it('يرفض OTP غير صالح', async () => {
      usersService.findOneByEmail.mockResolvedValue(mockUser as User);
      notificationsService.verifyOtp.mockResolvedValue(false);

      await expect(
        service.resetPassword({
          email: 'user@test.com',
          otp: 'wrong',
          password: 'newPass123',
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});

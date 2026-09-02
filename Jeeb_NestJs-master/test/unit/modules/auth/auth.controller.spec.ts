import { Test, TestingModule } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthController } from '../../../../src/modules/auth/auth.controller';
import { AuthService } from '../../../../src/modules/auth/auth.service';
import { TokenService } from '../../../../src/modules/auth/token.service';
import { OtpAttemptService } from '../../../../src/common/services/otp-attempt.service';
import { OtpBruteForceGuard } from '../../../../src/common/guards/otp-brute-force.guard';
import { OtpAttemptInterceptor } from '../../../../src/common/interceptors/otp-attempt.interceptor';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { User } from '../../../../src/database/entities/user.entity';
import { CustomerInitDto } from '../../../../src/modules/auth/dto/customer-init.dto';
import { CustomerCompleteRegistrationDto } from '../../../../src/modules/auth/dto/customer-complete-registration.dto';

describe('AuthController', () => {
  let controller: AuthController;
  let authService: jest.Mocked<AuthService>;

  const mockUser = {
    id: 1,
    email: 'test@test.com',
    role: UserRole.CUSTOMER,
  } as User;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        {
          provide: AuthService,
          useValue: {
            register: jest.fn(),
            verifyAccount: jest.fn(),
            login: jest.fn(),
            loginGuest: jest.fn(),
            forgotPassword: jest.fn(),
            resendOtp: jest.fn(),
            resetPassword: jest.fn(),
            logout: jest.fn(),
            getProfile: jest.fn(),
            updateProfile: jest.fn(),
            deleteProfile: jest.fn(),
            updateFirebaseToken: jest.fn(),
            customerInit: jest.fn(),
            customerVerifyPhone: jest.fn(),
            customerCompleteRegistration: jest.fn(),
          },
        },
        {
          provide: JwtService,
          useValue: { signAsync: jest.fn(), decode: jest.fn() },
        },
        { provide: ConfigService, useValue: { get: jest.fn() } },
        { provide: TokenService, useValue: { isTokenRevoked: jest.fn() } },
        {
          provide: OtpAttemptService,
          useValue: {
            recordFailedAttempt: jest.fn(),
            recordSuccessfulAttempt: jest.fn(),
            isBlocked: jest.fn(),
            getBlockInfo: jest.fn(),
          },
        },
        OtpBruteForceGuard,
        OtpAttemptInterceptor,
        Reflector,
      ],
    }).compile();

    controller = module.get<AuthController>(AuthController);
    authService = module.get(AuthService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('verify (POST /verify-account)', () => {
    it('يعيد 200 للـ CUSTOMER عبر email', async () => {
      const res = { status: jest.fn().mockReturnThis() };
      authService.verifyAccount.mockResolvedValue({
        message: 'Account verified successfully.',
        data: {
          message: 'Account verified successfully.',
          access_token: 'jwt',
          user: { id: 1, email: 'test@test.com', role: 'CUSTOMER' },
        },
      });

      const result = await controller.verify(
        { email: 'test@test.com', otp: '123456' },
        res as any,
      );

      expect(authService.verifyAccount).toHaveBeenCalledWith(
        'test@test.com',
        '123456',
      );
      expect(result).toHaveProperty('message');
      expect(result.data).toHaveProperty('access_token');
      expect(res.status).toHaveBeenCalledWith(200);
    });

    it('يعيد 200 للـ CUSTOMER عبر phone', async () => {
      const res = { status: jest.fn().mockReturnThis() };
      authService.verifyAccount.mockResolvedValue({
        message: 'Account verified successfully.',
        data: {
          message: 'Account verified successfully.',
          access_token: 'jwt',
          user: { id: 1, phone: '+963900000001', role: 'CUSTOMER' },
        },
      });

      const result = await controller.verify(
        { phone: '+963900000001', otp: '123456' },
        res as any,
      );

      expect(authService.verifyAccount).toHaveBeenCalledWith(
        '+963900000001',
        '123456',
      );
      expect(result).toHaveProperty('message');
      expect(result.data).toHaveProperty('access_token');
      expect(res.status).toHaveBeenCalledWith(200);
    });

    it('يعيد statusCode 202 للـ MERCHANT', async () => {
      const res = { status: jest.fn().mockReturnThis() };
      authService.verifyAccount.mockResolvedValue({
        statusCode: 202,
        message: 'تم التحقق من حسابك',
        data: { message: 'تم التحقق', userId: 2, isActive: false },
      });

      const result = await controller.verify(
        { email: 'merchant@test.com', otp: '123456' },
        res as any,
      );

      expect(res.status).toHaveBeenCalledWith(202);
      expect(result.data).toHaveProperty('isActive', false);
      expect(result.data).not.toHaveProperty('access_token');
    });
  });

  describe('login (POST /login)', () => {
    it('يعيد توكن عند نجاح تسجيل الدخول', async () => {
      authService.login.mockResolvedValue({
        access_token: 'jwt-token',
        user: { id: 1, email: 'test@test.com', role: UserRole.CUSTOMER },
      });

      const result = await controller.login(
        { email: 'test@test.com', password: 'password123' },
        { headers: { 'x-forwarded-for': '127.0.0.1' }, ip: '127.0.0.1' } as any,
      );

      expect(result).toHaveProperty('access_token', 'jwt-token');
      expect(authService.login).toHaveBeenCalled();
    });
  });

  describe('logout (POST /logout)', () => {
    it('يلغي التوكن ويعيد رسالة', async () => {
      authService.logout.mockResolvedValue({
        message: 'Logged out successfully',
      });

      const result = await controller.logout(mockUser, 'Bearer token123');

      expect(result).toEqual({ message: 'Logged out successfully' });
      expect(authService.logout).toHaveBeenCalledWith(mockUser, 'token123');
    });
  });

  describe('getProfile (GET /profile)', () => {
    it('يعيد بروفايل المستخدم', async () => {
      const profile = { id: 1, email: 'test@test.com', firstName: 'John' };
      authService.getProfile.mockResolvedValue(profile);

      const result = await controller.getProfile(mockUser);

      expect(result).toEqual(profile);
    });
  });

  describe('deleteProfile (DELETE /profile)', () => {
    it('يحذف الحساب ويعيد رسالة', async () => {
      authService.deleteProfile.mockResolvedValue({
        message: 'Account deleted successfully',
      });

      const result = await controller.deleteProfile(mockUser);

      expect(result).toEqual({ message: 'Account deleted successfully' });
    });
  });

  describe('updateFirebaseToken (POST /firebase-token)', () => {
    it('يحدث التوكن', async () => {
      authService.updateFirebaseToken.mockResolvedValue({
        message: 'Firebase token updated successfully',
        fcmTokenUpdated: true,
      });

      const result = await controller.updateFirebaseToken(
        { token: 'new-fcm-token' },
        mockUser,
      );

      expect(result).toEqual({
        success: true,
        message: 'Firebase token updated successfully',
        fcmTokenUpdated: true,
      });
    });

    it('يرمي BadRequest إذا لم يتم تقديم token أو firebaseToken', async () => {
      await expect(
        controller.updateFirebaseToken({} as any, mockUser),
      ).rejects.toThrow();
    });
  });

  describe('customerInit (POST /register/customer/init)', () => {
    it('يرسل OTP للهاتف', async () => {
      const mockResult = { message: 'OTP sent successfully to your phone.' };
      authService.customerInit.mockResolvedValue(mockResult);

      const dto: CustomerInitDto = { phone: '+963912345678' };
      const result = await controller.customerInit(dto);

      expect(authService.customerInit).toHaveBeenCalledWith(dto);
      expect(result).toEqual(mockResult);
    });
  });

  describe('customerVerifyPhone (POST /register/customer/verify-phone)', () => {
    it('يتحقق من OTP ويعيد رسالة', async () => {
      const mockResult = {
        message:
          'Phone verified successfully. Please complete your registration.',
      };
      authService.customerVerifyPhone.mockResolvedValue(mockResult);

      const result = await controller.customerVerifyPhone({
        phone: '+963912345678',
        otp: '123456',
      });

      expect(authService.customerVerifyPhone).toHaveBeenCalledWith(
        '+963912345678',
        '123456',
      );
      expect(result).toEqual(mockResult);
    });

    it('يرمي BadRequest إذا لم يتم تقديم phone', async () => {
      await expect(
        controller.customerVerifyPhone({
          email: 'test@test.com',
          otp: '123456',
        } as any),
      ).rejects.toThrow();
    });
  });

  describe('customerCompleteRegistration (POST /register/customer)', () => {
    it('يكمل بيانات العميل ويعيد النتيجة', async () => {
      const mockResult = {
        message: 'Profile updated successfully.',
        data: {
          message: 'Profile updated successfully.',
          user: {
            id: 1,
            email: 'customer@test.com',
            role: 'CUSTOMER',
            isVerified: true,
          },
        },
      };
      authService.customerCompleteRegistration.mockResolvedValue(mockResult);

      const dto: CustomerCompleteRegistrationDto = {
        email: 'customer@test.com',
      };

      const result = await controller.customerCompleteRegistration(dto, null, mockUser);

      expect(authService.customerCompleteRegistration).toHaveBeenCalledWith(
        mockUser.id,
        dto,
        [],
      );
      expect(result).toEqual(mockResult);
    });
  });
});

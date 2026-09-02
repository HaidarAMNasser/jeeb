import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from '../../../../src/modules/auth/auth.service';
import { RegistrationService } from '../../../../src/modules/auth/services/registration.service';
import { LoginService } from '../../../../src/modules/auth/services/login.service';
import { PasswordService } from '../../../../src/modules/auth/services/password.service';
import { ProfileService } from '../../../../src/modules/auth/services/profile.service';
import { CustomerRegistrationFlowService } from '../../../../src/modules/auth/services/customer-registration-flow.service';
import { TokenService } from '../../../../src/modules/auth/token.service';
import { FirebaseService } from '../../../../src/modules/firebase/firebase.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { User } from '../../../../src/database/entities/user.entity';

describe('AuthService', () => {
  let service: AuthService;
  let registrationService: jest.Mocked<RegistrationService>;
  let loginService: jest.Mocked<LoginService>;
  let passwordService: jest.Mocked<PasswordService>;
  let profileService: jest.Mocked<ProfileService>;
  let tokenService: jest.Mocked<TokenService>;
  let firebaseService: jest.Mocked<FirebaseService>;

  const mockUser = {
    id: 1,
    email: 'test@test.com',
    role: UserRole.CUSTOMER,
  } as User;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: RegistrationService,
          useValue: {
            register: jest.fn(),
            createAdminOrMerchant: jest.fn(),
            verifyAccount: jest.fn(),
          },
        },
        {
          provide: LoginService,
          useValue: {
            login: jest.fn(),
            handleGuestLogin: jest.fn(),
            updateFirebaseToken: jest.fn(),
          },
        },
        {
          provide: PasswordService,
          useValue: {
            forgotPassword: jest.fn(),
            resendOtp: jest.fn(),
            resetPassword: jest.fn(),
          },
        },
        {
          provide: ProfileService,
          useValue: {
            getProfile: jest.fn(),
            updateProfile: jest.fn(),
            deleteProfile: jest.fn(),
          },
        },
        {
          provide: CustomerRegistrationFlowService,
          useValue: {
            init: jest.fn(),
            verifyPhone: jest.fn(),
            completeRegistration: jest.fn(),
          },
        },
        {
          provide: TokenService,
          useValue: {
            generateAccessToken: jest.fn(),
            revokeToken: jest.fn(),
          },
        },
        {
          provide: FirebaseService,
          useValue: {
            createCustomTokenForDelivery: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    registrationService = module.get(RegistrationService);
    loginService = module.get(LoginService);
    passwordService = module.get(PasswordService);
    profileService = module.get(ProfileService);
    tokenService = module.get(TokenService);
    firebaseService = module.get(FirebaseService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('register', () => {
    it('يفوض إلى RegistrationService.register', async () => {
      const dto = {} as any;
      const expected = { message: 'registered' };
      registrationService.register.mockResolvedValue(expected);

      const result = await service.register(dto, []);

      expect(result).toBe(expected);
      expect(registrationService.register).toHaveBeenCalledWith(dto, []);
    });
  });

  describe('verifyAccount', () => {
    it('يفوض إلى RegistrationService.verifyAccount باستخدام email', async () => {
      const expected = { message: 'verified' };
      registrationService.verifyAccount.mockResolvedValue(expected);

      const result = await service.verifyAccount('email@test.com', '123456');

      expect(result).toBe(expected);
      expect(registrationService.verifyAccount).toHaveBeenCalledWith(
        'email@test.com',
        '123456',
      );
    });

    it('يفوض إلى RegistrationService.verifyAccount باستخدام phone', async () => {
      const expected = { message: 'verified' };
      registrationService.verifyAccount.mockResolvedValue(expected);

      const result = await service.verifyAccount(
        '+963900000001',
        '123456',
      );

      expect(result).toBe(expected);
      expect(registrationService.verifyAccount).toHaveBeenCalledWith(
        '+963900000001',
        '123456',
      );
    });
  });

  describe('login', () => {
    it('يفوض إلى LoginService.login', async () => {
      const dto = {} as any;
      const expected = { access_token: 'token' };
      loginService.login.mockResolvedValue(expected);

      const result = await service.login(dto, '127.0.0.1');

      expect(result).toBe(expected);
      expect(loginService.login).toHaveBeenCalledWith(dto, '127.0.0.1');
    });
  });

  describe('loginGuest', () => {
    it('يفوض إلى LoginService.handleGuestLogin', async () => {
      const expected = { access_token: 'guest-token' };
      loginService.handleGuestLogin.mockResolvedValue(expected);

      const result = await service.loginGuest(
        { firebaseToken: 'fcm-token' },
        '127.0.0.1',
      );

      expect(result).toBe(expected);
      expect(loginService.handleGuestLogin).toHaveBeenCalledWith(
        'fcm-token',
        '127.0.0.1',
      );
    });
  });

  describe('forgotPassword', () => {
    it('يفوض إلى PasswordService.forgotPassword', async () => {
      const dto = { email: 'test@test.com' };
      const expected = { message: 'OTP sent' };
      passwordService.forgotPassword.mockResolvedValue(expected);

      const result = await service.forgotPassword(dto);

      expect(result).toBe(expected);
    });
  });

  describe('resendOtp', () => {
    it('يفوض إلى PasswordService.resendOtp', async () => {
      const expected = { message: 'resent' };
      passwordService.resendOtp.mockResolvedValue(expected);

      const result = await service.resendOtp('test@test.com');

      expect(result).toBe(expected);
    });
  });

  describe('resetPassword', () => {
    it('يفوض إلى PasswordService.resetPassword', async () => {
      const dto = {} as any;
      const expected = { message: 'reset' };
      passwordService.resetPassword.mockResolvedValue(expected);

      const result = await service.resetPassword(dto);

      expect(result).toBe(expected);
    });
  });

  describe('logout', () => {
    it('يلغي التوكن ويعيد رسالة', async () => {
      const result = await service.logout(mockUser, 'bearer-token');

      expect(result).toEqual({ message: 'Logged out successfully' });
      expect(tokenService.revokeToken).toHaveBeenCalledWith('bearer-token');
    });
  });

  describe('getProfile', () => {
    it('يفوض إلى ProfileService.getProfile', async () => {
      const expected = { id: 1, email: 'test@test.com' };
      profileService.getProfile.mockResolvedValue(expected);

      const result = await service.getProfile(mockUser);

      expect(result).toBe(expected);
    });
  });

  describe('updateProfile', () => {
    it('يفوض إلى ProfileService.updateProfile', async () => {
      const dto = {} as any;
      const expected = { id: 1, firstName: 'Updated' };
      profileService.updateProfile.mockResolvedValue(expected);

      const result = await service.updateProfile(mockUser, dto, []);

      expect(result).toBe(expected);
    });
  });

  describe('deleteProfile', () => {
    it('يفوض إلى ProfileService.deleteProfile', async () => {
      const expected = { message: 'deleted' };
      profileService.deleteProfile.mockResolvedValue(expected);

      const result = await service.deleteProfile(mockUser);

      expect(result).toBe(expected);
    });
  });

  describe('updateFirebaseToken', () => {
    it('يحدث توكن Firebase لـ CUSTOMER', async () => {
      const customerUser = { id: 1, role: UserRole.CUSTOMER } as User;
      loginService.updateFirebaseToken.mockResolvedValue(customerUser);

      const result = await service.updateFirebaseToken(
        customerUser,
        'fcm-token',
      );

      expect(result).toHaveProperty('fcmTokenUpdated', true);
      expect(result).not.toHaveProperty('customToken');
    });

    it('يولد CustomToken لـ DELIVERY', async () => {
      const deliveryUser = { id: 5, role: UserRole.DELIVERY } as User;
      loginService.updateFirebaseToken.mockResolvedValue(deliveryUser);
      firebaseService.createCustomTokenForDelivery.mockResolvedValue({
        uid: 'delivery_5',
        customToken: 'firebase-custom-token',
      });

      const result = await service.updateFirebaseToken(
        deliveryUser,
        'fcm-token',
      );

      expect(result).toHaveProperty('firebaseUid', 'delivery_5');
      expect(result).toHaveProperty('customToken', 'firebase-custom-token');
    });
  });
});

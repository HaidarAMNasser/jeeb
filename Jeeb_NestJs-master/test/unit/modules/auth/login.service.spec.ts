import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import {
  UnauthorizedException,
  ForbiddenException,
  HttpException,
} from '@nestjs/common';
import { LoginService } from '../../../../src/modules/auth/services/login.service';
import { UsersService } from '../../../../src/modules/users/users.service';
import { TokenService } from '../../../../src/modules/auth/token.service';
import { LoginAttemptService } from '../../../../src/common/services/login-attempt.service';
import { IPBlockService } from '../../../../src/common/services/ip-block.service';
import { SecurityNotificationService } from '../../../../src/modules/notifications/security-notification.service';
import { MerchantsService } from '../../../../src/modules/merchants/merchants.service';
import { ImageProcessingService } from '../../../../src/common/image-processing/image-processing.service';
import { StorageService } from '../../../../src/common/storage/storage.service';
import { FirebaseService } from '../../../../src/modules/firebase/firebase.service';
import { User } from '../../../../src/database/entities/user.entity';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { Repository } from 'typeorm';
import { LoginDto } from '../../../../src/modules/auth/dto/login.dto';

jest.mock('bcrypt', () => ({
  hash: jest.fn().mockResolvedValue('hashed_password'),
  compare: jest.fn(),
}));

describe('LoginService', () => {
  let service: LoginService;
  let usersService: jest.Mocked<UsersService>;
  let tokenService: jest.Mocked<TokenService>;
  let loginAttemptService: jest.Mocked<LoginAttemptService>;
  let ipBlockService: jest.Mocked<IPBlockService>;
  let merchantsService: jest.Mocked<MerchantsService>;
  let storageService: jest.Mocked<StorageService>;
  let userRepository: jest.Mocked<Repository<User>>;

  const mockCustomerUser: Partial<User> = {
    id: 1,
    email: 'customer@test.com',
    password: 'hashed_password',
    firstName: 'John',
    lastName: 'Doe',
    role: UserRole.CUSTOMER,
    isActive: true,
    verifiedAt: new Date(),
    notificationChannel: 'EMAIL',
    images: [],
  };

  const mockMerchantUser: Partial<User> = {
    id: 2,
    email: 'merchant@test.com',
    password: 'hashed_password',
    firstName: 'Merchant',
    lastName: 'User',
    role: UserRole.MERCHANT,
    isActive: false,
    verifiedAt: new Date(),
    notificationChannel: 'EMAIL',
    images: [],
  };

  const mockLoginDto: LoginDto = {
    email: 'customer@test.com',
    password: 'password123',
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LoginService,
        {
          provide: UsersService,
          useValue: {
            findOneByEmailWithPassword: jest.fn(),
            findOneByPhoneWithPassword: jest.fn(),
            findOneByEmail: jest.fn(),
            findOneById: jest.fn(),
            updateFirebaseToken: jest.fn(),
          },
        },
        {
          provide: TokenService,
          useValue: {
            generateAccessToken: jest.fn(),
          },
        },
        {
          provide: LoginAttemptService,
          useValue: {
            hasActiveBlock: jest.fn(),
            resetAttempts: jest.fn(),
            resetIPAttempts: jest.fn(),
            recordFailedAttempt: jest.fn(),
            isIPBlocked: jest.fn(),
            getIPAttempts: jest.fn(),
            createBlock: jest.fn(),
            unblockByEmail: jest.fn(),
            getDurationText: jest.fn(),
          },
        },
        {
          provide: IPBlockService,
          useValue: {
            checkAndBlock: jest.fn(),
          },
        },
        {
          provide: SecurityNotificationService,
          useValue: {
            sendNewDeviceLoginNotification: jest.fn(),
            sendAccountLockedNotification: jest.fn(),
            sendFailedAttemptsWarning: jest.fn(),
          },
        },
        {
          provide: MerchantsService,
          useValue: {
            findByUserId: jest.fn(),
            updateMerchant: jest.fn(),
          },
        },
        {
          provide: ImageProcessingService,
          useValue: {
            processAndUpload: jest.fn(),
            deleteImages: jest.fn(),
          },
        },
        {
          provide: StorageService,
          useValue: {
            resolveUrl: jest.fn(),
            generatePublicUrl: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(User),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
            create: jest.fn(),
          },
        },
        {
          provide: FirebaseService,
          useValue: {
            verifyIdToken: jest.fn(),
            createDriverDocument: jest.fn(),
            createCustomTokenForDelivery: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<LoginService>(LoginService);
    usersService = module.get(UsersService);
    tokenService = module.get(TokenService);
    loginAttemptService = module.get(LoginAttemptService);
    merchantsService = module.get(MerchantsService);
    storageService = module.get(StorageService);
    userRepository = module.get(getRepositoryToken(User));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('login', () => {
    const { compare: bcryptCompare } = jest.requireMock('bcrypt');

    it('يسجل دخول CUSTOMER بالبريد ويعيد توكن', async () => {
      usersService.findOneByEmailWithPassword.mockResolvedValue(
        mockCustomerUser as User,
      );
      bcryptCompare.mockResolvedValue(true);
      tokenService.generateAccessToken.mockResolvedValue('jwt.token');
      loginAttemptService.hasActiveBlock.mockResolvedValue(null);
      userRepository.save.mockResolvedValue(mockCustomerUser as User);

      const result = await service.login(mockLoginDto, '127.0.0.1');

      expect(result).toHaveProperty('access_token', 'jwt.token');
      expect(result.user).toHaveProperty('email', 'customer@test.com');
      expect(result.user).not.toHaveProperty('password');
      expect(result.user).not.toHaveProperty('deletedAt');
    });

    it('يسجل دخول MERCHANT نشط ويعيد بيانات المتجر', async () => {
      const activeMerchant = {
        ...mockMerchantUser,
        isActive: true,
      } as User;
      usersService.findOneByEmailWithPassword.mockResolvedValue(activeMerchant);
      bcryptCompare.mockResolvedValue(true);
      tokenService.generateAccessToken.mockResolvedValue('jwt.token');
      loginAttemptService.hasActiveBlock.mockResolvedValue(null);
      userRepository.save.mockResolvedValue(activeMerchant);
      merchantsService.findByUserId.mockResolvedValue({
        id: 10,
        restaurantName: 'Test Restaurant',
        hidePhoneNumber: false,
        isOpen: true,
        description: 'Good food',
        estimatedDeliveryMinutes: 30,
        user: {
          id: 2,
          email: 'merchant@test.com',
          firstName: 'Merchant',
          lastName: 'User',
          role: 'MERCHANT',
          phone: '+96390000000',
          notificationChannel: 'EMAIL',
          firebaseToken: null,
          countryId: 1,
          country: { id: 1, name: 'Country' },
          cityId: 1,
          city: { id: 1, name: 'City' },
          address: null,
          isOnline: false,
          isActive: true,
          verifiedAt: new Date(),
          location: null,
          currentLat: null,
          currentLng: null,
          birthday: null,
          images: [],
          createdAt: new Date(),
          updatedAt: new Date(),
          deletedAt: null,
          officeOwnerId: null,
        },
      });

      const result = await service.login(
        { email: 'merchant@test.com', password: 'password123' },
        '127.0.0.1',
      );

      expect(result).toHaveProperty('access_token', 'jwt.token');
      expect(result.user).toHaveProperty('restaurantName', 'Test Restaurant');
      expect(result.user).toHaveProperty('merchantId', 10);
    });

    it('يرفض البريد الخطأ', async () => {
      usersService.findOneByEmailWithPassword.mockResolvedValue(null);
      loginAttemptService.hasActiveBlock.mockResolvedValue(null);
      loginAttemptService.recordFailedAttempt.mockResolvedValue(1);

      await expect(service.login(mockLoginDto)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('يرفض كلمة المرور الخطأ', async () => {
      usersService.findOneByEmailWithPassword.mockResolvedValue(
        mockCustomerUser as User,
      );
      bcryptCompare.mockResolvedValue(false);
      loginAttemptService.hasActiveBlock.mockResolvedValue(null);
      loginAttemptService.recordFailedAttempt.mockResolvedValue(1);

      await expect(service.login(mockLoginDto)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('يرفض حساب غير مؤكد', async () => {
      const unverifiedUser = {
        ...mockCustomerUser,
        verifiedAt: null,
      } as User;
      usersService.findOneByEmailWithPassword.mockResolvedValue(unverifiedUser);
      bcryptCompare.mockResolvedValue(true);
      loginAttemptService.hasActiveBlock.mockResolvedValue(null);

      await expect(service.login(mockLoginDto)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it('يرفض حساب MERCHANT غير نشط (pending)', async () => {
      const pendingMerchant = {
        ...mockMerchantUser,
        isActive: false,
        role: UserRole.MERCHANT,
        verifiedAt: new Date(),
      } as User;
      usersService.findOneByEmailWithPassword.mockResolvedValue(
        pendingMerchant,
      );
      bcryptCompare.mockResolvedValue(true);
      loginAttemptService.hasActiveBlock.mockResolvedValue(null);

      await expect(
        service.login({ email: 'merchant@test.com', password: 'password123' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('يحفظ firebaseToken إذا تم تقديمه', async () => {
      usersService.findOneByEmailWithPassword.mockResolvedValue(
        mockCustomerUser as User,
      );
      bcryptCompare.mockResolvedValue(true);
      tokenService.generateAccessToken.mockResolvedValue('jwt.token');
      loginAttemptService.hasActiveBlock.mockResolvedValue(null);
      userRepository.save.mockResolvedValue(mockCustomerUser as User);

      await service.login(
        { ...mockLoginDto, firebaseToken: 'fcm-token' },
        '127.0.0.1',
      );

      expect(usersService.updateFirebaseToken).toHaveBeenCalledWith(
        1,
        'fcm-token',
      );
    });

    it('يسجل دخول برقم الهاتف', async () => {
      usersService.findOneByPhoneWithPassword.mockResolvedValue(
        mockCustomerUser as User,
      );
      bcryptCompare.mockResolvedValue(true);
      tokenService.generateAccessToken.mockResolvedValue('jwt.token');
      loginAttemptService.hasActiveBlock.mockResolvedValue(null);
      userRepository.save.mockResolvedValue(mockCustomerUser as User);

      const result = await service.login(
        { phone: '+963900000001', password: 'password123' },
        '127.0.0.1',
      );

      expect(result).toHaveProperty('access_token', 'jwt.token');
      expect(usersService.findOneByPhoneWithPassword).toHaveBeenCalledWith(
        '+963900000001',
      );
    });
  });

  describe('handleGuestLogin', () => {
    it('ينشئ مستخدم ضيف جديد ويعيد توكن', async () => {
      tokenService.generateAccessToken.mockResolvedValue('guest-jwt');
      usersService.findOneByEmail.mockResolvedValue(null);
      userRepository.create.mockReturnValue({
        email: 'guest-testuid123@jeeb.local',
        password: 'hashed_password',
        firstName: 'Guest',
        lastName: 'User',
        phone: 'testuid123',
        role: UserRole.CUSTOMER,
        isActive: true,
        verifiedAt: expect.any(Date),
        firebaseToken: 'fcm-token:APA91bxxxx',
      } as User);
      userRepository.save.mockResolvedValue({
        id: 999,
        email: 'guest-testuid123@jeeb.local',
        firstName: 'Guest',
        lastName: 'User',
        role: UserRole.CUSTOMER,
        isActive: true,
        images: [],
      } as User);

      const result = await service.handleGuestLogin(
        'testuid123:APA91bxxxx',
        '127.0.0.1',
      );

      expect(result).toHaveProperty('access_token', 'guest-jwt');
      expect(result.user).toHaveProperty('is_guest', true);
    });

    it('يعيد مستخدم ضيف موجود', async () => {
      const existingGuest = {
        id: 100,
        email: 'guest-existing@jeeb.local',
        firstName: 'Guest',
        lastName: 'User',
        role: UserRole.CUSTOMER,
        isActive: true,
        firebaseToken: 'old-token',
        images: [],
      } as User;
      usersService.findOneByEmail.mockResolvedValue(existingGuest);
      tokenService.generateAccessToken.mockResolvedValue('guest-jwt');
      userRepository.save.mockResolvedValue(existingGuest);

      const result = await service.handleGuestLogin(
        'existing-uid',
        '127.0.0.1',
      );

      expect(result).toHaveProperty('access_token', 'guest-jwt');
      expect(result.user).toHaveProperty('is_guest', true);
    });
  });

  describe('handleFailedLogin', () => {
    it('يُسجل المحاولات ويُبلغ عند 3 محاولات', async () => {
      loginAttemptService.recordFailedAttempt.mockResolvedValue(3);

      await service.handleFailedLogin(1, 'user@test.com', '127.0.0.1');

      expect(loginAttemptService.recordFailedAttempt).toHaveBeenCalledWith(
        'user@test.com',
        '127.0.0.1',
      );
    });

    it('يُبلغ ويحظر عند 5 محاولات', async () => {
      loginAttemptService.recordFailedAttempt.mockResolvedValue(5);
      loginAttemptService.createBlock.mockResolvedValue({
        blockLevel: 'LEVEL_1',
      } as any);
      loginAttemptService.getDurationText.mockReturnValue('1 hour');

      await service.handleFailedLogin(1, 'user@test.com', '127.0.0.1');

      expect(loginAttemptService.createBlock).toHaveBeenCalled();
    });
  });

  describe('updateFirebaseToken', () => {
    it('يحدث توكن Firebase ويعيد المستخدم', async () => {
      usersService.updateFirebaseToken.mockResolvedValue(undefined);
      usersService.findOneById.mockResolvedValue(mockCustomerUser as User);

      const result = await service.updateFirebaseToken(1, 'new-fcm-token');

      expect(result).toHaveProperty('email', 'customer@test.com');
      expect(usersService.updateFirebaseToken).toHaveBeenCalledWith(
        1,
        'new-fcm-token',
      );
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { RegistrationService } from '../../../../src/modules/auth/services/registration.service';
import { UsersService } from '../../../../src/modules/users/users.service';
import { NotificationsService } from '../../../../src/modules/notifications/notifications.service';
import { MerchantsService } from '../../../../src/modules/merchants/merchants.service';
import { TokenService } from '../../../../src/modules/auth/token.service';
import { CustomerRegistrationStrategy } from '../../../../src/modules/auth/strategies/customer-registration.strategy';
import { ImageProcessingService } from '../../../../src/common/image-processing/image-processing.service';
import { StorageService } from '../../../../src/common/storage/storage.service';
import { FirebaseService } from '../../../../src/modules/firebase/firebase.service';
import { CountriesService } from '../../../../src/modules/countries/countries.service';
import { CitiesService } from '../../../../src/modules/cities/cities.service';
import { Image } from '../../../../src/database/entities/image.entity';
import { User } from '../../../../src/database/entities/user.entity';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { NotificationChannel } from '../../../../src/common/enums/notification-channel.enum';
import { RegisterDto } from '../../../../src/modules/auth/dto/register.dto';
import { Repository } from 'typeorm';

jest.mock('bcrypt', () => ({
  hash: jest.fn().mockResolvedValue('hashed_password_123'),
  compare: jest.fn(),
}));

describe('RegistrationService', () => {
  let service: RegistrationService;
  let module: TestingModule;
  let usersService: jest.Mocked<UsersService>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let merchantsService: jest.Mocked<MerchantsService>;
  let tokenService: jest.Mocked<TokenService>;
  let firebaseService: jest.Mocked<FirebaseService>;
  let countriesService: jest.Mocked<CountriesService>;
  let citiesService: jest.Mocked<CitiesService>;
  let userRepository: jest.Mocked<Repository<User>>;

  const mockRegisterDto: RegisterDto = {
    email: 'newuser@test.com',
    password: 'password123',
    firstName: 'John',
    lastName: 'Doe',
    phone: '+963900000001',
    role: UserRole.CUSTOMER,
  } as RegisterDto;

  const mockMerchantDto: RegisterDto = {
    ...mockRegisterDto,
    role: UserRole.MERCHANT,
    restaurantName: 'Test Restaurant',
  } as RegisterDto;

  const mockDeliveryDto: RegisterDto = {
    ...mockRegisterDto,
    role: UserRole.DELIVERY,
  } as RegisterDto;

  const mockCreatedUser: Partial<User> = {
    id: 1,
    email: 'newuser@test.com',
    firstName: 'John',
    lastName: 'Doe',
    phone: '+963900000001',
    role: UserRole.CUSTOMER,
    notificationChannel: NotificationChannel.WHATSAPP,
    isActive: true,
    verifiedAt: null,
    password: 'hashed_password_123',
    images: [],
    countryId: 1,
    cityId: 1,
  };

  beforeEach(async () => {
    module = await Test.createTestingModule({
      providers: [
        RegistrationService,
        {
          provide: CustomerRegistrationStrategy,
          useValue: {
            register: jest.fn(),
          },
        },
        {
          provide: UsersService,
          useValue: {
            findOneByEmailWithDeleted: jest.fn(),
            findOneByPhoneWithDeleted: jest.fn(),
            findOneByEmail: jest.fn(),
            findOneByPhone: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
            restore: jest.fn(),
          },
        },
        {
          provide: NotificationsService,
          useValue: {
            sendOtp: jest.fn(),
            verifyOtp: jest.fn(),
            sendWelcomeMessage: jest.fn(),
            sendToUser: jest.fn(),
          },
        },
        {
          provide: MerchantsService,
          useValue: {
            createMerchantProfile: jest.fn(),
            findByUserId: jest.fn(),
          },
        },
        {
          provide: TokenService,
          useValue: {
            generateAccessToken: jest.fn(),
          },
        },
        {
          provide: ImageProcessingService,
          useValue: {
            processAndUpload: jest.fn(),
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
          provide: FirebaseService,
          useValue: {
            createDriverDocument: jest.fn(),
            verifyIdToken: jest.fn(),
            createCustomTokenForDelivery: jest.fn(),
            deleteDriverDocument: jest.fn(),
          },
        },
        {
          provide: CountriesService,
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: CitiesService,
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Image),
          useValue: {
            create: jest.fn(),
            save: jest.fn(),
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(User),
          useValue: {
            find: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<RegistrationService>(RegistrationService);
    usersService = module.get(UsersService);
    notificationsService = module.get(NotificationsService);
    merchantsService = module.get(MerchantsService);
    tokenService = module.get(TokenService);
    firebaseService = module.get(FirebaseService);
    countriesService = module.get(CountriesService);
    citiesService = module.get(CitiesService);
    userRepository = module.get(getRepositoryToken(User));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('register', () => {
    it('يرفض CUSTOMER ويوجه لاستخدام التدفق الجديد', async () => {
      await expect(service.register(mockRegisterDto)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('ينشئ حساب MERCHANT بنجاح (بدون userId)', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue(null);
      usersService.create.mockResolvedValue({
        ...mockCreatedUser,
        role: UserRole.MERCHANT,
        isActive: false,
      } as User);
      countriesService.findOne.mockResolvedValue({ id: 1 } as any);
      citiesService.findOne.mockResolvedValue({
        id: 1,
        country: { id: 1 },
      } as any);

      const result = await service.register(mockMerchantDto);

      expect(result).toEqual({
        message: expect.stringContaining('قيد المراجعة'),
        data: { message: expect.stringContaining('قيد المراجعة') },
      });
      expect(result.data).not.toHaveProperty('userId');
      expect(merchantsService.createMerchantProfile).toHaveBeenCalledWith(
        1,
        expect.objectContaining({ restaurantName: 'Test Restaurant' }),
      );
    });

    it('ينشئ حساب DELIVERY بنجاح و ينشئ Firebase doc', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue(null);
      usersService.create.mockResolvedValue({
        ...mockCreatedUser,
        role: UserRole.DELIVERY,
        isActive: false,
      } as User);
      countriesService.findOne.mockResolvedValue({ id: 1 } as any);
      citiesService.findOne.mockResolvedValue({
        id: 1,
        country: { id: 1 },
      } as any);

      const result = await service.register(mockDeliveryDto);

      expect(result).toEqual({
        message: expect.stringContaining('قيد المراجعة'),
        data: { message: expect.stringContaining('قيد المراجعة') },
      });
      expect(firebaseService.createDriverDocument).toHaveBeenCalled();
    });

    it('يرفض الإيميل المكرر لـ MERCHANT', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue({
        id: 1,
        email: 'newuser@test.com',
        deletedAt: null,
        verifiedAt: new Date(),
      } as User);

      await expect(service.register(mockMerchantDto)).rejects.toThrow(
        BadRequestException,
      );
      expect(usersService.create).not.toHaveBeenCalled();
    });

    it('يرفض تسجيل MERCHANT بدون restaurantName', async () => {
      const dtoWithoutRestaurant = {
        ...mockRegisterDto,
        role: UserRole.MERCHANT,
      } as RegisterDto;

      await expect(service.register(dtoWithoutRestaurant)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('يرفض دور ADMIN', async () => {
      const adminDto = {
        ...mockRegisterDto,
        role: UserRole.ADMIN,
      } as RegisterDto;

      await expect(service.register(adminDto)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('يستعيد المستخدم المحذوف ناعماً (soft-deleted) لـ MERCHANT', async () => {
      const deletedUser = {
        id: 1,
        email: 'newuser@test.com',
        deletedAt: new Date(),
      } as User;
      usersService.findOneByEmailWithDeleted.mockResolvedValue(deletedUser);
      usersService.restore.mockResolvedValue(undefined);
      usersService.update.mockResolvedValue({
        ...mockCreatedUser,
        role: UserRole.MERCHANT,
        deletedAt: null,
      } as User);
      countriesService.findOne.mockResolvedValue({ id: 1 } as any);
      citiesService.findOne.mockResolvedValue({
        id: 1,
        country: { id: 1 },
      } as any);

      const result = await service.register(mockMerchantDto);

      expect(usersService.restore).toHaveBeenCalledWith(1);
      expect(usersService.update).toHaveBeenCalled();
      expect(result.data).not.toHaveProperty('userId');
    });
  });

  describe('verifyAccount', () => {
    const email = 'user@test.com';

    it('يؤكد حساب CUSTOMER ويعيد access_token', async () => {
      const mockUser = {
        ...mockCreatedUser,
        id: 1,
        email,
        role: UserRole.CUSTOMER,
        verifiedAt: null,
        notificationChannel: NotificationChannel.WHATSAPP,
        images: [],
      } as User;
      usersService.findOneByEmail.mockResolvedValue(mockUser);
      notificationsService.verifyOtp.mockResolvedValue(true);
      tokenService.generateAccessToken.mockResolvedValue('jwt.token.here');

      const result = await service.verifyAccount(email, '123456');

      expect(result).toHaveProperty(
        'message',
        'Account verified successfully.',
      );
      expect(result.data).toHaveProperty('access_token', 'jwt.token.here');
      expect(result.data).toHaveProperty('user');
      expect(result.data.user).toHaveProperty('id', 1);
      expect(usersService.update).toHaveBeenCalledWith(1, {
        verifiedAt: expect.any(Date),
        notificationChannel: NotificationChannel.FIREBASE,
      });
    });

    it('يؤكد حساب MERCHANT ويعيد statusCode 202 مع isActive', async () => {
      const mockMerchant = {
        ...mockCreatedUser,
        id: 2,
        email,
        role: UserRole.MERCHANT,
        verifiedAt: null,
        isActive: false,
        notificationChannel: NotificationChannel.EMAIL,
      } as User;
      usersService.findOneByEmail.mockResolvedValue(mockMerchant);
      notificationsService.verifyOtp.mockResolvedValue(true);

      const result = await service.verifyAccount(email, '123456');

      expect(result).toHaveProperty('statusCode', 202);
      expect(result.data).toHaveProperty('isActive', false);
      expect(result.data).toHaveProperty('userId', 2);
      expect(result.data).not.toHaveProperty('access_token');
    });

    it('يؤكد حساب DELIVERY ويعيد statusCode 202 (بدون isActive)', async () => {
      const mockDelivery = {
        ...mockCreatedUser,
        id: 3,
        email,
        role: UserRole.DELIVERY,
        verifiedAt: null,
        notificationChannel: NotificationChannel.EMAIL,
      } as User;
      usersService.findOneByEmail.mockResolvedValue(mockDelivery);
      notificationsService.verifyOtp.mockResolvedValue(true);

      const result = await service.verifyAccount(email, '123456');

      expect(result).toHaveProperty('statusCode', 202);
      expect(result.data).toHaveProperty('userId', 3);
      expect(result.data).not.toHaveProperty('access_token');
      expect(result.data).not.toHaveProperty('isActive');
    });

    it('يرجع already verified إذا الحساب مؤكد مسبقاً', async () => {
      const verifiedUser = {
        ...mockCreatedUser,
        email,
        verifiedAt: new Date(),
      } as User;
      usersService.findOneByEmail.mockResolvedValue(verifiedUser);

      const result = await service.verifyAccount(email, '123456');

      expect(result).toEqual({ message: 'Account already verified' });
    });

    it('يرفض مستخدم غير موجود', async () => {
      usersService.findOneByEmail.mockResolvedValue(null);

      await expect(
        service.verifyAccount('unknown@test.com', '123456'),
      ).rejects.toThrow(NotFoundException);
    });

    it('يرفض OTP غير صالح', async () => {
      const mockUser = { ...mockCreatedUser, email, verifiedAt: null } as User;
      usersService.findOneByEmail.mockResolvedValue(mockUser);
      notificationsService.verifyOtp.mockResolvedValue(false);

      await expect(service.verifyAccount(email, 'wrong-otp')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('يبحث عن مستخدم بواسطة phone إذا لم يتم العثور عليه بالـ email', async () => {
      const phoneUser = {
        ...mockCreatedUser,
        id: 5,
        email: 'phoneuser@test.com',
        phone: '+963900000005',
        role: UserRole.CUSTOMER,
        verifiedAt: null,
        notificationChannel: NotificationChannel.WHATSAPP,
        images: [],
      } as User;
      usersService.findOneByEmail.mockResolvedValue(null);
      usersService.findOneByPhone.mockResolvedValue(phoneUser);
      notificationsService.verifyOtp.mockResolvedValue(true);
      tokenService.generateAccessToken.mockResolvedValue('token.phone');

      const result = await service.verifyAccount('+963900000005', '123456');

      expect(result).toHaveProperty(
        'message',
        'Account verified successfully.',
      );
      expect(usersService.findOneByPhone).toHaveBeenCalledWith(
        '+963900000005',
      );
    });
  });

  describe('createAdminOrMerchant', () => {
    it('ينشئ مستخدم MERCHANT بنجاح', async () => {
      usersService.create.mockResolvedValue(mockCreatedUser as User);

      const result = await service.createAdminOrMerchant({
        email: 'merchant@test.com',
        password: 'password123',
        firstName: 'Merchant',
        lastName: 'User',
        phone: '+96390000002',
        role: UserRole.MERCHANT,
      } as any);

      expect(result).toHaveProperty('message', 'User created successfully.');
      expect(result).toHaveProperty('userId', 1);
      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          verifiedAt: expect.any(Date),
          isOnline: true,
        }),
      );
    });

    it('يرفض دور CUSTOMER', async () => {
      await expect(
        service.createAdminOrMerchant({
          role: UserRole.CUSTOMER,
        } as any),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { getRepositoryToken } from '@nestjs/typeorm';
import Redis from 'ioredis';
import { CustomerRegistrationFlowService } from '../../../../../src/modules/auth/services/customer-registration-flow.service';
import { UsersService } from '../../../../../src/modules/users/users.service';
import { NotificationsService } from '../../../../../src/modules/notifications/notifications.service';
import { ImageProcessingService } from '../../../../../src/common/image-processing/image-processing.service';
import { StorageService } from '../../../../../src/common/storage/storage.service';
import { CountriesService } from '../../../../../src/modules/countries/countries.service';
import { CitiesService } from '../../../../../src/modules/cities/cities.service';
import { TokenService } from '../../../../../src/modules/auth/token.service';
import { Image } from '../../../../../src/database/entities/image.entity';
import { User } from '../../../../../src/database/entities/user.entity';
import { UserRole } from '../../../../../src/common/enums/user-role.enum';
import { NotificationChannel } from '../../../../../src/common/enums/notification-channel.enum';
import { NotificationType } from '../../../../../src/common/enums/notification-type.enum';
import { ImageEntityType } from '../../../../../src/common/enums/image-entity-type.enum';
import { REDIS_CLIENT } from '../../../../../src/common/redis/redis.constants';
import { CustomerInitDto } from '../../../../../src/modules/auth/dto/customer-init.dto';
import { CustomerCompleteRegistrationDto } from '../../../../../src/modules/auth/dto/customer-complete-registration.dto';
import { Repository } from 'typeorm';

jest.mock('bcrypt', () => ({
  hash: jest.fn().mockResolvedValue('hashed_password_123'),
  compare: jest.fn(),
}));

describe('CustomerRegistrationFlowService', () => {
  let service: CustomerRegistrationFlowService;
  let usersService: jest.Mocked<UsersService>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let countriesService: jest.Mocked<CountriesService>;
  let citiesService: jest.Mocked<CitiesService>;
  let tokenService: jest.Mocked<TokenService>;
  let module: TestingModule;
  let imageRepository: jest.Mocked<Repository<Image>>;
  let redis: jest.Mocked<Redis>;

  const mockInitDto: CustomerInitDto = {
    phone: '+963912345678',
    firstName: 'John',
    lastName: 'Doe',
    password: 'password123',
  };

  const mockCompleteDto: CustomerCompleteRegistrationDto = {
    email: 'customer@test.com',
    countryId: 1,
    cityId: 1,
    address: 'Damascus, Syria',
  };

  const mockCreatedUser: Partial<User> = {
    id: 1,
    email: null,
    firstName: 'John',
    lastName: 'Doe',
    phone: '+963912345678',
    role: UserRole.CUSTOMER,
    notificationChannel: NotificationChannel.FIREBASE,
    isActive: true,
    verifiedAt: new Date(),
    password: 'hashed_password_123',
    images: [],
  };

  const mockUpdatedUser: Partial<User> = {
    id: 1,
    email: 'customer@test.com',
    firstName: 'John',
    lastName: 'Doe',
    phone: '+963912345678',
    role: UserRole.CUSTOMER,
    notificationChannel: NotificationChannel.FIREBASE,
    isActive: true,
    countryId: 1,
    cityId: 1,
    address: 'Damascus, Syria',
    images: [],
  };

  beforeEach(async () => {
    module = await Test.createTestingModule({
      providers: [
        CustomerRegistrationFlowService,
        {
          provide: UsersService,
          useValue: {
            findOneByPhoneWithDeleted: jest.fn(),
            findOneByEmailWithDeleted: jest.fn(),
            findOneByPhone: jest.fn(),
            findOneById: jest.fn(),
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
          provide: TokenService,
          useValue: {
            generateAccessToken: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Image),
          useValue: {
            create: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: REDIS_CLIENT,
          useValue: {
            get: jest.fn(),
            set: jest.fn(),
            del: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<CustomerRegistrationFlowService>(
      CustomerRegistrationFlowService,
    );
    usersService = module.get(UsersService);
    notificationsService = module.get(NotificationsService);
    countriesService = module.get(CountriesService);
    citiesService = module.get(CitiesService);
    tokenService = module.get(TokenService);
    imageRepository = module.get(getRepositoryToken(Image));
    redis = module.get(REDIS_CLIENT);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('init', () => {
    it('يرسل OTP ويخزن الجلسة في Redis', async () => {
      usersService.findOneByPhoneWithDeleted.mockResolvedValue(null);

      const result = await service.init(mockInitDto);

      expect(usersService.findOneByPhoneWithDeleted).toHaveBeenCalledWith(
        mockInitDto.phone,
      );
      expect(notificationsService.sendOtp).toHaveBeenCalledWith(
        mockInitDto.phone,
        expect.any(String),
        NotificationChannel.WHATSAPP,
      );
      expect(redis.set).toHaveBeenCalledWith(
        `reg_customer:${mockInitDto.phone}`,
        JSON.stringify({
          status: 'pending',
          phone: mockInitDto.phone,
          firstName: mockInitDto.firstName,
          lastName: mockInitDto.lastName,
          password: 'hashed_password_123',
        }),
        'EX',
        900,
      );
      expect(result).toEqual({
        message: 'OTP sent successfully to your phone.',
      });
    });

    it('يرفض إذا كان رقم الهاتف موجوداً بالفعل', async () => {
      usersService.findOneByPhoneWithDeleted.mockResolvedValue({
        id: 1,
        phone: mockInitDto.phone,
        deletedAt: null,
      } as User);

      await expect(service.init(mockInitDto)).rejects.toThrow(
        BadRequestException,
      );
      expect(notificationsService.sendOtp).not.toHaveBeenCalled();
    });

    it('يسمح بإعادة التسجيل لرقم محذوف ناعماً (soft-deleted)', async () => {
      usersService.findOneByPhoneWithDeleted.mockResolvedValue({
        id: 1,
        phone: mockInitDto.phone,
        deletedAt: new Date(),
      } as User);

      const result = await service.init(mockInitDto);

      expect(notificationsService.sendOtp).toHaveBeenCalled();
      expect(result).toEqual({
        message: 'OTP sent successfully to your phone.',
      });
    });
  });

  describe('verifyPhone', () => {
    it('يتحقق من OTP وينشئ الحساب ويعيد access_token', async () => {
      redis.get.mockResolvedValue(
        JSON.stringify({
          status: 'pending',
          phone: mockInitDto.phone,
          firstName: 'John',
          lastName: 'Doe',
          password: 'hashed_password_123',
        }),
      );
      notificationsService.verifyOtp.mockResolvedValue(true);
      usersService.create.mockResolvedValue(mockCreatedUser as User);
      tokenService.generateAccessToken.mockResolvedValue('jwt.token.here');

      const result = await service.verifyPhone(mockInitDto.phone, '123456');

      expect(redis.get).toHaveBeenCalledWith(
        `reg_customer:${mockInitDto.phone}`,
      );
      expect(notificationsService.verifyOtp).toHaveBeenCalledWith(
        mockInitDto.phone,
        '123456',
        NotificationType.OTP,
      );
      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          phone: mockInitDto.phone,
          firstName: 'John',
          lastName: 'Doe',
          password: 'hashed_password_123',
          role: UserRole.CUSTOMER,
          notificationChannel: NotificationChannel.FIREBASE,
          verifiedAt: expect.any(Date),
          isActive: true,
        }),
      );
      expect(redis.del).toHaveBeenCalledWith(
        `reg_customer:${mockInitDto.phone}`,
      );
      expect(tokenService.generateAccessToken).toHaveBeenCalled();
      expect(result).toHaveProperty('message', 'Account created and verified successfully.');
      expect(result.data).toHaveProperty('access_token', 'jwt.token.here');
      expect(result.data.user).toHaveProperty('id', 1);
      expect(result.data.user).toHaveProperty('phone', mockInitDto.phone);
      expect(result.data.user).toHaveProperty('role', UserRole.CUSTOMER);
    });

    it('يرفض إذا لم توجد جلسة', async () => {
      redis.get.mockResolvedValue(null);

      await expect(
        service.verifyPhone(mockInitDto.phone, '123456'),
      ).rejects.toThrow(BadRequestException);
    });

    it('يرفض OTP غير صحيح', async () => {
      redis.get.mockResolvedValue(
        JSON.stringify({
          status: 'pending',
          phone: mockInitDto.phone,
          firstName: 'John',
          lastName: 'Doe',
          password: 'hashed_password_123',
        }),
      );
      notificationsService.verifyOtp.mockResolvedValue(false);

      await expect(
        service.verifyPhone(mockInitDto.phone, 'wrong'),
      ).rejects.toThrow(BadRequestException);
      expect(usersService.create).not.toHaveBeenCalled();
    });
  });

  describe('completeRegistration', () => {
    beforeEach(() => {
      usersService.findOneById.mockResolvedValue(mockCreatedUser as User);
      usersService.update.mockResolvedValue(mockUpdatedUser as User);
      countriesService.findOne.mockResolvedValue({ id: 1 } as any);
      citiesService.findOne.mockResolvedValue({
        id: 1,
        country: { id: 1 },
      } as any);
    });

    it('يحدث بيانات العميل ويُكمل التسجيل', async () => {
      const result = await service.completeRegistration(1, mockCompleteDto);

      expect(usersService.findOneById).toHaveBeenCalledWith(1);
      expect(usersService.update).toHaveBeenCalledWith(
        1,
        expect.objectContaining({
          email: mockCompleteDto.email,
          countryId: 1,
          cityId: 1,
          address: 'Damascus, Syria',
        }),
      );
      expect(result).toHaveProperty('message', 'Profile updated successfully.');
      expect(result.data.user).toHaveProperty('id', 1);
    });

    it('يرفض مستخدم غير موجود', async () => {
      usersService.findOneById.mockResolvedValue(null);

      await expect(
        service.completeRegistration(999, mockCompleteDto),
      ).rejects.toThrow(NotFoundException);
    });

    it('يرفض إيميل مكرر', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue({
        id: 2,
        email: mockCompleteDto.email,
        deletedAt: null,
      } as User);

      await expect(
        service.completeRegistration(1, mockCompleteDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('يسمح بالإيميل إذا كان لنفس المستخدم', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue({
        id: 1,
        email: mockCompleteDto.email,
        deletedAt: null,
      } as User);

      const result = await service.completeRegistration(1, mockCompleteDto);

      expect(usersService.update).toHaveBeenCalled();
      expect(result).toHaveProperty('message', 'Profile updated successfully.');
    });

    it('يرفض دولة غير موجودة', async () => {
      countriesService.findOne.mockRejectedValue(
        new NotFoundException('Country not found'),
      );

      await expect(
        service.completeRegistration(1, mockCompleteDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('يرفض مدينة لا تنتمي للدولة', async () => {
      citiesService.findOne.mockResolvedValue({
        id: 2,
        country: { id: 999 },
      } as any);

      await expect(
        service.completeRegistration(1, mockCompleteDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('يرفض مدينة غير موجودة', async () => {
      citiesService.findOne.mockRejectedValue(
        new NotFoundException('City not found'),
      );

      await expect(
        service.completeRegistration(1, mockCompleteDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('يعالج صور الملف الشخصي إذا تم رفعها', async () => {
      const imageProcessingService = module.get(ImageProcessingService);
      (imageProcessingService.processAndUpload as jest.Mock).mockResolvedValue({
        original: 'http://example.com/img.jpg',
        mobile: 'http://example.com/img-mobile.jpg',
        thumbnail: 'http://example.com/img-thumb.jpg',
      });
      imageRepository.create.mockReturnValue({} as Image);
      imageRepository.save.mockResolvedValue({ id: 1 } as Image);

      const mockFile = { buffer: Buffer.from('test'), originalname: 'test.jpg' } as Express.Multer.File;

      const result = await service.completeRegistration(
        1,
        mockCompleteDto,
        [mockFile],
      );

      expect(imageProcessingService.processAndUpload).toHaveBeenCalledWith(
        mockFile,
        'users/1',
      );
      expect(imageRepository.create).toHaveBeenCalledWith({
        entityType: ImageEntityType.USER,
        entityId: 1,
        url: 'http://example.com/img.jpg',
        mobileUrl: 'http://example.com/img-mobile.jpg',
        thumbnailUrl: 'http://example.com/img-thumb.jpg',
        isMain: true,
        displayOrder: 0,
      });
      expect(imageRepository.save).toHaveBeenCalled();
      expect(result).toHaveProperty('message', 'Profile updated successfully.');
    });

    it('يتجاهل الصور إذا لم يتم رفع ملفات', async () => {
      const imageProcessingService = module.get(ImageProcessingService);

      await service.completeRegistration(1, mockCompleteDto);

      expect(imageProcessingService.processAndUpload).not.toHaveBeenCalled();
    });

    it('يحدث فقط الحقول المرسلة ويتجاهل undefined', async () => {
      const partialDto: CustomerCompleteRegistrationDto = {
        email: 'new@test.com',
      };

      await service.completeRegistration(1, partialDto);

      expect(usersService.update).toHaveBeenCalledWith(
        1,
        expect.objectContaining({
          email: 'new@test.com',
        }),
      );
      expect(usersService.update).not.toHaveBeenCalledWith(
        expect.objectContaining({
          countryId: expect.anything(),
        }),
      );
    });
  });
});

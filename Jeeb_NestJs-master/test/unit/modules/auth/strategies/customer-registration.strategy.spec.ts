import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { BadRequestException } from '@nestjs/common';
import { CustomerRegistrationStrategy } from '../../../../../src/modules/auth/strategies/customer-registration.strategy';
import { UsersService } from '../../../../../src/modules/users/users.service';
import { NotificationsService } from '../../../../../src/modules/notifications/notifications.service';
import { ImageProcessingService } from '../../../../../src/common/image-processing/image-processing.service';
import { StorageService } from '../../../../../src/common/storage/storage.service';
import { CountriesService } from '../../../../../src/modules/countries/countries.service';
import { CitiesService } from '../../../../../src/modules/cities/cities.service';
import { Image } from '../../../../../src/database/entities/image.entity';
import { User } from '../../../../../src/database/entities/user.entity';
import { UserRole } from '../../../../../src/common/enums/user-role.enum';
import { NotificationChannel } from '../../../../../src/common/enums/notification-channel.enum';
import { RegisterDto } from '../../../../../src/modules/auth/dto/register.dto';
import { Repository } from 'typeorm';

jest.mock('bcrypt', () => ({
  hash: jest.fn().mockResolvedValue('hashed_password_123'),
  compare: jest.fn(),
}));

describe('CustomerRegistrationStrategy', () => {
  let strategy: CustomerRegistrationStrategy;
  let usersService: jest.Mocked<UsersService>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let countriesService: jest.Mocked<CountriesService>;
  let citiesService: jest.Mocked<CitiesService>;
  let imageRepository: jest.Mocked<Repository<Image>>;
  let imageProcessingService: jest.Mocked<ImageProcessingService>;

  const mockRegisterDto: RegisterDto = {
    email: 'customer@test.com',
    password: 'password123',
    firstName: 'John',
    lastName: 'Doe',
    phone: '+963900000001',
    role: UserRole.CUSTOMER,
  } as RegisterDto;

  const mockCreatedUser: Partial<User> = {
    id: 1,
    email: 'customer@test.com',
    firstName: 'John',
    lastName: 'Doe',
    phone: '+963900000001',
    role: UserRole.CUSTOMER,
    notificationChannel: NotificationChannel.WHATSAPP,
    isActive: true,
    verifiedAt: null,
    password: 'hashed_password_123',
    images: [],
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CustomerRegistrationStrategy,
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
          provide: getRepositoryToken(Image),
          useValue: {
            create: jest.fn(),
            save: jest.fn(),
            find: jest.fn(),
          },
        },
      ],
    }).compile();

    strategy = module.get<CustomerRegistrationStrategy>(
      CustomerRegistrationStrategy,
    );
    usersService = module.get(UsersService);
    notificationsService = module.get(NotificationsService);
    countriesService = module.get(CountriesService);
    citiesService = module.get(CitiesService);
    imageRepository = module.get(getRepositoryToken(Image));
    imageProcessingService = module.get(ImageProcessingService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('register', () => {
    it('ينشئ حساب CUSTOMER بنجاح ويعيد userId', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue(null);
      usersService.findOneByPhoneWithDeleted.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockCreatedUser as User);

      const result = await strategy.register(mockRegisterDto);

      expect(result).toEqual({
        message: expect.stringContaining('registered'),
        data: {
          message: expect.stringContaining('registered'),
          userId: 1,
        },
      });
      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          email: 'customer@test.com',
          role: UserRole.CUSTOMER,
          isActive: true,
        }),
      );
      expect(notificationsService.sendOtp).toHaveBeenCalled();
    });

    it('يستعيد المستخدم المحذوف ناعماً (soft-deleted)', async () => {
      const deletedUser = {
        id: 1,
        email: 'customer@test.com',
        deletedAt: new Date(),
      } as User;
      usersService.findOneByEmailWithDeleted.mockResolvedValue(deletedUser);
      usersService.findOneByPhoneWithDeleted.mockResolvedValue(null);
      usersService.restore.mockResolvedValue(undefined);
      usersService.update.mockResolvedValue({
        ...mockCreatedUser,
        deletedAt: null,
      } as User);

      const result = await strategy.register(mockRegisterDto);

      expect(usersService.restore).toHaveBeenCalledWith(1);
      expect(usersService.update).toHaveBeenCalled();
      expect(result.data).toHaveProperty('userId', 1);
    });

    it('يقبل countryId و cityId صحيحين', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue(null);
      usersService.findOneByPhoneWithDeleted.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockCreatedUser as User);
      countriesService.findOne.mockResolvedValue({ id: 1 } as any);
      citiesService.findOne.mockResolvedValue({
        id: 1,
        country: { id: 1 },
      } as any);

      const dto = { ...mockRegisterDto, countryId: 1, cityId: 1 } as RegisterDto;
      const result = await strategy.register(dto);

      expect(countriesService.findOne).toHaveBeenCalledWith(1);
      expect(citiesService.findOne).toHaveBeenCalledWith(1);
      expect(result.data).toHaveProperty('userId', 1);
    });

    it('يرفض الإيميل المكرر', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue({
        id: 1,
        email: 'customer@test.com',
        deletedAt: null,
      } as User);

      await expect(strategy.register(mockRegisterDto)).rejects.toThrow(
        BadRequestException,
      );
      expect(usersService.create).not.toHaveBeenCalled();
    });

    it('يرفض رقم الهاتف المكرر', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue(null);
      usersService.findOneByPhoneWithDeleted.mockResolvedValue({
        id: 2,
        phone: '+963900000001',
        deletedAt: null,
      } as User);

      await expect(strategy.register(mockRegisterDto)).rejects.toThrow(
        BadRequestException,
      );
      expect(usersService.create).not.toHaveBeenCalled();
    });

    it('يرفض countryId غير موجود', async () => {
      countriesService.findOne.mockRejectedValue(
        new (require('@nestjs/common').NotFoundException)('Country not found'),
      );

      await expect(
        strategy.register({
          ...mockRegisterDto,
          countryId: 999,
        } as RegisterDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('يرفض cityId لا يتبع countryId', async () => {
      countriesService.findOne.mockResolvedValue({ id: 1 } as any);
      citiesService.findOne.mockResolvedValue({
        id: 2,
        country: { id: 999 },
      } as any);

      await expect(
        strategy.register({
          ...mockRegisterDto,
          countryId: 1,
          cityId: 2,
        } as RegisterDto),
      ).rejects.toThrow(BadRequestException);
    });

    it('يرسل OTP عبر WhatsApp حتى لو notificationChannel = EMAIL', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue(null);
      usersService.findOneByPhoneWithDeleted.mockResolvedValue(null);
      usersService.create.mockResolvedValue({
        ...mockCreatedUser,
        notificationChannel: NotificationChannel.EMAIL,
      } as User);

      await strategy.register(mockRegisterDto);

      expect(notificationsService.sendOtp).toHaveBeenCalledWith(
        mockRegisterDto.phone,
        expect.any(String),
        NotificationChannel.WHATSAPP,
        1,
      );
    });

    it('يعالج الصورة المرفوعة', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue(null);
      usersService.findOneByPhoneWithDeleted.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockCreatedUser as User);
      imageProcessingService.processAndUpload.mockResolvedValue({
        original: 'https://cdn.example.com/original.jpg',
        mobile: 'https://cdn.example.com/mobile.jpg',
        thumbnail: 'https://cdn.example.com/thumb.jpg',
      });
      imageRepository.create.mockReturnValue({} as Image);
      imageRepository.save.mockResolvedValue({ id: 10 } as Image);

      const fakeFile = { originalname: 'profile.jpg' } as Express.Multer.File;
      await strategy.register(mockRegisterDto, [fakeFile]);

      expect(imageRepository.save).toHaveBeenCalled();
    });

    it('يتجاهل الصورة إذا لم يتم رفع أي ملف', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue(null);
      usersService.findOneByPhoneWithDeleted.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockCreatedUser as User);

      await strategy.register(mockRegisterDto);

      expect(imageRepository.save).not.toHaveBeenCalled();
    });

    it('يعيد response بالصيغة الصحيحة', async () => {
      usersService.findOneByEmailWithDeleted.mockResolvedValue(null);
      usersService.findOneByPhoneWithDeleted.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockCreatedUser as User);

      const result = await strategy.register(mockRegisterDto);

      expect(result).toMatchObject({
        message: expect.any(String),
        data: {
          message: expect.any(String),
          userId: expect.any(Number),
        },
      });
    });
  });
});

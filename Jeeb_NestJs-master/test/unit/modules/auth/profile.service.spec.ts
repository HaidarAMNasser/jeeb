import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { ProfileService } from '../../../../src/modules/auth/services/profile.service';
import { UsersService } from '../../../../src/modules/users/users.service';
import { MerchantsService } from '../../../../src/modules/merchants/merchants.service';
import { ImageProcessingService } from '../../../../src/common/image-processing/image-processing.service';
import { StorageService } from '../../../../src/common/storage/storage.service';
import { FirebaseService } from '../../../../src/modules/firebase/firebase.service';
import { CountriesService } from '../../../../src/modules/countries/countries.service';
import { CitiesService } from '../../../../src/modules/cities/cities.service';
import { AreasService } from '../../../../src/modules/areas/areas.service';
import { Image } from '../../../../src/database/entities/image.entity';
import { Order } from '../../../../src/database/entities/order.entity';
import { DeliveryAssignment } from '../../../../src/database/entities/delivery-assignment.entity';
import { User } from '../../../../src/database/entities/user.entity';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { DataSource, Repository } from 'typeorm';

describe('ProfileService', () => {
  let service: ProfileService;
  let usersService: jest.Mocked<UsersService>;
  let merchantsService: jest.Mocked<MerchantsService>;
  let imageRepository: jest.Mocked<Repository<Image>>;
  let userRepository: jest.Mocked<Repository<User>>;
  let dataSource: jest.Mocked<DataSource>;

  const mockCustomerUser: Partial<User> = {
    id: 1,
    email: 'customer@test.com',
    firstName: 'John',
    lastName: 'Doe',
    role: UserRole.CUSTOMER,
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProfileService,
        {
          provide: UsersService,
          useValue: {
            findOneByIdWithRelations: jest.fn(),
            findOneByEmail: jest.fn(),
            update: jest.fn(),
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
          },
        },
        {
          provide: FirebaseService,
          useValue: {
            deleteDriverDocument: jest.fn(),
            createDriverDocument: jest.fn(),
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
          provide: AreasService,
          useValue: {
            findOne: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Image),
          useValue: {
            find: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
            remove: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(Order),
          useValue: {
            find: jest.fn(),
            delete: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(DeliveryAssignment),
          useValue: {
            find: jest.fn(),
          },
        },
        {
          provide: getRepositoryToken(User),
          useValue: {
            findOne: jest.fn(),
            update: jest.fn(),
            delete: jest.fn(),
          },
        },
        {
          provide: DataSource,
          useValue: {
            createQueryRunner: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<ProfileService>(ProfileService);
    usersService = module.get(UsersService);
    merchantsService = module.get(MerchantsService);
    imageRepository = module.get(getRepositoryToken(Image));
    userRepository = module.get(getRepositoryToken(User));
    dataSource = module.get(DataSource);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getProfile', () => {
    it('يعيد بروفايل CUSTOMER', async () => {
      usersService.findOneByIdWithRelations.mockResolvedValue(
        mockCustomerUser as User,
      );
      imageRepository.find.mockResolvedValue([]);

      const result = await service.getProfile(mockCustomerUser as User);

      expect(result).toHaveProperty('email', 'customer@test.com');
      expect(result).not.toHaveProperty('password');
      expect(result).not.toHaveProperty('deletedAt');
    });

    it('يعيد بروفايل MERCHANT', async () => {
      merchantsService.findByUserId.mockResolvedValue({
        id: 10,
        restaurantName: 'Test Restaurant',
        user: {
          id: 2,
          email: 'merchant@test.com',
          firstName: 'Merchant',
          lastName: 'User',
          role: 'MERCHANT',
          images: [],
        },
      });

      const result = await service.getProfile({
        id: 2,
        role: UserRole.MERCHANT,
      } as User);

      expect(result).toHaveProperty('restaurantName', 'Test Restaurant');
      expect(result).toHaveProperty('id', 10); // merchant.id overwrites user.id
    });
  });

  describe('updateProfile', () => {
    it('يحدث بيانات المستخدم', async () => {
      userRepository.findOne.mockResolvedValue({
        id: 1,
        password: 'old_hashed',
      } as User);
      usersService.findOneByIdWithRelations.mockResolvedValue({
        ...mockCustomerUser,
        firstName: 'Updated',
      } as User);
      imageRepository.find.mockResolvedValue([]);

      const result = await service.updateProfile(
        mockCustomerUser as User,
        { firstName: 'Updated' } as any,
      );

      expect(result).toHaveProperty('firstName', 'Updated');
      expect(usersService.update).toHaveBeenCalledWith(1, {
        firstName: 'Updated',
      });
    });

    it('يرفض مستخدم غير موجود عند التحديث', async () => {
      userRepository.findOne.mockResolvedValue(null);

      await expect(
        service.updateProfile(mockCustomerUser as User, {} as any),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('deleteProfile', () => {
    it('يحذف حساب CUSTOMER', async () => {
      const queryRunner = {
        connect: jest.fn(),
        startTransaction: jest.fn(),
        commitTransaction: jest.fn(),
        rollbackTransaction: jest.fn(),
        release: jest.fn(),
        manager: {
          delete: jest.fn(),
          remove: jest.fn(),
        },
      };
      dataSource.createQueryRunner.mockReturnValue(queryRunner as any);
      usersService.findOneByIdWithRelations.mockResolvedValue(
        mockCustomerUser as User,
      );
      imageRepository.find.mockResolvedValue([]);

      const result = await service.deleteProfile(mockCustomerUser as User);

      expect(result).toEqual({ message: 'Account deleted successfully' });
      expect(queryRunner.commitTransaction).toHaveBeenCalled();
      expect(queryRunner.release).toHaveBeenCalled();
    });

    it('يرجع NotFoundException إذا المستخدم غير موجود', async () => {
      usersService.findOneByIdWithRelations.mockResolvedValue(null);

      await expect(service.deleteProfile({ id: 999 } as User)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});

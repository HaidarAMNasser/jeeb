import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { Repository, DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { UsersService } from '../../../../src/modules/users/users.service';
import { User } from '../../../../src/database/entities/user.entity';
import { Area } from '../../../../src/database/entities/area.entity';
import { Image } from '../../../../src/database/entities/image.entity';
import { Order } from '../../../../src/database/entities/order.entity';
import { Favorite } from '../../../../src/database/entities/favorite.entity';
import { DeliveryAssignment } from '../../../../src/database/entities/delivery-assignment.entity';
import { NotificationsService } from '../../../../src/modules/notifications/notifications.service';
import { SearchService } from '../../../../src/common/search';
import { MerchantsService } from '../../../../src/modules/merchants/merchants.service';
import { ImageProcessingService } from '../../../../src/common/image-processing/image-processing.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { NotificationChannel } from '../../../../src/common/enums/notification-channel.enum';

jest.mock('bcrypt');

describe('UsersService', () => {
  let service: UsersService;
  let userRepo: jest.Mocked<Repository<User>>;
  let areaRepo: jest.Mocked<Repository<Area>>;
  let imageRepo: jest.Mocked<Repository<Image>>;
  let orderRepo: jest.Mocked<Repository<Order>>;
  let favoriteRepo: jest.Mocked<Repository<Favorite>>;
  let deliveryAssignmentRepo: jest.Mocked<Repository<DeliveryAssignment>>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let searchService: jest.Mocked<SearchService>;
  let merchantsService: jest.Mocked<MerchantsService>;
  let imageProcessingService: jest.Mocked<ImageProcessingService>;
  let dataSource: jest.Mocked<DataSource>;

  const mockUser: Partial<User> = {
    id: 1,
    email: 'user@test.com',
    firstName: 'John',
    lastName: 'Doe',
    phone: '+963900000001',
    role: UserRole.CUSTOMER,
    countryId: 1,
    cityId: 1,
    areaId: 1,
    password: 'hashed',
    notificationChannel: NotificationChannel.FIREBASE,
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: getRepositoryToken(User), useValue: {
          create: jest.fn(),
          save: jest.fn(),
          findOne: jest.fn(),
          find: jest.fn(),
          preload: jest.fn(),
          createQueryBuilder: jest.fn(),
          softDelete: jest.fn(),
          restore: jest.fn(),
          remove: jest.fn(),
          update: jest.fn(),
        }},
        { provide: getRepositoryToken(Area), useValue: {
          findOne: jest.fn(),
        }},
        { provide: getRepositoryToken(Image), useValue: {
          find: jest.fn(),
          remove: jest.fn(),
        }},
        { provide: getRepositoryToken(Order), useValue: {
          delete: jest.fn(),
        }},
        { provide: getRepositoryToken(Favorite), useValue: {
          delete: jest.fn(),
        }},
        { provide: getRepositoryToken(DeliveryAssignment), useValue: {
          find: jest.fn(),
        }},
        { provide: NotificationsService, useValue: {
          sendWelcomeEmail: jest.fn(),
        }},
        { provide: SearchService, useValue: {
          buildSearchConditions: jest.fn(),
        }},
        { provide: MerchantsService, useValue: {
          updateMerchant: jest.fn(),
        }},
        { provide: ImageProcessingService, useValue: {
          deleteImages: jest.fn(),
        }},
        { provide: DataSource, useValue: {
          createQueryRunner: jest.fn(),
        }},
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    userRepo = module.get(getRepositoryToken(User));
    areaRepo = module.get(getRepositoryToken(Area));
    imageRepo = module.get(getRepositoryToken(Image));
    orderRepo = module.get(getRepositoryToken(Order));
    favoriteRepo = module.get(getRepositoryToken(Favorite));
    deliveryAssignmentRepo = module.get(getRepositoryToken(DeliveryAssignment));
    notificationsService = module.get(NotificationsService);
    searchService = module.get(SearchService);
    merchantsService = module.get(MerchantsService);
    imageProcessingService = module.get(ImageProcessingService);
    dataSource = module.get(DataSource);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createCustomer', () => {
    const dto = { email: 'new@test.com', password: 'plain123', firstName: 'New', lastName: 'User', phone: '+963' };

    it('should hash password and create customer', async () => {
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed_pswd');
      userRepo.create.mockReturnValue(mockUser as User);
      userRepo.save.mockResolvedValue(mockUser as User);

      const result = await service.createCustomer(dto as any);

      expect(bcrypt.hash).toHaveBeenCalledWith('plain123', 10);
      expect(userRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        ...dto,
        password: 'hashed_pswd',
        role: UserRole.CUSTOMER,
      }));
      expect(userRepo.save).toHaveBeenCalled();
      expect(result).toEqual(mockUser);
    });

    it('should send welcome email if channel is EMAIL', async () => {
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed');
      userRepo.create.mockReturnValue(mockUser as User);
      userRepo.save.mockResolvedValue({ ...mockUser, notificationChannel: NotificationChannel.EMAIL } as User);

      await service.createCustomer({ ...dto, notificationChannel: NotificationChannel.EMAIL } as any);

      expect(notificationsService.sendWelcomeEmail).toHaveBeenCalled();
    });
  });

  describe('createMerchant', () => {
    const dto = { email: 'merchant@test.com', password: 'plain123', firstName: 'M', lastName: 'N', phone: '+963' };

    it('should hash password and create merchant', async () => {
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed');
      userRepo.create.mockReturnValue(mockUser as User);
      userRepo.save.mockResolvedValue(mockUser as User);

      const result = await service.createMerchant(dto as any);

      expect(userRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        role: UserRole.MERCHANT,
      }));
      expect(result).toEqual(mockUser);
    });
  });

  describe('createDelivery', () => {
    const dto = { email: 'delivery@test.com', password: 'plain123', firstName: 'D', lastName: 'R', phone: '+963' };

    it('should hash password and create delivery', async () => {
      (bcrypt.hash as jest.Mock).mockResolvedValue('hashed');
      userRepo.create.mockReturnValue(mockUser as User);
      userRepo.save.mockResolvedValue(mockUser as User);

      const result = await service.createDelivery(dto as any);

      expect(userRepo.create).toHaveBeenCalledWith(expect.objectContaining({
        role: UserRole.DELIVERY,
      }));
      expect(result).toEqual(mockUser);
    });
  });

  describe('findAllCustomers', () => {
    it('should build query and return paginated results', async () => {
      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[mockUser], 1]),
      };
      userRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);

      const result = await service.findAllCustomers({ page: 1, limit: 10 });

      expect(mockQueryBuilder.where).toHaveBeenCalledWith('user.role = :role', { role: UserRole.CUSTOMER });
      expect(result).toEqual({ data: [mockUser], total: 1, page: 1, limit: 10 });
    });
  });

  describe('findOneById', () => {
    it('should find user by id', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);

      const result = await service.findOneById(1);

      expect(userRepo.findOne).toHaveBeenCalledWith({ where: { id: 1 } });
      expect(result).toEqual(mockUser);
    });

    it('should return null when not found', async () => {
      userRepo.findOne.mockResolvedValue(null);
      expect(await service.findOneById(999)).toBeNull();
    });
  });

  describe('findOneByIdWithRelations', () => {
    it('should find user with relations', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);

      const result = await service.findOneByIdWithRelations(1);

      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { id: 1 },
        relations: ['country', 'city', 'area', 'images', 'merchant'],
      });
      expect(result).toEqual(mockUser);
    });
  });

  describe('updateCustomer', () => {
    it('should update customer fields', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);
      userRepo.save.mockResolvedValue({ ...mockUser, firstName: 'Updated' } as User);

      const result = await service.updateCustomer(1, { firstName: 'Updated' } as any);

      expect(userRepo.save).toHaveBeenCalled();
      expect(result.firstName).toBe('Updated');
    });

    it('should throw NotFoundException when user not found', async () => {
      userRepo.findOne.mockResolvedValue(null);
      await expect(service.updateCustomer(999, {} as any)).rejects.toThrow(NotFoundException);
    });
  });

  describe('update', () => {
    it('should preload and save user', async () => {
      userRepo.preload.mockResolvedValue(mockUser as User);
      userRepo.save.mockResolvedValue(mockUser as User);

      const result = await service.update(1, { firstName: 'Updated' });

      expect(userRepo.preload).toHaveBeenCalledWith({ id: 1, firstName: 'Updated' });
      expect(result).toEqual(mockUser);
    });

    it('should return null when preload fails', async () => {
      userRepo.preload.mockResolvedValue(null);
      expect(await service.update(999, {} as any)).toBeNull();
    });
  });

  describe('softDelete', () => {
    it('should throw NotFoundException when user not found', async () => {
      userRepo.findOne.mockResolvedValue(null);
      await expect(service.softDelete(999)).rejects.toThrow(NotFoundException);
    });
  });

  describe('findOneByEmail', () => {
    it('should find user by email', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);
      expect(await service.findOneByEmail('user@test.com')).toEqual(mockUser);
    });
  });

  describe('findOneByPhone', () => {
    it('should find user by phone', async () => {
      userRepo.findOne.mockResolvedValue(mockUser as User);
      expect(await service.findOneByPhone('+963900000001')).toEqual(mockUser);
    });
  });
});

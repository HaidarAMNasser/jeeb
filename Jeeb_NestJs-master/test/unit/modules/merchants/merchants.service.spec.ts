import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { MerchantsService } from '../../../../src/modules/merchants/merchants.service';
import { Merchant } from '../../../../src/database/entities/merchant.entity';
import { User } from '../../../../src/database/entities/user.entity';
import { Image } from '../../../../src/database/entities/image.entity';
import { SearchService } from '../../../../src/common/search';
import { GoogleDirectionsService } from '../../../../src/modules/distance/google-directions.service';
import { SettingsService } from '../../../../src/modules/settings/settings.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { MerchantType } from '../../../../src/common/enums/merchant-type.enum';
import { ErrorCodes } from '../../../../src/common/constants/error-codes';

describe('MerchantsService', () => {
  let service: MerchantsService;
  let merchantRepo: any;
  let userRepo: any;
  let imageRepo: any;
  let searchService: any;
  let googleDirectionsService: any;
  let settingsService: any;

  const mockMerchant = {
    id: 1,
    userId: 1,
    restaurantName: 'Test Restaurant',
    description: 'A test merchant',
    isOpen: false,
    isActive: true,
    hidePhoneNumber: false,
    type: MerchantType.RESTAURANT,
    user: { id: 1, role: UserRole.MERCHANT, location: { lat: 25.2, lng: 55.3 } },
  };

  beforeEach(async () => {
    merchantRepo = {
      create: jest.fn(),
      save: jest.fn(),
      findOne: jest.fn(),
      createQueryBuilder: jest.fn(),
      remove: jest.fn(),
    };
    userRepo = {
      findOne: jest.fn(),
      update: jest.fn(),
    };
    imageRepo = {
      find: jest.fn().mockResolvedValue([]),
    };
    searchService = {
      buildSearchConditions: jest.fn(),
    };
    googleDirectionsService = {
      getMultipleRoutes: jest.fn(),
    };
    settingsService = {
      getSettingByKey: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MerchantsService,
        { provide: getRepositoryToken(Merchant), useValue: merchantRepo },
        { provide: getRepositoryToken(User), useValue: userRepo },
        { provide: getRepositoryToken(Image), useValue: imageRepo },
        { provide: SearchService, useValue: searchService },
        { provide: GoogleDirectionsService, useValue: googleDirectionsService },
        { provide: SettingsService, useValue: settingsService },
      ],
    }).compile();

    service = module.get<MerchantsService>(MerchantsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createMerchantProfile', () => {
    it('should create a new merchant profile', async () => {
      const data = { restaurantName: 'New Restaurant', description: 'Nice place', type: MerchantType.RESTAURANT };
      const saved = { id: 2, userId: 1, ...data, isOpen: false };
      merchantRepo.create.mockReturnValue(saved);
      merchantRepo.save.mockResolvedValue(saved);

      const result = await service.createMerchantProfile(1, data);

      expect(merchantRepo.create).toHaveBeenCalledWith({
        userId: 1,
        restaurantName: 'New Restaurant',
        description: 'Nice place',
        isOpen: false,
        type: MerchantType.RESTAURANT,
      });
      expect(merchantRepo.save).toHaveBeenCalledWith(saved);
      expect(result).toEqual(saved);
    });
  });

  describe('findByUserId', () => {
    it('should return merchant with relations', async () => {
      merchantRepo.findOne.mockResolvedValue(mockMerchant);

      const result = await service.findByUserId(1);

      expect(merchantRepo.findOne).toHaveBeenCalledWith({
        where: { userId: 1 },
        relations: ['user', 'user.country', 'user.city'],
      });
      expect(result).toEqual(mockMerchant);
    });

    it('should return null when not found', async () => {
      merchantRepo.findOne.mockResolvedValue(null);

      const result = await service.findByUserId(999);
      expect(result).toBeNull();
    });
  });

  describe('findById', () => {
    it('should return merchant by id', async () => {
      merchantRepo.findOne.mockResolvedValue(mockMerchant);

      const result = await service.findById(1);

      expect(merchantRepo.findOne).toHaveBeenCalledWith({
        where: { id: 1 },
        relations: ['user', 'user.country', 'user.city'],
      });
      expect(result).toEqual(mockMerchant);
    });

    it('should throw NotFoundException when not found', async () => {
      merchantRepo.findOne.mockResolvedValue(null);

      await expect(service.findById(999)).rejects.toThrow(NotFoundException);
    });
  });

  describe('findAllMerchants', () => {
    it('should return paginated merchants', async () => {
      const qb = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[mockMerchant], 1]),
      };
      merchantRepo.createQueryBuilder.mockReturnValue(qb);
      userRepo.findOne.mockResolvedValue(null);

      const result = await service.findAllMerchants({ page: 1, limit: 10 }, { id: 1, role: UserRole.CUSTOMER });

      expect(result.data).toHaveLength(1);
      expect(result.pagination.total).toBe(1);
    });
  });

  describe('updateMerchant', () => {
    it('should update merchant fields', async () => {
      merchantRepo.findOne.mockResolvedValue({ ...mockMerchant });
      merchantRepo.save.mockImplementation((m) => Promise.resolve(m));

      const result = await service.updateMerchant(1, { restaurantName: 'Updated' }, UserRole.ADMIN);

      expect(result.restaurantName).toBe('Updated');
    });

    it('should throw NotFoundException when merchant not found', async () => {
      merchantRepo.findOne.mockResolvedValue(null);

      await expect(
        service.updateMerchant(999, { restaurantName: 'X' }, UserRole.ADMIN),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException when non-admin updates isActive', async () => {
      merchantRepo.findOne.mockResolvedValue({ ...mockMerchant });

      await expect(
        service.updateMerchant(1, { isActive: false }, UserRole.MERCHANT),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow admin to update isActive and hidePhoneNumber', async () => {
      merchantRepo.findOne.mockResolvedValue({ ...mockMerchant });
      merchantRepo.save.mockImplementation((m) => Promise.resolve(m));

      const result = await service.updateMerchant(
        1,
        { isActive: false, hidePhoneNumber: true },
        UserRole.ADMIN,
      );

      expect(result).toBeDefined();
    });
  });

  describe('toggleOpenStatus', () => {
    it('should toggle isOpen from false to true', async () => {
      merchantRepo.findOne.mockResolvedValue({ ...mockMerchant, isOpen: false });
      merchantRepo.save.mockImplementation((m) => Promise.resolve(m));

      const result = await service.toggleOpenStatus(1);

      expect(result.isOpen).toBe(true);
    });

    it('should toggle isOpen from true to false', async () => {
      merchantRepo.findOne.mockResolvedValue({ ...mockMerchant, isOpen: true });
      merchantRepo.save.mockImplementation((m) => Promise.resolve(m));

      const result = await service.toggleOpenStatus(1);

      expect(result.isOpen).toBe(false);
    });

    it('should throw NotFoundException when merchant not found', async () => {
      merchantRepo.findOne.mockResolvedValue(null);

      await expect(service.toggleOpenStatus(999)).rejects.toThrow(NotFoundException);
    });
  });

  describe('deleteMerchant', () => {
    it('should delete merchant', async () => {
      merchantRepo.findOne.mockResolvedValue(mockMerchant);
      merchantRepo.remove.mockResolvedValue(undefined);

      await service.deleteMerchant(1);

      expect(merchantRepo.remove).toHaveBeenCalledWith(mockMerchant);
    });

    it('should throw NotFoundException when not found', async () => {
      merchantRepo.findOne.mockResolvedValue(null);

      await expect(service.deleteMerchant(999)).rejects.toThrow(NotFoundException);
    });
  });
});

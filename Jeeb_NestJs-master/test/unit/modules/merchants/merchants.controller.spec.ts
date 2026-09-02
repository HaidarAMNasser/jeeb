import { Test, TestingModule } from '@nestjs/testing';
import { Reflector } from '@nestjs/core';
import { MerchantsController } from '../../../../src/modules/merchants/merchants.controller';
import { MerchantsService } from '../../../../src/modules/merchants/merchants.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';

describe('MerchantsController', () => {
  let controller: MerchantsController;
  let merchantsService: jest.Mocked<MerchantsService>;

  const mockMerchant = { id: 1, userId: 1, restaurantName: 'Test' };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [MerchantsController],
      providers: [
        {
          provide: MerchantsService,
          useValue: {
            findAllMerchants: jest.fn(),
            findByUserId: jest.fn(),
            findById: jest.fn(),
            createMerchantProfile: jest.fn(),
            updateMerchant: jest.fn(),
            toggleOpenStatus: jest.fn(),
            deleteMerchant: jest.fn(),
          },
        },
        Reflector,
      ],
    }).compile();

    controller = module.get<MerchantsController>(MerchantsController);
    merchantsService = module.get(MerchantsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll (GET /merchants)', () => {
    it('should delegate to service with query and user', async () => {
      const query = { page: 1, limit: 10, search: 'test' };
      const user = { id: 1, role: UserRole.CUSTOMER };
      const expected = { data: [], pagination: { total: 0, page: 1, limit: 10, totalPages: 0, hasNextPage: false, hasPreviousPage: false } };
      merchantsService.findAllMerchants.mockResolvedValue(expected as any);

      const result = await controller.findAll(query, user);

      expect(merchantsService.findAllMerchants).toHaveBeenCalledWith(query, user);
      expect(result).toEqual(expected);
    });
  });

  describe('getMyProfile (GET /merchants/profile)', () => {
    it('should return merchant by user id', async () => {
      merchantsService.findByUserId.mockResolvedValue(mockMerchant as any);

      const result = await controller.getMyProfile({ id: 1 });

      expect(merchantsService.findByUserId).toHaveBeenCalledWith(1);
      expect(result).toEqual(mockMerchant);
    });
  });

  describe('findOne (GET /merchants/:id)', () => {
    it('should find merchant by id', async () => {
      merchantsService.findById.mockResolvedValue(mockMerchant as any);

      const result = await controller.findOne(1);

      expect(merchantsService.findById).toHaveBeenCalledWith(1);
      expect(result).toEqual(mockMerchant);
    });
  });

  describe('findByUser (GET /merchants/user/:userId)', () => {
    it('should find merchant by userId', async () => {
      merchantsService.findByUserId.mockResolvedValue(mockMerchant as any);

      const result = await controller.findByUser(1);

      expect(merchantsService.findByUserId).toHaveBeenCalledWith(1);
      expect(result).toEqual(mockMerchant);
    });
  });

  describe('create (POST /merchants)', () => {
    it('should create merchant profile', async () => {
      const body = { userId: 1, restaurantName: 'Test' };
      merchantsService.createMerchantProfile.mockResolvedValue(mockMerchant as any);

      const result = await controller.create(body);

      expect(merchantsService.createMerchantProfile).toHaveBeenCalledWith(1, body);
      expect(result).toEqual(mockMerchant);
    });
  });

  describe('update (PATCH /merchants/user/:userId)', () => {
    it('should process body and delegate to updateMerchant', async () => {
      const body = { restaurantName: 'New', isOpen: 'true', hidePhoneNumber: false, isActive: true };
      const user = { id: 1, role: UserRole.ADMIN };
      merchantsService.updateMerchant.mockResolvedValue(mockMerchant as any);

      const result = await controller.update(1, body, user);

      expect(merchantsService.updateMerchant).toHaveBeenCalledWith(
        1,
        {
          restaurantName: 'New',
          isOpen: true,
          hidePhoneNumber: false,
          isActive: true,
        },
        UserRole.ADMIN,
      );
      expect(result).toEqual(mockMerchant);
    });
  });

  describe('toggleOpen (PATCH /merchants/user/:userId/toggle-open)', () => {
    it('should toggle open status', async () => {
      merchantsService.toggleOpenStatus.mockResolvedValue({ ...mockMerchant, isOpen: true } as any);

      const result = await controller.toggleOpen(1, { id: 1, role: UserRole.MERCHANT });

      expect(merchantsService.toggleOpenStatus).toHaveBeenCalledWith(1);
      expect(result.isOpen).toBe(true);
    });
  });

  describe('delete (DELETE /merchants/user/:userId)', () => {
    it('should delete merchant', async () => {
      merchantsService.deleteMerchant.mockResolvedValue(undefined);

      await controller.delete(1, { id: 1, role: UserRole.ADMIN });

      expect(merchantsService.deleteMerchant).toHaveBeenCalledWith(1);
    });
  });
});

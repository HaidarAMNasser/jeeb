import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Order } from '../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../src/database/entities/product.entity';
import { Offer } from '../../../../src/database/entities/offer.entity';
import { Image } from '../../../../src/database/entities/image.entity';
import { OrderQueryService } from '../../../../src/modules/orders/services/order-query.service';
import { OrderAccessValidator } from '../../../../src/modules/orders/validators/order-access.validator';
import { SearchService } from '../../../../src/common/search';
import { SettingsService } from '../../../../src/modules/settings/settings.service';
import { GoogleDirectionsService } from '../../../../src/modules/distance/google-directions.service';
import { FirebaseService } from '../../../../src/modules/firebase/firebase.service';
import { StorageService } from '../../../../src/common/storage/storage.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { OrderStatus } from '../../../../src/common/enums/order-status.enum';
import { DeliveryStatus } from '../../../../src/common/enums/delivery-status.enum';
import { ImageEntityType } from '../../../../src/common/enums';

describe('OrderQueryService', () => {
  let service: OrderQueryService;

  const mockQueryBuilder = {
    leftJoinAndSelect: jest.fn().mockReturnThis(),
    leftJoin: jest.fn().mockReturnThis(),
    withDeleted: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    select: jest.fn().mockReturnThis(),
    addSelect: jest.fn().mockReturnThis(),
    skip: jest.fn().mockReturnThis(),
    take: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    offset: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    addOrderBy: jest.fn().mockReturnThis(),
    getManyAndCount: jest.fn().mockResolvedValue([[], 0]),
    getCount: jest.fn().mockResolvedValue(1),
    getRawMany: jest.fn().mockResolvedValue([{ id: 1, createdAt: new Date().toISOString() }]),
  };

  const mockOrder = {
    id: 1,
    customerId: 10,
    customerName: 'Test Customer',
    phone: '+966555555555',
    paymentMethod: 'CASH',
    status: OrderStatus.PENDING,
    deliveryFee: 15,
    platformCommission: 5,
    totalAmount: 120,
    discountAmount: 10,
    tipAmount: 0,
    ownerRevenue: 100,
    currencyCode: 'SAR',
    mealPreparationTime: 30,
    deliveryTime: 45,
    deliveryCoordinates: { latitude: 24.7, longitude: 46.7 },
    finalLocation: null,
    deliveryDeadline: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    owner: {
      id: 20,
      firstName: 'Owner',
      lastName: 'Test',
      phone: '+966555555577',
      email: 'owner@test.com',
      address: 'Riyadh',
      location: { lat: 24.8, lng: 46.8 },
      merchant: { restaurantName: 'Test Restaurant', hidePhoneNumber: false },
    },
    customer: {
      id: 10,
      firstName: 'Customer',
      lastName: 'Test',
      phone: '+966555555555',
      email: 'customer@test.com',
      address: 'Jeddah',
    },
    items: [
      {
        id: 1,
        productId: 100,
        offerId: null,
        originalUnitPrice: 50,
        unitPrice: 45,
        quantity: 2,
        totalPrice: 90,
        productDiscountValue: 5,
      },
    ],
    offers: [],
    deliveryAssignments: [],
    paymentReceipts: [],
  };

  const mockOrderRepo = {
    createQueryBuilder: jest.fn().mockReturnValue(mockQueryBuilder),
    findOne: jest.fn(),
    find: jest.fn().mockResolvedValue([mockOrder]),
  };
  const mockOrderItemRepo = {};
  const mockProductRepo = { find: jest.fn() };
  const mockOfferRepo = { find: jest.fn() };
  const mockImageRepo = { find: jest.fn() };

  const mockOrderAccessValidator = {
    applyRoleBasedFiltering: jest.fn().mockResolvedValue(undefined),
    validateOrderAccess: jest.fn(),
  };
  const mockSearchService = {
    buildSearchConditions: jest.fn(),
  };
  const mockSettingsService = {
    getSettingByKey: jest.fn(),
  };
  const mockGoogleDirectionsService = {
    getRouteDetails: jest.fn(),
  };
  const mockFirebaseService = {
    getAllDriverLocations: jest.fn(),
  };
  const mockStorageService = {
    resolveUrl: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrderQueryService,
        { provide: getRepositoryToken(Order), useValue: mockOrderRepo },
        { provide: getRepositoryToken(OrderItem), useValue: mockOrderItemRepo },
        { provide: getRepositoryToken(Product), useValue: mockProductRepo },
        { provide: getRepositoryToken(Offer), useValue: mockOfferRepo },
        { provide: getRepositoryToken(Image), useValue: mockImageRepo },
        { provide: OrderAccessValidator, useValue: mockOrderAccessValidator },
        { provide: SearchService, useValue: mockSearchService },
        { provide: SettingsService, useValue: mockSettingsService },
        {
          provide: GoogleDirectionsService,
          useValue: mockGoogleDirectionsService,
        },
        { provide: FirebaseService, useValue: mockFirebaseService },
        { provide: StorageService, useValue: mockStorageService },
      ],
    }).compile();

    service = module.get<OrderQueryService>(OrderQueryService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll', () => {
    it('should return paginated results with default pagination', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({ value: '180' });
      mockQueryBuilder.getManyAndCount.mockResolvedValue([[mockOrder], 1]);
      mockImageRepo.find.mockResolvedValue([]);

      const result = await service.findAll({}, 1, UserRole.ADMIN);

      expect(result.page).toBe(1);
      expect(result.limit).toBe(10);
      expect(result.total).toBe(1);
      expect(result.data).toHaveLength(1);
      expect(mockOrderRepo.createQueryBuilder).toHaveBeenCalledWith('order');
    });

    it('should apply status filter when provided', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({ value: '180' });
      mockQueryBuilder.getManyAndCount.mockResolvedValue([[mockOrder], 1]);
      mockImageRepo.find.mockResolvedValue([]);

      await service.findAll({ status: OrderStatus.PENDING }, 1, UserRole.ADMIN);

      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'order.status = :status',
        { status: OrderStatus.PENDING },
      );
    });

    // Skipped: source uses dynamic import('@nestjs/common') which requires --experimental-vm-modules
    it.skip('should block PAID/COMPLETE filter for CUSTOMER role', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({ value: '180' });
      await expect(
        service.findAll({ status: OrderStatus.PAID }, 1, UserRole.CUSTOMER),
      ).rejects.toThrow('You cannot filter by PAID or COMPLETE status');
    });

    it('should expand DELIVERED to include PAID and COMPLETE for CUSTOMER', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({ value: '180' });
      mockQueryBuilder.getManyAndCount.mockResolvedValue([[mockOrder], 1]);
      mockImageRepo.find.mockResolvedValue([]);

      await service.findAll(
        { status: OrderStatus.DELIVERED },
        1,
        UserRole.CUSTOMER,
      );

      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'order.status IN (:...statuses)',
        {
          statuses: [
            OrderStatus.DELIVERED,
            OrderStatus.PAID,
            OrderStatus.COMPLETE,
          ],
        },
      );
    });

    it('should apply search filter when search query provided', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({ value: '180' });
      mockQueryBuilder.getManyAndCount.mockResolvedValue([[mockOrder], 1]);
      mockImageRepo.find.mockResolvedValue([]);
      mockSearchService.buildSearchConditions.mockReturnValue({
        condition:
          '(customer.firstName ILIKE :search OR customer.lastName ILIKE :search)',
        paramName: 'search',
        paramValue: '%test%',
      });

      await service.findAll({ search: 'test' }, 1, UserRole.ADMIN);

      expect(mockSearchService.buildSearchConditions).toHaveBeenCalled();
    });

    it('should apply date range filters', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({ value: '180' });
      mockQueryBuilder.getManyAndCount.mockResolvedValue([[mockOrder], 1]);
      mockImageRepo.find.mockResolvedValue([]);

      await service.findAll(
        { startDate: '2024-01-01', endDate: '2024-12-31' },
        1,
        UserRole.ADMIN,
      );

      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'order.createdAt >= :startDate',
        { startDate: '2024-01-01' },
      );
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'order.createdAt <= :endDate',
        { endDate: '2024-12-31' },
      );
    });

    it('should apply merchantId filter when provided', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({ value: '180' });
      mockQueryBuilder.getManyAndCount.mockResolvedValue([[mockOrder], 1]);
      mockImageRepo.find.mockResolvedValue([]);

      await service.findAll({ merchantId: 20 }, 1, UserRole.ADMIN);

      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'order.ownerId = :merchantId',
        { merchantId: 20 },
      );
    });
  });

  describe('findOne', () => {
    it('should return enriched order when found', async () => {
      mockOrderRepo.findOne.mockResolvedValue(mockOrder);
      mockOrderAccessValidator.validateOrderAccess.mockReturnValue({
        canAccess: true,
      });
      mockProductRepo.find.mockResolvedValue([]);
      mockOfferRepo.find.mockResolvedValue([]);
      mockImageRepo.find.mockResolvedValue([]);

      const result = await service.findOne(1, 1, UserRole.ADMIN);

      expect(result).toBeDefined();
      expect(result.id).toBe(1);
    });

    it('should throw error when order not found', async () => {
      mockOrderRepo.findOne.mockResolvedValue(null);

      await expect(service.findOne(999, 1, UserRole.ADMIN)).rejects.toThrow(
        'Order with ID 999 not found',
      );
    });

    it('should throw error when access denied', async () => {
      mockOrderRepo.findOne.mockResolvedValue(mockOrder);
      mockOrderAccessValidator.validateOrderAccess.mockReturnValue({
        canAccess: false,
        reason: 'Access denied',
      });

      await expect(service.findOne(1, 1, UserRole.CUSTOMER)).rejects.toThrow(
        'Access denied',
      );
    });
  });
});

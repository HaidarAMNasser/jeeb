import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { OrderManagementService } from '../../../../src/modules/orders/services/order-management.service';
import { Order } from '../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../src/database/entities/product.entity';
import { Offer } from '../../../../src/database/entities/offer.entity';
import { Image } from '../../../../src/database/entities/image.entity';
import { DeliveryAssignment } from '../../../../src/database/entities/delivery-assignment.entity';
import { OrderQueryService } from '../../../../src/modules/orders/services/order-query.service';
import { OrderActionsService } from '../../../../src/modules/orders/services/order-actions.service';
import { NotificationsService } from '../../../../src/modules/notifications/notifications.service';
import { SettingsService } from '../../../../src/modules/settings/settings.service';
import { GoogleDirectionsService } from '../../../../src/modules/distance/google-directions.service';
import { FirebaseService } from '../../../../src/modules/firebase/firebase.service';
import { StorageService } from '../../../../src/common/storage/storage.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { OrderStatus } from '../../../../src/common/enums/order-status.enum';
import { DeliveryStatus } from '../../../../src/common/enums/delivery-status.enum';
import { ImageEntityType } from '../../../../src/common/enums';

describe('OrderManagementService', () => {
  let service: OrderManagementService;

  const mockOrderRepo = {
    findOne: jest.fn(),
    find: jest.fn(),
  };

  const mockOrderItemRepo = {};
  const mockProductRepo = { find: jest.fn() };
  const mockOfferRepo = { find: jest.fn() };
  const mockImageRepo = { find: jest.fn() };
  const mockDeliveryAssignmentRepo = {};

  const mockOrderQueryService = {
    findAll: jest.fn(),
  };

  const mockOrderActionsService = {
    confirmOrder: jest.fn(),
    rejectOrder: jest.fn(),
    updateOrderStatus: jest.fn(),
    cancelOrder: jest.fn(),
  };

  const mockNotificationsService = {};
  const mockSettingsService = {
    getSettingByKey: jest.fn(),
  };
  const mockStorageService = {
    resolveUrl: jest.fn(),
  };
  const mockGoogleDirectionsService = {
    getRouteDetails: jest.fn(),
  };
  const mockFirebaseService = {
    getAllDriverLocations: jest.fn(),
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
        commissionRate: 0,
      },
    ],
    offers: [],
    deliveryAssignments: [],
    paymentReceipts: [],
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrderManagementService,
        { provide: getRepositoryToken(Order), useValue: mockOrderRepo },
        { provide: getRepositoryToken(OrderItem), useValue: mockOrderItemRepo },
        { provide: getRepositoryToken(Product), useValue: mockProductRepo },
        { provide: getRepositoryToken(Offer), useValue: mockOfferRepo },
        { provide: getRepositoryToken(Image), useValue: mockImageRepo },
        {
          provide: getRepositoryToken(DeliveryAssignment),
          useValue: mockDeliveryAssignmentRepo,
        },
        { provide: OrderQueryService, useValue: mockOrderQueryService },
        { provide: OrderActionsService, useValue: mockOrderActionsService },
        { provide: NotificationsService, useValue: mockNotificationsService },
        { provide: SettingsService, useValue: mockSettingsService },
        { provide: StorageService, useValue: mockStorageService },
        {
          provide: GoogleDirectionsService,
          useValue: mockGoogleDirectionsService,
        },
        { provide: FirebaseService, useValue: mockFirebaseService },
      ],
    }).compile();

    service = module.get<OrderManagementService>(OrderManagementService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll', () => {
    it('should delegate to orderQueryService.findAll', async () => {
      const query = { page: 1, limit: 10 };
      const result = { data: [], total: 0, page: 1, limit: 10 };
      mockOrderQueryService.findAll.mockResolvedValue(result);

      const output = await service.findAll(query, 1, UserRole.ADMIN);

      expect(mockOrderQueryService.findAll).toHaveBeenCalledWith(
        query,
        1,
        UserRole.ADMIN,
        undefined,
      );
      expect(output).toEqual(result);
    });

    it('should pass status filter when provided', async () => {
      const query = { page: 1, limit: 10, status: OrderStatus.PENDING };
      mockOrderQueryService.findAll.mockResolvedValue({ data: [], total: 0 });

      await service.findAll(query, 1, UserRole.MERCHANT, OrderStatus.PENDING);

      expect(mockOrderQueryService.findAll).toHaveBeenCalledWith(
        query,
        1,
        UserRole.MERCHANT,
        OrderStatus.PENDING,
      );
    });
  });

  describe('findOne', () => {
    it('should throw NotFoundException when order not found', async () => {
      mockOrderRepo.findOne.mockResolvedValue(null);

      await expect(service.findOne(999, 1, UserRole.ADMIN)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should return enriched order for ADMIN role', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({
        value: '180',
      });
      mockOrderRepo.findOne.mockResolvedValue({ ...mockOrder, offers: [] });
      mockProductRepo.find.mockResolvedValue([
        { id: 100, merchantId: 20, name: 'Product', price: 50 },
      ]);
      mockOfferRepo.find.mockResolvedValue([]);
      mockImageRepo.find.mockResolvedValue([]);
      mockStorageService.resolveUrl.mockReturnValue(
        'https://cdn.example.com/img.jpg',
      );

      const result = await service.findOne(1, 1, UserRole.ADMIN);

      expect(result).toBeDefined();
      expect(result.id).toBe(1);
      expect(result.status).toBe(OrderStatus.PENDING);
      expect(mockSettingsService.getSettingByKey).toHaveBeenCalledWith(
        'driverRequestTimeoutSeconds',
      );
    });

    it('should hide owner phone when merchant has hidePhoneNumber=true for non-admin', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({
        value: '180',
      });
      const orderWithHiddenPhone = {
        ...mockOrder,
        owner: {
          ...mockOrder.owner,
          merchant: { restaurantName: 'Test', hidePhoneNumber: true },
        },
      };
      mockOrderRepo.findOne.mockResolvedValue(orderWithHiddenPhone);
      mockProductRepo.find.mockResolvedValue([]);
      mockOfferRepo.find.mockResolvedValue([]);
      mockImageRepo.find.mockResolvedValue([]);

      const result = await service.findOne(1, 1, UserRole.CUSTOMER);

      expect(result.owner.phone).toBeUndefined();
    });

    it('should include remaining time for DELIVERY role with SEARCHING status', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({
        value: '180',
      });
      const searchingOrder = {
        ...mockOrder,
        status: OrderStatus.SEARCHING,
        deliveryAssignments: [
          {
            deliveryId: 30,
            status: DeliveryStatus.ACCEPTED,
            assignedAt: new Date(Date.now() - 30000),
            delivery: {
              id: 30,
              firstName: 'Driver',
              lastName: 'Test',
              phone: '+966555555533',
              email: 'driver@test.com',
              address: 'Riyadh',
            },
          },
        ],
      };
      mockOrderRepo.findOne.mockResolvedValue(searchingOrder);
      mockProductRepo.find.mockResolvedValue([]);
      mockOfferRepo.find.mockResolvedValue([]);
      mockImageRepo.find.mockResolvedValue([]);

      const result = await service.findOne(1, 30, UserRole.DELIVERY);

      expect(result.remainingTime).toBeDefined();
      expect(result.remainingTime.minutes).toBeGreaterThanOrEqual(0);
      expect(result.deliveryId).toBe(30);
    });

    it('should calculate estimated route when coordinates exist', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({
        value: '180',
      });
      mockOrderRepo.findOne.mockResolvedValue(mockOrder);
      mockProductRepo.find.mockResolvedValue([]);
      mockOfferRepo.find.mockResolvedValue([]);
      mockImageRepo.find.mockResolvedValue([]);
      mockGoogleDirectionsService.getRouteDetails.mockResolvedValue({
        distanceMeters: 5000,
        durationSeconds: 600,
      });
      mockStorageService.resolveUrl.mockReturnValue(
        'https://cdn.example.com/img.jpg',
      );

      const result = await service.findOne(1, 1, UserRole.ADMIN);

      expect(result.estimatedRoute).toBeDefined();
      expect(result.estimatedRoute.merchantToCustomer.distance).toBe(5000);
    });

    it('should include receipts for ADMIN and DELIVERY roles', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({
        value: '180',
      });
      const orderWithReceipts = {
        ...mockOrder,
        paymentReceipts: [
          {
            id: 1,
            imageId: 50,
            image: {
              id: 50,
              url: 'receipt.jpg',
              thumbnailUrl: 'thumb.jpg',
              mobileUrl: 'mobile.jpg',
            },
          },
        ],
      };
      mockOrderRepo.findOne.mockResolvedValue(orderWithReceipts);
      mockProductRepo.find.mockResolvedValue([]);
      mockOfferRepo.find.mockResolvedValue([]);
      mockImageRepo.find.mockResolvedValue([]);
      mockStorageService.resolveUrl.mockReturnValue(
        'https://cdn.example.com/img.jpg',
      );

      const result = await service.findOne(1, 1, UserRole.ADMIN);

      expect(result.receipts).toBeDefined();
      expect(result.receipts).toHaveLength(1);
    });

    it('should handle driver-to-customer route for PICKED_UP status', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({
        value: '180',
      });
      const pickedOrder = {
        ...mockOrder,
        status: OrderStatus.PICKED_UP,
        deliveryAssignments: [
          {
            deliveryId: 30,
            status: DeliveryStatus.ACCEPTED,
            assignedAt: new Date(),
            delivery: {
              id: 30,
              firstName: 'Driver',
              lastName: 'Test',
              phone: '+966555555533',
              email: 'driver@test.com',
              address: '',
            },
          },
        ],
      };
      mockOrderRepo.findOne.mockResolvedValue(pickedOrder);
      mockProductRepo.find.mockResolvedValue([]);
      mockOfferRepo.find.mockResolvedValue([]);
      mockImageRepo.find.mockResolvedValue([]);
      mockGoogleDirectionsService.getRouteDetails.mockResolvedValue({
        distanceMeters: 3000,
        durationSeconds: 400,
      });
      mockFirebaseService.getAllDriverLocations.mockResolvedValue(
        new Map([[30, { currentLat: 24.9, currentLng: 46.9 }]]),
      );
      mockStorageService.resolveUrl.mockReturnValue(
        'https://cdn.example.com/img.jpg',
      );

      const result = await service.findOne(1, 1, UserRole.ADMIN);

      expect(result.estimatedRoute.driverToMerchant).toBeDefined();
      expect(result.estimatedRoute.driverToCustomer).toBeDefined();
    });

    it('should handle errors in estimatedRoute gracefully', async () => {
      mockSettingsService.getSettingByKey.mockResolvedValue({
        value: '180',
      });
      mockOrderRepo.findOne.mockResolvedValue(mockOrder);
      mockProductRepo.find.mockResolvedValue([]);
      mockOfferRepo.find.mockResolvedValue([]);
      mockImageRepo.find.mockResolvedValue([]);
      mockGoogleDirectionsService.getRouteDetails.mockRejectedValue(
        new Error('API error'),
      );
      mockStorageService.resolveUrl.mockReturnValue(
        'https://cdn.example.com/img.jpg',
      );

      const result = await service.findOne(1, 1, UserRole.ADMIN);

      expect(result.estimatedRoute).toBeUndefined();
    });
  });

  describe('confirmOrder', () => {
    it('should delegate to orderActionsService.confirmOrder', async () => {
      const mockConfirmed = { id: 1, status: OrderStatus.CONFIRMED };
      mockOrderActionsService.confirmOrder.mockResolvedValue(mockConfirmed);

      const result = await service.confirmOrder(1, 1, UserRole.ADMIN);

      expect(mockOrderActionsService.confirmOrder).toHaveBeenCalledWith(
        1,
        1,
        UserRole.ADMIN,
      );
      expect(result).toEqual(mockConfirmed);
    });
  });

  describe('rejectOrder', () => {
    it('should delegate to orderActionsService.rejectOrder', async () => {
      const mockRejected = { id: 1, status: OrderStatus.REJECTED };
      mockOrderActionsService.rejectOrder.mockResolvedValue(mockRejected);

      const result = await service.rejectOrder(
        1,
        1,
        UserRole.MERCHANT,
        'Out of stock',
      );

      expect(mockOrderActionsService.rejectOrder).toHaveBeenCalledWith(
        1,
        1,
        UserRole.MERCHANT,
        'Out of stock',
      );
      expect(result).toEqual(mockRejected);
    });
  });

  describe('updateOrderStatus', () => {
    it('should delegate to orderActionsService.updateOrderStatus', async () => {
      const mockUpdated = { id: 1, status: OrderStatus.DELIVERED };
      mockOrderActionsService.updateOrderStatus.mockResolvedValue(mockUpdated);

      const result = await service.updateOrderStatus(
        1,
        OrderStatus.DELIVERED,
        1,
        UserRole.ADMIN,
        undefined,
        { lat: 24.7, lng: 46.7 },
        30,
        45,
      );

      expect(mockOrderActionsService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.DELIVERED,
        1,
        UserRole.ADMIN,
        undefined,
        { lat: 24.7, lng: 46.7 },
        30,
        45,
      );
      expect(result).toEqual(mockUpdated);
    });
  });

  describe('cancelOrder', () => {
    it('should delegate to orderActionsService.cancelOrder', async () => {
      const mockCancelled = { id: 1, status: OrderStatus.CANCELLED };
      mockOrderActionsService.cancelOrder.mockResolvedValue(mockCancelled);

      const result = await service.cancelOrder(
        1,
        1,
        UserRole.ADMIN,
        'Customer request',
      );

      expect(mockOrderActionsService.cancelOrder).toHaveBeenCalledWith(
        1,
        1,
        UserRole.ADMIN,
        'Customer request',
      );
      expect(result).toEqual(mockCancelled);
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { DataSource, Repository } from 'typeorm';
import { getQueueToken } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { OrderCreationService } from '../../../../src/modules/orders/services/order-creation.service';
import { CouponsService } from '../../../../src/modules/coupons/coupons.service';
import { CreateOrderDto } from '../../../../src/modules/orders/dto/create-order.dto';
import { OrderStatus } from '../../../../src/common/enums/order-status.enum';
import { DiscountType } from '../../../../src/common/enums/discount-type.enum';
import { Order } from '../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../src/database/entities/product.entity';
import { Offer } from '../../../../src/database/entities/offer.entity';
import { Invoice } from '../../../../src/database/entities/invoice.entity';

describe('OrderCreationService', () => {
  let service: OrderCreationService;
  let orderRepo: jest.Mocked<Repository<Order>>;
  let orderItemRepo: jest.Mocked<Repository<OrderItem>>;
  let productRepo: jest.Mocked<Repository<Product>>;
  let offerRepo: jest.Mocked<Repository<Offer>>;
  let invoiceRepo: jest.Mocked<Repository<Invoice>>;
  let couponsService: jest.Mocked<CouponsService>;
  let dataSource: jest.Mocked<DataSource>;
  let ordersQueue: jest.Mocked<Queue>;

  const mockUserId = 10;
  const mockOwnerId = 20;
  const mockProductId = 100;
  const mockOfferId = 200;

  const mockProduct: Partial<Product> = {
    id: mockProductId,
    name: 'شاورما',
    price: 1500,
    merchantId: mockOwnerId,
    isAvailable: true,
    hasStock: true,
    stockQuantity: 50,
    discount: 0,
    discountType: DiscountType.NONE,
  };

  const mockOffer = {
    id: mockOfferId,
    name: 'عرض الشاورما',
    isActive: true,
    merchantId: mockOwnerId,
    discountType: DiscountType.PERCENTAGE,
    discountValue: 10,
    offerProducts: [
      {
        product: { ...mockProduct, id: mockProductId + 1, price: 1000 },
      },
    ],
  } as any;

  const createDto: CreateOrderDto = {
    ownerId: mockOwnerId,
    items: [{ productId: mockProductId, quantity: 2 }],
    deliveryCoordinates: { latitude: 24.7, longitude: 46.7 },
    paymentMethod: 'CASH',
    areaId: 1,
  } as any;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrderCreationService,
        {
          provide: getRepositoryToken(Order),
          useValue: { create: jest.fn() },
        },
        {
          provide: getRepositoryToken(OrderItem),
          useValue: { create: jest.fn() },
        },
        {
          provide: getRepositoryToken(Product),
          useValue: { findOne: jest.fn() },
        },
        {
          provide: getRepositoryToken(Offer),
          useValue: { findOne: jest.fn() },
        },
        {
          provide: getRepositoryToken(Invoice),
          useValue: { create: jest.fn() },
        },
        {
          provide: CouponsService,
          useValue: {},
        },
        {
          provide: DataSource,
          useValue: { createQueryRunner: jest.fn() },
        },
        {
          provide: getQueueToken('orders'),
          useValue: { add: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<OrderCreationService>(OrderCreationService);
    orderRepo = module.get(getRepositoryToken(Order));
    orderItemRepo = module.get(getRepositoryToken(OrderItem));
    productRepo = module.get(getRepositoryToken(Product));
    offerRepo = module.get(getRepositoryToken(Offer));
    invoiceRepo = module.get(getRepositoryToken(Invoice));
    couponsService = module.get(CouponsService);
    dataSource = module.get(DataSource);
    ordersQueue = module.get(getQueueToken('orders'));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    const mockSavedOrder = { id: 1, customerId: mockUserId } as Order;

    const mockQueryRunner = {
      connect: jest.fn(),
      startTransaction: jest.fn(),
      commitTransaction: jest.fn(),
      rollbackTransaction: jest.fn(),
      release: jest.fn(),
      manager: {
        save: jest.fn().mockResolvedValue(mockSavedOrder),
        decrement: jest.fn().mockResolvedValue(undefined),
      },
    } as any;

    beforeEach(() => {
      dataSource.createQueryRunner.mockReturnValue(mockQueryRunner);
      orderRepo.create.mockReturnValue(mockSavedOrder);
      orderItemRepo.create.mockReturnValue({} as OrderItem);
      invoiceRepo.create.mockReturnValue({} as Invoice);
      ordersQueue.add.mockResolvedValue({ id: 'job-1' } as any);
      productRepo.findOne.mockResolvedValue(mockProduct as Product);
    });

    it('ينشئ طلباً بنجاح', async () => {
      const result = await service.create(createDto, mockUserId);

      expect(result).toBeDefined();
      expect(result.order).toBeDefined();
      expect(mockQueryRunner.connect).toHaveBeenCalled();
      expect(mockQueryRunner.startTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.commitTransaction).toHaveBeenCalled();
      expect(ordersQueue.add).toHaveBeenCalledWith(
        'order-timeout',
        { orderId: mockSavedOrder.id },
        expect.objectContaining({ delay: expect.any(Number) }),
      );
    });

    it('يرمي BadRequestException إذا كانت الإحداثيات مفقودة', async () => {
      const invalidDto = {
        ...createDto,
        deliveryCoordinates: undefined as any,
      };

      await expect(service.create(invalidDto, mockUserId)).rejects.toThrow(
        BadRequestException,
      );
      expect(mockQueryRunner.rollbackTransaction).toHaveBeenCalled();
    });

    it('يرمي NotFoundException إذا كان المنتج غير موجود', async () => {
      productRepo.findOne.mockResolvedValue(null);

      await expect(service.create(createDto, mockUserId)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('يرمي BadRequestException إذا كان المنتج غير متاح', async () => {
      productRepo.findOne.mockResolvedValue({
        ...mockProduct,
        isAvailable: false,
      } as Product);

      await expect(service.create(createDto, mockUserId)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('يرمي BadRequestException إذا كانت الكمية تتجاوز المخزون', async () => {
      productRepo.findOne.mockResolvedValue({
        ...mockProduct,
        stockQuantity: 1,
      } as Product);

      await expect(service.create(createDto, mockUserId)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('يرمي BadRequestException إذا كان المنتج لا يتبع التاجر', async () => {
      productRepo.findOne.mockResolvedValue({
        ...mockProduct,
        merchantId: 999,
      } as Product);

      await expect(service.create(createDto, mockUserId)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('يعالج الأخطاء غير المتوقعة ويلغي المعاملة', async () => {
      mockQueryRunner.manager.save.mockRejectedValue(new Error('DB error'));

      await expect(service.create(createDto, mockUserId)).rejects.toThrow(
        BadRequestException,
      );
      expect(mockQueryRunner.rollbackTransaction).toHaveBeenCalled();
      expect(mockQueryRunner.release).toHaveBeenCalled();
    });
  });

  describe('مع العروض (offers)', () => {
    const createDtoWithOffers: CreateOrderDto = {
      ownerId: mockOwnerId,
      items: [],
      offers: [{ offerId: mockOfferId, quantity: 1 }],
      deliveryCoordinates: { latitude: 24.7, longitude: 46.7 },
      paymentMethod: 'CASH',
      areaId: 1,
    } as any;

    const mockQueryRunner = {
      connect: jest.fn(),
      startTransaction: jest.fn(),
      commitTransaction: jest.fn(),
      rollbackTransaction: jest.fn(),
      release: jest.fn(),
      manager: {
        save: jest.fn().mockResolvedValue({ id: 1, customerId: mockUserId }),
        decrement: jest.fn().mockResolvedValue(undefined),
      },
    } as any;

    beforeEach(() => {
      dataSource.createQueryRunner.mockReturnValue(mockQueryRunner);
      orderRepo.create.mockReturnValue({ id: 1 } as Order);
      orderItemRepo.create.mockReturnValue({} as OrderItem);
      invoiceRepo.create.mockReturnValue({} as Invoice);
      ordersQueue.add.mockResolvedValue({ id: 'job-1' } as any);
    });

    it('ينشئ طلباً مع العروض', async () => {
      offerRepo.findOne.mockResolvedValue(mockOffer);

      const result = await service.create(createDtoWithOffers, mockUserId);

      expect(result).toBeDefined();
      expect(mockQueryRunner.commitTransaction).toHaveBeenCalled();
    });

    it('يرمي NotFoundException إذا كان العرض غير موجود', async () => {
      offerRepo.findOne.mockResolvedValue(null);

      await expect(
        service.create(createDtoWithOffers, mockUserId),
      ).rejects.toThrow(NotFoundException);
    });

    it('يرمي BadRequestException إذا كان العرض غير نشط', async () => {
      offerRepo.findOne.mockResolvedValue({ ...mockOffer, isActive: false });

      await expect(
        service.create(createDtoWithOffers, mockUserId),
      ).rejects.toThrow(BadRequestException);
    });
  });
});

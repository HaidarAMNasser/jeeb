import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ItemManagementStage } from '../../../../../src/modules/orders/pipeline/stages/item-management.stage';
import { Order } from '../../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../../src/database/entities/product.entity';
import { OffersHelper } from '../../../../../src/modules/orders/pipeline/helpers/offers.helper';
import { OrderStatus } from '../../../../../src/common/enums/order-status.enum';
import { UserRole } from '../../../../../src/common/enums/user-role.enum';

describe('ItemManagementStage', () => {
  let stage: ItemManagementStage;
  const mockOrderItemRepo = {
    create: jest.fn(),
    delete: jest.fn(),
    save: jest.fn(),
  };
  const mockProductRepo = {
    findByIds: jest.fn(),
    findOne: jest.fn(),
    increment: jest.fn(),
    decrement: jest.fn(),
  };
  const mockOffersHelper = { handleOffersModification: jest.fn() };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ItemManagementStage,
        { provide: getRepositoryToken(Order), useValue: {} },
        { provide: getRepositoryToken(OrderItem), useValue: mockOrderItemRepo },
        { provide: getRepositoryToken(Product), useValue: mockProductRepo },
        { provide: OffersHelper, useValue: mockOffersHelper },
      ],
    }).compile();
    stage = module.get<ItemManagementStage>(ItemManagementStage);
  });

  afterEach(() => jest.clearAllMocks());

  const baseCtx = (overrides = {}) => ({
    orderId: 1,
    newStatus: OrderStatus.CONFIRMED,
    userId: 1,
    role: UserRole.ADMIN,
    order: {
      id: 1,
      status: OrderStatus.PENDING,
      ownerId: 5,
      items: [{ id: 10, productId: 100, quantity: 2, offerId: null }],
      offers: [],
      deliveryFee: 10,
      platformCommission: 5,
      tipAmount: 3,
    },
    ...overrides,
  });

  const makeProduct = (id: number, overrides = {}) => ({
    id,
    name: `Product ${id}`,
    price: 100,
    merchantId: 5,
    isAvailable: true,
    stockQuantity: 10,
    hasStock: true,
    discount: 0,
    discountType: null,
    ...overrides,
  });

  it('should pass through when no modifications', async () => {
    const result = await stage.execute(baseCtx());
    expect(result.success).toBe(true);
  });

  it('should delegate to offersHelper when only deletedOffers', async () => {
    mockOffersHelper.handleOffersModification.mockResolvedValue({
      success: true,
    });
    await stage.execute(baseCtx({ deletedOffers: [200] }));
    expect(mockOffersHelper.handleOffersModification).toHaveBeenCalled();
  });

  it('should fail when order is null with modifications', async () => {
    const result = await stage.execute(
      baseCtx({ order: null, items: [{ productId: 100, quantity: 3 }] }),
    );
    expect(result.success).toBe(false);
  });

  it('should fail when order is not PENDING', async () => {
    const result = await stage.execute(
      baseCtx({
        items: [{ productId: 100, quantity: 3 }],
        order: { id: 1, status: OrderStatus.CONFIRMED, items: [], offers: [] },
      }),
    );
    expect(result.success).toBe(false);
  });

  it('should process items correctly', async () => {
    mockProductRepo.findByIds.mockResolvedValue([makeProduct(100)]);
    mockOrderItemRepo.create.mockImplementation((dto) => dto);
    mockOrderItemRepo.delete.mockResolvedValue({} as any);
    mockOrderItemRepo.save.mockResolvedValue([]);
    const result = await stage.execute(
      baseCtx({ items: [{ productId: 100, quantity: 3 }] }),
    );
    expect(result.success).toBe(true);
  });

  it('should process itemsByProductId correctly', async () => {
    mockProductRepo.findByIds.mockResolvedValue([makeProduct(100)]);
    mockOrderItemRepo.create.mockImplementation((dto) => dto);
    mockOrderItemRepo.delete.mockResolvedValue({} as any);
    mockOrderItemRepo.save.mockResolvedValue([]);
    const result = await stage.execute(
      baseCtx({ itemsByProductId: [{ productId: 100, quantity: 3 }] }),
    );
    expect(result.success).toBe(true);
  });

  it('should fail when itemsById references non-existing item', async () => {
    const result = await stage.execute(
      baseCtx({ itemsById: [{ id: 999, quantity: 2 }] }),
    );
    expect(result.success).toBe(false);
  });

  it('should process itemsById correctly', async () => {
    mockProductRepo.findByIds.mockResolvedValue([makeProduct(100)]);
    mockOrderItemRepo.create.mockImplementation((dto) => dto);
    mockOrderItemRepo.delete.mockResolvedValue({} as any);
    mockOrderItemRepo.save.mockResolvedValue([]);
    const result = await stage.execute(
      baseCtx({ itemsById: [{ id: 10, quantity: 4 }] }),
    );
    expect(result.success).toBe(true);
  });

  it('should fail when deletedProducts references unknown product', async () => {
    const result = await stage.execute(baseCtx({ deletedProducts: [999] }));
    expect(result.success).toBe(false);
  });

  it('should process deletedProducts correctly', async () => {
    mockProductRepo.findByIds.mockResolvedValue([
      makeProduct(100),
      makeProduct(200),
    ]);
    mockOrderItemRepo.create.mockImplementation((dto) => dto);
    mockOrderItemRepo.delete.mockResolvedValue({} as any);
    mockOrderItemRepo.save.mockResolvedValue([]);
    const ctx = baseCtx({
      order: {
        id: 1,
        status: OrderStatus.PENDING,
        ownerId: 5,
        items: [
          { id: 10, productId: 100, quantity: 2, offerId: null },
          { id: 11, productId: 200, quantity: 1, offerId: null },
        ],
        offers: [],
        deliveryFee: 0,
        platformCommission: 0,
        tipAmount: 0,
      },
      deletedProducts: [100],
    });
    const result = await stage.execute(ctx);
    expect(result.success).toBe(true);
  });

  it('should fail when removing all items', async () => {
    const result = await stage.execute(
      baseCtx({
        items: [{ productId: 100, quantity: 0 }],
        deletedProducts: [100],
      }),
    );
    expect(result.success).toBe(false);
  });

  it('should fail when product not found', async () => {
    mockProductRepo.findByIds.mockResolvedValue([]);
    const result = await stage.execute(
      baseCtx({ items: [{ productId: 100, quantity: 3 }] }),
    );
    expect(result.success).toBe(false);
  });

  it('should fail when product not belonging to merchant', async () => {
    mockProductRepo.findByIds.mockResolvedValue([
      makeProduct(100, { merchantId: 999 }),
    ]);
    const result = await stage.execute(
      baseCtx({ items: [{ productId: 100, quantity: 3 }] }),
    );
    expect(result.success).toBe(false);
  });

  it('should fail when product not available', async () => {
    mockProductRepo.findByIds.mockResolvedValue([
      makeProduct(100, { isAvailable: false }),
    ]);
    const result = await stage.execute(
      baseCtx({ items: [{ productId: 100, quantity: 3 }] }),
    );
    expect(result.success).toBe(false);
  });

  it('should fail on insufficient stock', async () => {
    mockProductRepo.findByIds.mockResolvedValue([
      makeProduct(100, { stockQuantity: 1, hasStock: true }),
    ]);
    const result = await stage.execute(
      baseCtx({ items: [{ productId: 100, quantity: 5 }] }),
    );
    expect(result.success).toBe(false);
  });

  it('should decrement stock on increased quantity', async () => {
    mockProductRepo.findByIds.mockResolvedValue([makeProduct(100)]);
    mockProductRepo.decrement.mockResolvedValue({} as any);
    mockOrderItemRepo.create.mockImplementation((dto) => dto);
    mockOrderItemRepo.delete.mockResolvedValue({} as any);
    mockOrderItemRepo.save.mockResolvedValue([]);
    await stage.execute(baseCtx({ items: [{ productId: 100, quantity: 5 }] }));
    expect(mockProductRepo.decrement).toHaveBeenCalledWith(
      { id: 100 },
      'stockQuantity',
      3,
    );
  });

  it('should increment stock on decreased quantity', async () => {
    mockProductRepo.findByIds.mockResolvedValue([makeProduct(100)]);
    mockProductRepo.increment.mockResolvedValue({} as any);
    mockOrderItemRepo.create.mockImplementation((dto) => dto);
    mockOrderItemRepo.delete.mockResolvedValue({} as any);
    mockOrderItemRepo.save.mockResolvedValue([]);
    await stage.execute(baseCtx({ items: [{ productId: 100, quantity: 1 }] }));
    expect(mockProductRepo.increment).toHaveBeenCalledWith(
      { id: 100 },
      'stockQuantity',
      1,
    );
  });

  it('should restore stock for removed products', async () => {
    mockProductRepo.findByIds.mockResolvedValue([
      makeProduct(100),
      makeProduct(200),
    ]);
    mockProductRepo.findOne.mockResolvedValueOnce(makeProduct(100));
    mockProductRepo.increment.mockResolvedValue({} as any);
    mockOrderItemRepo.create.mockImplementation((dto) => dto);
    mockOrderItemRepo.delete.mockResolvedValue({} as any);
    mockOrderItemRepo.save.mockResolvedValue([]);
    const ctx = baseCtx({
      order: {
        id: 1,
        status: OrderStatus.PENDING,
        ownerId: 5,
        items: [
          { id: 10, productId: 100, quantity: 2, offerId: null },
          { id: 11, productId: 200, quantity: 1, offerId: null },
        ],
        offers: [],
        deliveryFee: 0,
        platformCommission: 0,
        tipAmount: 0,
      },
      items: [{ productId: 200, quantity: 1 }],
      deletedProducts: [100],
    });
    const result = await stage.execute(ctx);
    expect(result.success).toBe(true);
    expect(mockProductRepo.increment).toHaveBeenCalled();
  });

  it('should set order total and discount', async () => {
    mockProductRepo.findByIds.mockResolvedValue([
      makeProduct(100, {
        price: 200,
        discount: 10,
        discountType: 'PERCENTAGE',
      }),
    ]);
    mockOrderItemRepo.create.mockImplementation((dto) => dto);
    mockOrderItemRepo.delete.mockResolvedValue({} as any);
    mockOrderItemRepo.save.mockResolvedValue([]);
    const result = await stage.execute(
      baseCtx({ items: [{ productId: 100, quantity: 2 }] }),
    );
    expect(result.success).toBe(true);
    expect(result.data.order.totalAmount).toBe(378);
    expect(result.data.order.discountAmount).toBe(40);
  });

  it('should handle errors gracefully', async () => {
    mockProductRepo.findByIds.mockRejectedValue(new Error('DB error'));
    const result = await stage.execute(
      baseCtx({ items: [{ productId: 100, quantity: 3 }] }),
    );
    expect(result.success).toBe(false);
    expect(result.stage).toBe('ItemManagement');
  });
});

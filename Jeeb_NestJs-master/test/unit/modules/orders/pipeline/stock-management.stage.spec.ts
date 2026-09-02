import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { StockManagementStage } from '../../../../../src/modules/orders/pipeline/stages/stock-management.stage';
import { Order } from '../../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../../src/database/entities/product.entity';
import { OrderStatus } from '../../../../../src/common/enums/order-status.enum';
import { UserRole } from '../../../../../src/common/enums/user-role.enum';

describe('StockManagementStage', () => {
  let stage: StockManagementStage;
  const mockProductRepo = {
    findByIds: jest.fn(),
    increment: jest.fn(),
    decrement: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StockManagementStage,
        { provide: getRepositoryToken(Order), useValue: {} },
        { provide: getRepositoryToken(OrderItem), useValue: {} },
        { provide: getRepositoryToken(Product), useValue: mockProductRepo },
      ],
    }).compile();
    stage = module.get<StockManagementStage>(StockManagementStage);
  });

  afterEach(() => jest.clearAllMocks());

  const ctx = (overrides = {}) => ({
    orderId: 1,
    newStatus: OrderStatus.CANCELLED,
    userId: 1,
    role: UserRole.ADMIN,
    order: {
      id: 1,
      status: OrderStatus.PENDING,
      items: [{ id: 1, productId: 100, quantity: 2, offerId: null }],
    },
    ...overrides,
  });

  it('should restore stock on cancellation', async () => {
    mockProductRepo.findByIds.mockResolvedValue([
      { id: 100, hasStock: true, name: 'Product', stockQuantity: 5 },
    ]);
    const result = await stage.execute(ctx());
    expect(result.success).toBe(true);
    expect(mockProductRepo.increment).toHaveBeenCalledWith(
      { id: 100 },
      'stockQuantity',
      2,
    );
  });

  it('should skip restoration for non-stock items', async () => {
    mockProductRepo.findByIds.mockResolvedValue([
      { id: 100, hasStock: false, name: 'Product' },
    ]);
    const result = await stage.execute(ctx());
    expect(result.success).toBe(true);
    expect(mockProductRepo.increment).not.toHaveBeenCalled();
  });

  it('should skip when order has no items', async () => {
    const result = await stage.execute(
      ctx({ order: { id: 1, status: OrderStatus.PENDING, items: [] } }),
    );
    expect(result.success).toBe(true);
    expect(mockProductRepo.findByIds).not.toHaveBeenCalled();
  });

  it('should do nothing for non-cancel status', async () => {
    const result = await stage.execute(
      ctx({ newStatus: OrderStatus.CONFIRMED }),
    );
    expect(result.success).toBe(true);
    expect(mockProductRepo.findByIds).not.toHaveBeenCalled();
  });

  it('should deduct stock on restore from CANCELLED', async () => {
    mockProductRepo.findByIds.mockResolvedValue([
      { id: 100, hasStock: true, name: 'Product', stockQuantity: 10 },
    ]);
    const result = await stage.execute(
      ctx({
        order: {
          id: 1,
          status: OrderStatus.CANCELLED,
          items: [{ id: 1, productId: 100, quantity: 2 }],
        },
        newStatus: OrderStatus.PENDING,
      }),
    );
    expect(result.success).toBe(true);
    expect(mockProductRepo.decrement).toHaveBeenCalled();
  });

  it('should fail restore when stock insufficient', async () => {
    mockProductRepo.findByIds.mockResolvedValue([
      { id: 100, hasStock: true, name: 'Product', stockQuantity: 1 },
    ]);
    const result = await stage.execute(
      ctx({
        order: {
          id: 1,
          status: OrderStatus.CANCELLED,
          items: [{ id: 1, productId: 100, quantity: 2 }],
        },
        newStatus: OrderStatus.PENDING,
      }),
    );
    expect(result.success).toBe(false);
  });
});

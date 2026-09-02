import { Test, TestingModule } from '@nestjs/testing';
import { OffersHelper } from '../../../../../src/modules/orders/pipeline/helpers/offers.helper';
import { Logger } from '@nestjs/common';
import { OrderStatus } from '../../../../../src/common/enums/order-status.enum';

describe('OffersHelper', () => {
  let helper: OffersHelper;
  const mockOrderItemRepo = { delete: jest.fn() };
  const mockProductRepo = { findOne: jest.fn(), increment: jest.fn() };
  const logger = new Logger('test');

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [OffersHelper],
    }).compile();
    helper = module.get<OffersHelper>(OffersHelper);
  });

  afterEach(() => jest.clearAllMocks());

  const ctx = (overrides = {}) => ({
    orderId: 1,
    newStatus: OrderStatus.PENDING,
    userId: 1,
    role: 'ADMIN' as any,
    order: {
      id: 1,
      status: OrderStatus.PENDING,
      offers: [{ id: 200 }],
      items: [{ id: 1, productId: 100, quantity: 2, offerId: 200 }],
    },
    deletedOffers: [200],
    ...overrides,
  });

  it('should fail when order is missing', async () => {
    const result = await helper.handleOffersModification(
      ctx({ order: null }),
      mockOrderItemRepo as any,
      mockProductRepo as any,
      logger,
    );
    expect(result.success).toBe(false);
  });

  it('should fail when order is not PENDING', async () => {
    const result = await helper.handleOffersModification(
      ctx({
        order: { id: 1, status: OrderStatus.CONFIRMED, offers: [], items: [] },
      }),
      mockOrderItemRepo as any,
      mockProductRepo as any,
      logger,
    );
    expect(result.success).toBe(false);
  });

  it('should fail when deleted offers not in order', async () => {
    const result = await helper.handleOffersModification(
      ctx({ deletedOffers: [999] }),
      mockOrderItemRepo as any,
      mockProductRepo as any,
      logger,
    );
    expect(result.success).toBe(false);
  });

  it('should restore stock and delete offer items', async () => {
    mockProductRepo.findOne.mockResolvedValue({ id: 100, hasStock: true });
    mockProductRepo.increment.mockResolvedValue({} as any);
    mockOrderItemRepo.delete.mockResolvedValue({} as any);
    const result = await helper.handleOffersModification(
      ctx(),
      mockOrderItemRepo as any,
      mockProductRepo as any,
      logger,
    );
    expect(result.success).toBe(true);
    expect(mockProductRepo.increment).toHaveBeenCalledWith(
      { id: 100 },
      'stockQuantity',
      2,
    );
    expect(mockOrderItemRepo.delete).toHaveBeenCalledWith([1]);
  });

  it('should succeed when no deleted offers', async () => {
    const result = await helper.handleOffersModification(
      ctx({ deletedOffers: [] }),
      mockOrderItemRepo as any,
      mockProductRepo as any,
      logger,
    );
    expect(result.success).toBe(true);
  });
});

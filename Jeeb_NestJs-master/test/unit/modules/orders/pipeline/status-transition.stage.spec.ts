import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { StatusTransitionStage } from '../../../../../src/modules/orders/pipeline/stages/status-transition.stage';
import { Order } from '../../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../../src/database/entities/product.entity';
import { UpdateOrderStage } from '../../../../../src/modules/orders/pipeline/update-order-pipeline.interfaces';
import { OrderStatus } from '../../../../../src/common/enums/order-status.enum';
import { UserRole } from '../../../../../src/common/enums/user-role.enum';

describe('StatusTransitionStage', () => {
  let stage: StatusTransitionStage;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StatusTransitionStage,
        { provide: getRepositoryToken(Order), useValue: {} },
        { provide: getRepositoryToken(OrderItem), useValue: {} },
        { provide: getRepositoryToken(Product), useValue: {} },
      ],
    }).compile();
    stage = module.get<StatusTransitionStage>(StatusTransitionStage);
  });

  const ctx = (overrides = {}) => ({
    orderId: 1,
    newStatus: OrderStatus.CONFIRMED,
    userId: 1,
    role: UserRole.ADMIN,
    order: { id: 1, status: OrderStatus.PENDING },
    ...overrides,
  });

  it('should allow PENDING -> CONFIRMED', async () => {
    const result = await stage.execute(ctx());
    expect(result.success).toBe(true);
  });

  it('should fail when order is null', async () => {
    const result = await stage.execute(ctx({ order: null }));
    expect(result.success).toBe(false);
    expect(result.stage).toBe(UpdateOrderStage.STATUS_TRANSITION);
  });

  it('should fail when order is already DELIVERED', async () => {
    const result = await stage.execute(
      ctx({
        order: { id: 1, status: OrderStatus.DELIVERED },
        newStatus: OrderStatus.PAID,
      }),
    );
    expect(result.success).toBe(false);
  });

  it('should fail on invalid transition PENDING -> DELIVERED', async () => {
    const result = await stage.execute(
      ctx({ newStatus: OrderStatus.DELIVERED }),
    );
    expect(result.success).toBe(false);
    expect(result.error).toContain('Invalid');
  });

  it('should allow CANCELLED -> PENDING within time window', async () => {
    const result = await stage.execute(
      ctx({
        order: {
          id: 1,
          status: OrderStatus.CANCELLED,
          cancelledAt: new Date(),
        },
        newStatus: OrderStatus.PENDING,
      }),
    );
    expect(result.success).toBe(true);
  });

  it('should fail CANCELLED -> PENDING after 3 min window', async () => {
    const result = await stage.execute(
      ctx({
        order: {
          id: 1,
          status: OrderStatus.CANCELLED,
          cancelledAt: new Date(Date.now() - 4 * 60 * 1000),
        },
        newStatus: OrderStatus.PENDING,
      }),
    );
    expect(result.success).toBe(false);
    expect(result.error).toContain('3-minute window');
  });

  it('should fail CANCELLED without cancelledAt', async () => {
    const result = await stage.execute(
      ctx({
        order: { id: 1, status: OrderStatus.CANCELLED },
        newStatus: OrderStatus.PENDING,
      }),
    );
    expect(result.success).toBe(false);
  });

  it('should allow CANCELLED -> CONFIRMED within window', async () => {
    const result = await stage.execute(
      ctx({
        order: {
          id: 1,
          status: OrderStatus.CANCELLED,
          cancelledAt: new Date(),
        },
        newStatus: OrderStatus.CONFIRMED,
      }),
    );
    expect(result.success).toBe(true);
  });

  it('should fail CANCELLED -> DELIVERED (not allowed)', async () => {
    const result = await stage.execute(
      ctx({
        order: {
          id: 1,
          status: OrderStatus.CANCELLED,
          cancelledAt: new Date(),
        },
        newStatus: OrderStatus.DELIVERED,
      }),
    );
    expect(result.success).toBe(false);
  });

  it('should block DELIVERED -> any (source code blocks all transitions from DELIVERED)', async () => {
    const result = await stage.execute(
      ctx({
        order: { id: 1, status: OrderStatus.DELIVERED },
        newStatus: OrderStatus.PAID,
      }),
    );
    expect(result.success).toBe(false);
  });

  it('should allow PAID -> COMPLETE', async () => {
    const result = await stage.execute(
      ctx({
        order: { id: 1, status: OrderStatus.PAID },
        newStatus: OrderStatus.COMPLETE,
      }),
    );
    expect(result.success).toBe(true);
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { AuthorizationStage } from '../../../../../src/modules/orders/pipeline/stages/authorization.stage';
import { Order } from '../../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../../src/database/entities/product.entity';
import { UpdateOrderStage } from '../../../../../src/modules/orders/pipeline/update-order-pipeline.interfaces';
import { OrderStatus } from '../../../../../src/common/enums/order-status.enum';
import { UserRole } from '../../../../../src/common/enums/user-role.enum';

describe('AuthorizationStage', () => {
  let stage: AuthorizationStage;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthorizationStage,
        { provide: getRepositoryToken(Order), useValue: {} },
        { provide: getRepositoryToken(OrderItem), useValue: {} },
        { provide: getRepositoryToken(Product), useValue: {} },
      ],
    }).compile();
    stage = module.get<AuthorizationStage>(AuthorizationStage);
  });

  const baseCtx = (overrides = {}) => ({
    orderId: 1,
    newStatus: OrderStatus.CANCELLED,
    userId: 1,
    role: UserRole.CUSTOMER,
    order: { id: 1, status: OrderStatus.PENDING, customerId: 1, ownerId: 2 },
    ...overrides,
  });

  it('should fail when order is missing', async () => {
    const result = await stage.execute(baseCtx({ order: null }));
    expect(result.success).toBe(false);
    expect(result.stage).toBe(UpdateOrderStage.AUTHORIZATION);
  });

  it('should allow CUSTOMER to cancel their own order', async () => {
    const result = await stage.execute(baseCtx());
    expect(result.success).toBe(true);
  });

  it('should deny CUSTOMER from cancelling another customer order', async () => {
    const result = await stage.execute(
      baseCtx({
        order: {
          id: 1,
          status: OrderStatus.PENDING,
          customerId: 99,
          ownerId: 2,
        },
      }),
    );
    expect(result.success).toBe(false);
  });

  it('should deny role without permission for status', async () => {
    const result = await stage.execute(
      baseCtx({ role: UserRole.CUSTOMER, newStatus: OrderStatus.CONFIRMED }),
    );
    expect(result.success).toBe(false);
    expect(result.error).toContain('cannot change status');
  });

  it('should allow ADMIN any status transition', async () => {
    const result = await stage.execute(
      baseCtx({ role: UserRole.ADMIN, newStatus: OrderStatus.COMPLETE }),
    );
    expect(result.success).toBe(true);
  });

  it('should deny MERCHANT updating another merchant order', async () => {
    const result = await stage.execute(
      baseCtx({
        role: UserRole.MERCHANT,
        userId: 5,
        order: {
          id: 1,
          status: OrderStatus.PENDING,
          customerId: 1,
          ownerId: 2,
        },
      }),
    );
    expect(result.success).toBe(false);
  });

  it('should allow MERCHANT updating their own order', async () => {
    const result = await stage.execute(
      baseCtx({
        role: UserRole.MERCHANT,
        userId: 2,
        newStatus: OrderStatus.CONFIRMED,
        order: {
          id: 1,
          status: OrderStatus.PENDING,
          customerId: 1,
          ownerId: 2,
        },
      }),
    );
    expect(result.success).toBe(true);
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ValidationStage } from '../../../../../src/modules/orders/pipeline/stages/validation.stage';
import { Order } from '../../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../../src/database/entities/product.entity';
import { UpdateOrderStage } from '../../../../../src/modules/orders/pipeline/update-order-pipeline.interfaces';
import { OrderStatus } from '../../../../../src/common/enums/order-status.enum';
import { UserRole } from '../../../../../src/common/enums/user-role.enum';

describe('ValidationStage', () => {
  let stage: ValidationStage;
  const mockOrderRepo = { findOne: jest.fn() };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ValidationStage,
        { provide: getRepositoryToken(Order), useValue: mockOrderRepo },
        { provide: getRepositoryToken(OrderItem), useValue: {} },
        { provide: getRepositoryToken(Product), useValue: {} },
      ],
    }).compile();
    stage = module.get<ValidationStage>(ValidationStage);
  });

  afterEach(() => jest.clearAllMocks());

  it('should fail when orderId is missing', async () => {
    const result = await stage.execute({
      orderId: 0,
      newStatus: OrderStatus.CONFIRMED,
      userId: 1,
      role: UserRole.ADMIN,
    });
    expect(result.success).toBe(false);
    expect(result.stage).toBe(UpdateOrderStage.VALIDATION);
  });

  it('should fail when newStatus is missing', async () => {
    const result = await stage.execute({
      orderId: 1,
      newStatus: null as any,
      userId: 1,
      role: UserRole.ADMIN,
    });
    expect(result.success).toBe(false);
  });

  it('should fail when order not found in DB', async () => {
    mockOrderRepo.findOne.mockResolvedValue(null);
    const result = await stage.execute({
      orderId: 999,
      newStatus: OrderStatus.CONFIRMED,
      userId: 1,
      role: UserRole.ADMIN,
    });
    expect(result.success).toBe(false);
    expect(result.error).toContain('Order not found');
  });

  it('should succeed and attach order to context', async () => {
    const foundOrder = { id: 1, status: OrderStatus.PENDING };
    mockOrderRepo.findOne.mockResolvedValue(foundOrder);
    const result = await stage.execute({
      orderId: 1,
      newStatus: OrderStatus.CONFIRMED,
      userId: 1,
      role: UserRole.ADMIN,
    });
    expect(result.success).toBe(true);
    expect(result.data?.order).toEqual(foundOrder);
  });
});

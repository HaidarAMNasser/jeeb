import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotificationStage } from '../../../../../src/modules/orders/pipeline/stages/notification.stage';
import { Order } from '../../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../../src/database/entities/product.entity';
import { OrderActionsService } from '../../../../../src/modules/orders/services/order-actions.service';
import { UpdateOrderStage } from '../../../../../src/modules/orders/pipeline/update-order-pipeline.interfaces';
import { OrderStatus } from '../../../../../src/common/enums/order-status.enum';
import { UserRole } from '../../../../../src/common/enums/user-role.enum';

describe('NotificationStage', () => {
  let stage: NotificationStage;
  const mockOrderActionsService = { sendStatusNotifications: jest.fn() };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationStage,
        { provide: getRepositoryToken(Order), useValue: {} },
        { provide: getRepositoryToken(OrderItem), useValue: {} },
        { provide: getRepositoryToken(Product), useValue: {} },
        { provide: OrderActionsService, useValue: mockOrderActionsService },
      ],
    }).compile();
    stage = module.get<NotificationStage>(NotificationStage);
  });

  afterEach(() => jest.clearAllMocks());

  it('should send status notifications', async () => {
    const result = await stage.execute({
      orderId: 1,
      newStatus: OrderStatus.CONFIRMED,
      userId: 1,
      role: UserRole.ADMIN,
      order: { id: 1 },
    });
    expect(result.success).toBe(true);
    expect(mockOrderActionsService.sendStatusNotifications).toHaveBeenCalled();
  });

  it('should succeed even when order is missing', async () => {
    const result = await stage.execute({
      orderId: 1,
      newStatus: OrderStatus.CONFIRMED,
      userId: 1,
      role: UserRole.ADMIN,
    });
    expect(result.success).toBe(true);
    expect(
      mockOrderActionsService.sendStatusNotifications,
    ).not.toHaveBeenCalled();
  });

  it('should log for READY_FOR_PICKUP', async () => {
    const result = await stage.execute({
      orderId: 1,
      newStatus: OrderStatus.READY_FOR_PICKUP,
      userId: 1,
      role: UserRole.ADMIN,
      order: { id: 1 },
    });
    expect(result.success).toBe(true);
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UpdateOrderPipeline } from '../../../../../src/modules/orders/pipeline/update-order-pipeline';
import { Order } from '../../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../../src/database/entities/product.entity';
import { ValidationStage } from '../../../../../src/modules/orders/pipeline/stages/validation.stage';
import { AuthorizationStage } from '../../../../../src/modules/orders/pipeline/stages/authorization.stage';
import { StatusTransitionStage } from '../../../../../src/modules/orders/pipeline/stages/status-transition.stage';
import { StockManagementStage } from '../../../../../src/modules/orders/pipeline/stages/stock-management.stage';
import { ItemManagementStage } from '../../../../../src/modules/orders/pipeline/stages/item-management.stage';
import { StatusUpdateStage } from '../../../../../src/modules/orders/pipeline/stages/status-update.stage';
import { NotificationStage } from '../../../../../src/modules/orders/pipeline/stages/notification.stage';
import { OrderStatus } from '../../../../../src/common/enums/order-status.enum';
import { UserRole } from '../../../../../src/common/enums/user-role.enum';

describe('UpdateOrderPipeline', () => {
  let pipeline: UpdateOrderPipeline;

  const mockStage = (name: string) => ({
    execute: jest.fn(),
  });

  const mocks = {
    orderRepo: { save: jest.fn() },
    orderItemRepo: {},
    productRepo: {},
    validationStage: mockStage('Validation'),
    authorizationStage: mockStage('Authorization'),
    statusTransitionStage: mockStage('StatusTransition'),
    stockManagementStage: mockStage('StockManagement'),
    itemManagementStage: mockStage('ItemManagement'),
    statusUpdateStage: mockStage('StatusUpdate'),
    notificationStage: mockStage('Notification'),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UpdateOrderPipeline,
        { provide: getRepositoryToken(Order), useValue: mocks.orderRepo },
        {
          provide: getRepositoryToken(OrderItem),
          useValue: mocks.orderItemRepo,
        },
        { provide: getRepositoryToken(Product), useValue: mocks.productRepo },
        { provide: ValidationStage, useValue: mocks.validationStage },
        { provide: AuthorizationStage, useValue: mocks.authorizationStage },
        {
          provide: StatusTransitionStage,
          useValue: mocks.statusTransitionStage,
        },
        { provide: StockManagementStage, useValue: mocks.stockManagementStage },
        { provide: ItemManagementStage, useValue: mocks.itemManagementStage },
        { provide: StatusUpdateStage, useValue: mocks.statusUpdateStage },
        { provide: NotificationStage, useValue: mocks.notificationStage },
      ],
    }).compile();

    pipeline = module.get<UpdateOrderPipeline>(UpdateOrderPipeline);
  });

  afterEach(() => jest.clearAllMocks());

  it('should run all stages and return success', async () => {
    const successResult = {
      success: true,
      data: { order: { id: 1, status: OrderStatus.CONFIRMED } },
    };
    Object.values(mocks).forEach((m: any) => {
      if (m.execute) m.execute.mockResolvedValue(successResult);
    });

    const result = await pipeline.execute(
      1,
      OrderStatus.CONFIRMED,
      1,
      UserRole.ADMIN,
    );

    expect(result.success).toBe(true);
    expect(mocks.validationStage.execute).toHaveBeenCalled();
    expect(mocks.authorizationStage.execute).toHaveBeenCalled();
    expect(mocks.statusTransitionStage.execute).toHaveBeenCalled();
    expect(mocks.stockManagementStage.execute).toHaveBeenCalled();
    expect(mocks.itemManagementStage.execute).toHaveBeenCalled();
    expect(mocks.statusUpdateStage.execute).toHaveBeenCalled();
    expect(mocks.notificationStage.execute).toHaveBeenCalled();
  });

  it('should stop at first failure', async () => {
    mocks.validationStage.execute.mockResolvedValue({
      success: false,
      error: 'Invalid',
      stage: 'Validation',
    });
    const result = await pipeline.execute(
      1,
      OrderStatus.CONFIRMED,
      1,
      UserRole.ADMIN,
    );
    expect(result.success).toBe(false);
    expect(mocks.authorizationStage.execute).not.toHaveBeenCalled();
  });

  it('should pass all parameters through context', async () => {
    const successResult = { success: true, data: {} };
    Object.values(mocks).forEach((m: any) => {
      if (m.execute) m.execute.mockResolvedValue(successResult);
    });

    await pipeline.execute(
      1,
      OrderStatus.DELIVERED,
      1,
      UserRole.DELIVERY,
      'Delivered',
      { lat: 24.7, lng: 46.7 },
    );

    const ctx = mocks.validationStage.execute.mock.calls[0][0];
    expect(ctx.orderId).toBe(1);
    expect(ctx.newStatus).toBe(OrderStatus.DELIVERED);
    expect(ctx.role).toBe(UserRole.DELIVERY);
    expect(ctx.reason).toBe('Delivered');
    expect(ctx.finalLocation).toEqual({ lat: 24.7, lng: 46.7 });
  });
});

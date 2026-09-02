import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { StatusUpdateStage } from '../../../../../src/modules/orders/pipeline/stages/status-update.stage';
import { Order } from '../../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../../src/database/entities/product.entity';
import { DeliveryAssignmentService } from '../../../../../src/modules/orders/services/delivery-assignment.service';
import { FirebaseService } from '../../../../../src/modules/firebase/firebase.service';
import { LoyaltyService } from '../../../../../src/modules/loyalty/loyalty.service';
import { OrderStatus } from '../../../../../src/common/enums/order-status.enum';
import { UserRole } from '../../../../../src/common/enums/user-role.enum';

describe('StatusUpdateStage', () => {
  let stage: StatusUpdateStage;
  const mockOrderRepo = { save: jest.fn() };
  const mockDeliveryAssignmentService = { startSearchingForDriver: jest.fn() };
  const mockFirebaseService = {
    orderDocumentExists: jest.fn(),
    createOrderDocument: jest.fn(),
    updateOrderDocument: jest.fn(),
    deleteOrderDocument: jest.fn(),
  };
  const mockLoyaltyService = { processOrderDelivery: jest.fn() };

  beforeEach(async () => {
    jest.useFakeTimers();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StatusUpdateStage,
        { provide: getRepositoryToken(Order), useValue: mockOrderRepo },
        { provide: getRepositoryToken(OrderItem), useValue: {} },
        { provide: getRepositoryToken(Product), useValue: {} },
        {
          provide: DeliveryAssignmentService,
          useValue: mockDeliveryAssignmentService,
        },
        { provide: FirebaseService, useValue: mockFirebaseService },
        { provide: LoyaltyService, useValue: mockLoyaltyService },
      ],
    }).compile();
    stage = module.get<StatusUpdateStage>(StatusUpdateStage);
  });

  afterEach(() => {
    jest.clearAllMocks();
    jest.useRealTimers();
  });

  const baseCtx = (overrides = {}) => ({
    orderId: 1,
    newStatus: OrderStatus.CONFIRMED,
    userId: 1,
    role: UserRole.ADMIN,
    order: {
      id: 1,
      status: OrderStatus.PENDING,
      items: [],
      offers: [],
      deliveryCoordinates: { latitude: 24.7, longitude: 46.7 },
    },
    ...overrides,
  });

  it('should fail when order is null', async () => {
    const result = await stage.execute(baseCtx({ order: null }));
    expect(result.success).toBe(false);
  });

  it('should update order status and save', async () => {
    mockOrderRepo.save.mockResolvedValue({});
    mockFirebaseService.orderDocumentExists.mockResolvedValue(true);
    mockFirebaseService.updateOrderDocument.mockResolvedValue(undefined);
    const result = await stage.execute(baseCtx());
    expect(result.success).toBe(true);
    expect(mockOrderRepo.save).toHaveBeenCalled();
  });

  it('should set mealPreparationTime and deliveryTime on CONFIRMED', async () => {
    const order = { id: 1, status: OrderStatus.PENDING, items: [], offers: [] };
    mockOrderRepo.save.mockResolvedValue(order);
    mockFirebaseService.orderDocumentExists.mockResolvedValue(true);
    mockFirebaseService.updateOrderDocument.mockResolvedValue(undefined);
    await stage.execute(
      baseCtx({
        newStatus: OrderStatus.CONFIRMED,
        mealPreparationTime: 20,
        deliveryTime: 30,
      }),
    );
    expect(mockOrderRepo.save).toHaveBeenCalledWith(
      expect.objectContaining({
        mealPreparationTime: 20,
        deliveryTime: 30,
        deliveryDeadline: expect.any(Date),
      }),
    );
  });

  it('should trigger driver search on CONFIRMED', async () => {
    const order = { id: 1, status: OrderStatus.PENDING, items: [], offers: [] };
    mockOrderRepo.save.mockResolvedValue(order);
    mockFirebaseService.orderDocumentExists.mockResolvedValue(true);
    mockFirebaseService.updateOrderDocument.mockResolvedValue(undefined);
    mockDeliveryAssignmentService.startSearchingForDriver.mockResolvedValue(
      undefined,
    );
    await stage.execute(baseCtx({ newStatus: OrderStatus.CONFIRMED }));
    expect(
      mockDeliveryAssignmentService.startSearchingForDriver,
    ).toHaveBeenCalledWith(1);
  });

  it('should process loyalty and set finalLocation on DELIVERED', async () => {
    mockOrderRepo.save.mockResolvedValue({});
    mockFirebaseService.orderDocumentExists.mockResolvedValue(true);
    mockFirebaseService.updateOrderDocument.mockResolvedValue(undefined);
    mockLoyaltyService.processOrderDelivery.mockResolvedValue(undefined);
    await stage.execute(
      baseCtx({
        newStatus: OrderStatus.DELIVERED,
        finalLocation: { lat: 24.8, lng: 46.8 },
        order: {
          id: 1,
          customerId: 10,
          status: OrderStatus.ON_THE_WAY,
          items: [],
          offers: [],
          deliveryCoordinates: { latitude: 24.7, longitude: 46.7 },
        },
      }),
    );
    expect(mockLoyaltyService.processOrderDelivery).toHaveBeenCalledWith(10, 1);
  });

  it('should create Firebase document if missing', async () => {
    mockOrderRepo.save.mockResolvedValue({});
    mockFirebaseService.orderDocumentExists.mockResolvedValue(false);
    mockFirebaseService.createOrderDocument.mockResolvedValue(undefined);
    const result = await stage.execute(baseCtx());
    expect(result.success).toBe(true);
    expect(mockFirebaseService.createOrderDocument).toHaveBeenCalled();
  });

  it('should delete Firebase document on CANCELLED', async () => {
    mockOrderRepo.save.mockResolvedValue({});
    mockFirebaseService.orderDocumentExists.mockResolvedValue(true);
    mockFirebaseService.updateOrderDocument.mockResolvedValue(undefined);
    mockFirebaseService.deleteOrderDocument.mockResolvedValue(undefined);
    await stage.execute(baseCtx({ newStatus: OrderStatus.CANCELLED }));
    expect(mockFirebaseService.deleteOrderDocument).toHaveBeenCalledWith(1);
  });

  it('should clear previousStatus and cancelledAt when restoring from CANCELLED', async () => {
    const order = {
      id: 1,
      status: OrderStatus.CANCELLED,
      previousStatus: OrderStatus.PENDING,
      cancelledAt: new Date(),
      items: [],
      offers: [],
    };
    mockOrderRepo.save.mockResolvedValue(order);
    mockFirebaseService.orderDocumentExists.mockResolvedValue(true);
    mockFirebaseService.updateOrderDocument.mockResolvedValue(undefined);
    await stage.execute(
      baseCtx({
        order: {
          ...order,
          status: OrderStatus.CANCELLED,
          previousStatus: OrderStatus.PENDING,
          cancelledAt: new Date(),
        },
        newStatus: OrderStatus.PENDING,
      }),
    );
    expect(mockOrderRepo.save).toHaveBeenCalledWith(
      expect.objectContaining({ previousStatus: null, cancelledAt: null }),
    );
  });
});

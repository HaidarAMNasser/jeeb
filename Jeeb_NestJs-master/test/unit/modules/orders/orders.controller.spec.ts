import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { AuthGuard } from '../../../../src/common/guards/auth.guard';
import { OrdersController } from '../../../../src/modules/orders/orders.controller';
import { OrdersService } from '../../../../src/modules/orders/services/orders.service';
import { UnassignDriverService } from '../../../../src/modules/orders/services/unassign-driver.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { OrderStatus } from '../../../../src/common/enums/order-status.enum';

describe('OrdersController', () => {
  let controller: OrdersController;

  const mockOrdersService = {
    create: jest.fn(),
    findAll: jest.fn(),
    findOne: jest.fn(),
    updateOrderStatus: jest.fn(),
    updateOrder: jest.fn(),
    uploadPaid: jest.fn(),
    sendDeliveryNotifications: jest.fn(),
    acceptDeliveryAssignment: jest.fn(),
    rejectDeliveryAssignment: jest.fn(),
  };

  const mockUnassignDriverService = {
    execute: jest.fn(),
  };

  const mockUser = { id: 1, role: UserRole.ADMIN };
  const mockDeliveryUser = { id: 30, role: UserRole.DELIVERY };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [OrdersController],
      providers: [
        { provide: OrdersService, useValue: mockOrdersService },
        { provide: UnassignDriverService, useValue: mockUnassignDriverService },
      ],
    })
      .overrideGuard(AuthGuard)
      .useValue({ canActivate: jest.fn(() => true) })
      .compile();

    controller = module.get<OrdersController>(OrdersController);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    it('should create order with user id', async () => {
      const dto = { items: [{ productId: 100, quantity: 1 }] };
      mockOrdersService.create.mockResolvedValue({ id: 1 });

      const result = await controller.create(dto as any, mockUser);

      expect(mockOrdersService.create).toHaveBeenCalledWith(dto, 1);
      expect(result).toEqual({ id: 1 });
    });

    it('should use default user id when user is null', async () => {
      const dto = { items: [] };
      mockOrdersService.create.mockResolvedValue({ id: 1 });

      const result = await controller.create(dto as any, null);

      expect(mockOrdersService.create).toHaveBeenCalledWith(dto, 1);
    });
  });

  describe('findAll', () => {
    it('should delegate to ordersService.findAll', async () => {
      const query = { page: 1, limit: 10 };
      mockOrdersService.findAll.mockResolvedValue({ data: [], total: 0 });

      const result = await controller.findAll(query as any, mockUser);

      expect(mockOrdersService.findAll).toHaveBeenCalledWith(
        query,
        1,
        UserRole.ADMIN,
        undefined,
      );
      expect(result).toEqual({ data: [], total: 0 });
    });
  });

  describe('findOne', () => {
    it('should delegate to ordersService.findOne', async () => {
      mockOrdersService.findOne.mockResolvedValue({ id: 1 });

      const result = await controller.findOne('1', mockUser);

      expect(mockOrdersService.findOne).toHaveBeenCalledWith(
        1,
        1,
        UserRole.ADMIN,
      );
      expect(result).toEqual({ id: 1 });
    });
  });

  describe('uploadPaid', () => {
    it('should upload paid receipt for delivery user', async () => {
      const body = { orderIds: '[1, 2]' };
      const files = [{ filename: 'receipt.jpg' }] as any;
      mockOrdersService.uploadPaid.mockResolvedValue({ success: true });

      const result = await controller.uploadPaid(body, files, mockDeliveryUser);

      expect(mockOrdersService.uploadPaid).toHaveBeenCalledWith(
        [1, 2],
        files,
        30,
        UserRole.DELIVERY,
      );
      expect(result).toEqual({ success: true });
    });

    it('should reject when user is not delivery', async () => {
      const result = await controller.uploadPaid({}, [], mockUser);

      expect(result).toEqual({
        message: 'Only delivery drivers can upload payment receipts',
      });
    });

    it('should return auth message when user is null', async () => {
      const result = await controller.uploadPaid({}, [], null);

      expect(result).toEqual({ message: 'Authentication required' });
    });
  });

  describe('updateOrderStatus', () => {
    it('should update order status with valid status string', async () => {
      mockOrdersService.findOne.mockResolvedValue({
        status: OrderStatus.PENDING,
      });
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.CONFIRMED,
      });

      const result = await controller.updateOrderStatus(
        1,
        'confirm',
        {} as any,
        mockUser,
      );

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.CONFIRMED,
        1,
        UserRole.ADMIN,
        undefined,
        undefined,
        undefined,
        undefined,
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.CONFIRMED });
    });

    it('should send delivery notifications when status is READY_FOR_PICKUP', async () => {
      mockOrdersService.findOne.mockResolvedValue({
        status: OrderStatus.PREPARING,
      });
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.READY_FOR_PICKUP,
      });
      mockOrdersService.sendDeliveryNotifications.mockResolvedValue(undefined);

      await controller.updateOrderStatus(1, 'ready', {} as any, mockUser);

      expect(mockOrdersService.sendDeliveryNotifications).toHaveBeenCalledWith(
        1,
      );
    });

    it('should throw BadRequestException for invalid status', async () => {
      await expect(
        controller.updateOrderStatus(1, 'invalid_status', {} as any, mockUser),
      ).rejects.toThrow(BadRequestException);
    });

    it('should return auth message when user is null', async () => {
      const result = await controller.updateOrderStatus(
        1,
        'confirm',
        {} as any,
        null,
      );

      expect(result).toEqual({ message: 'Authentication required' });
    });
  });

  describe('updateOrder', () => {
    it('should delegate to ordersService.updateOrder', async () => {
      const dto = { items: [] };
      mockOrdersService.updateOrder.mockResolvedValue({ id: 1 });

      const result = await controller.updateOrder('1', dto as any, mockUser);

      expect(mockOrdersService.updateOrder).toHaveBeenCalledWith(
        1,
        1,
        UserRole.ADMIN,
        dto,
      );
      expect(result).toEqual({ id: 1 });
    });

    it('should return auth message when user is null', async () => {
      const result = await controller.updateOrder('1', {} as any, null);

      expect(result).toEqual({ message: 'Authentication required' });
    });
  });

  describe('confirmOrder', () => {
    it('should update order status to CONFIRMED', async () => {
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.CONFIRMED,
      });

      const result = await controller.confirmOrder('1', {} as any, mockUser);

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.CONFIRMED,
        1,
        UserRole.ADMIN,
        'Order confirmed by merchant/admin',
        undefined,
        undefined,
        undefined,
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.CONFIRMED });
    });
  });

  describe('cancelOrder', () => {
    it('should update order status to CANCELLED with reason', async () => {
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.CANCELLED,
      });

      const result = await controller.cancelOrder(
        '1',
        'Customer request',
        mockUser,
      );

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.CANCELLED,
        1,
        UserRole.ADMIN,
        'Customer request',
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.CANCELLED });
    });

    it('should use default reason when not provided', async () => {
      mockOrdersService.updateOrderStatus.mockResolvedValue({});

      await controller.cancelOrder('1', undefined, mockUser);

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.CANCELLED,
        1,
        UserRole.ADMIN,
        'Order cancelled',
      );
    });
  });

  describe('rejectOrder', () => {
    it('should update order status to REJECTED with reason', async () => {
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.REJECTED,
      });

      const result = await controller.rejectOrder(
        '1',
        'Out of stock',
        mockUser,
      );

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.REJECTED,
        1,
        UserRole.ADMIN,
        'Out of stock',
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.REJECTED });
    });
  });

  describe('startPreparing', () => {
    it('should update order status to PREPARING', async () => {
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.PREPARING,
      });

      const result = await controller.startPreparing(
        '1',
        'Preparing order',
        mockUser,
      );

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.PREPARING,
        1,
        UserRole.ADMIN,
        'Preparing order',
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.PREPARING });
    });
  });

  describe('readyForPickup', () => {
    it('should update order status to READY_FOR_PICKUP', async () => {
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.READY_FOR_PICKUP,
      });

      const result = await controller.readyForPickup('1', 'Ready', mockUser);

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.READY_FOR_PICKUP,
        1,
        UserRole.ADMIN,
        'Ready',
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.READY_FOR_PICKUP });
    });
  });

  describe('pickedUp', () => {
    it('should update order status to PICKED_UP', async () => {
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.PICKED_UP,
      });

      const result = await controller.pickedUp('1', 'Picked', mockUser);

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.PICKED_UP,
        1,
        UserRole.ADMIN,
        'Picked',
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.PICKED_UP });
    });
  });

  describe('onTheWay', () => {
    it('should update order status to ON_THE_WAY', async () => {
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.ON_THE_WAY,
      });

      const result = await controller.onTheWay('1', 'On the way', mockUser);

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.ON_THE_WAY,
        1,
        UserRole.ADMIN,
        'On the way',
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.ON_THE_WAY });
    });
  });

  describe('delivered', () => {
    it('should update order status to DELIVERED with location', async () => {
      const body = {
        reason: 'Delivered',
        finalLocation: { lat: 24.7, lng: 46.7 },
      };
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.DELIVERED,
      });

      const result = await controller.delivered('1', body, mockUser);

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.DELIVERED,
        1,
        UserRole.ADMIN,
        'Delivered',
        { lat: 24.7, lng: 46.7 },
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.DELIVERED });
    });
  });

  describe('restoreToPending', () => {
    it('should update order status to PENDING', async () => {
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.PENDING,
      });

      const result = await controller.restoreToPending('1', mockUser);

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.PENDING,
        1,
        UserRole.ADMIN,
        'Order restored to pending',
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.PENDING });
    });
  });

  describe('completeOrder', () => {
    it('should complete order for ADMIN role', async () => {
      mockOrdersService.updateOrderStatus.mockResolvedValue({
        id: 1,
        status: OrderStatus.COMPLETE,
      });

      const result = await controller.completeOrder('1', mockUser);

      expect(mockOrdersService.updateOrderStatus).toHaveBeenCalledWith(
        1,
        OrderStatus.COMPLETE,
        1,
        UserRole.ADMIN,
        'Order completed by admin',
      );
      expect(result).toEqual({ id: 1, status: OrderStatus.COMPLETE });
    });

    it('should reject when user is not admin', async () => {
      const result = await controller.completeOrder('1', {
        id: 2,
        role: UserRole.MERCHANT,
      });

      expect(result).toEqual({ message: 'Only admins can complete orders' });
    });
  });

  describe('sendDeliveryNotifications', () => {
    it('should delegate to ordersService.sendDeliveryNotifications', async () => {
      mockOrdersService.sendDeliveryNotifications.mockResolvedValue({
        success: true,
      });

      const result = await controller.sendDeliveryNotifications('1', mockUser);

      expect(mockOrdersService.sendDeliveryNotifications).toHaveBeenCalledWith(
        1,
      );
      expect(result).toEqual({ success: true });
    });
  });

  describe('acceptDeliveryAssignment', () => {
    it('should accept delivery for DELIVERY role', async () => {
      mockOrdersService.acceptDeliveryAssignment.mockResolvedValue({
        assigned: true,
      });

      const result = await controller.acceptDeliveryAssignment(
        '1',
        { deliveryTime: 25 },
        mockDeliveryUser,
      );

      expect(mockOrdersService.acceptDeliveryAssignment).toHaveBeenCalledWith(
        1,
        30,
        25,
      );
      expect(result).toEqual({ assigned: true });
    });

    it('should reject when user is not delivery', async () => {
      const result = await controller.acceptDeliveryAssignment(
        '1',
        {},
        mockUser,
      );

      expect(result).toEqual({
        message: 'Only delivery drivers can accept assignments',
      });
    });
  });

  describe('rejectDeliveryAssignment', () => {
    it('should reject delivery for DELIVERY role with reason', async () => {
      mockOrdersService.rejectDeliveryAssignment.mockResolvedValue({
        rejected: true,
      });

      const result = await controller.rejectDeliveryAssignment(
        '1',
        'Too far',
        mockDeliveryUser,
      );

      expect(mockOrdersService.rejectDeliveryAssignment).toHaveBeenCalledWith(
        1,
        30,
        'Too far',
      );
      expect(result).toEqual({ rejected: true });
    });

    it('should reject when user is not delivery', async () => {
      const result = await controller.rejectDeliveryAssignment(
        '1',
        'reason',
        mockUser,
      );

      expect(result).toEqual({
        message: 'Only delivery drivers can accept assignments',
      });
    });
  });
});

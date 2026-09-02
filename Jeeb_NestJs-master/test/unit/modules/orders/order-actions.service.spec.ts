import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { Repository } from 'typeorm';
import { OrderActionsService } from '../../../../src/modules/orders/services/order-actions.service';
import { OrderAccessValidator } from '../../../../src/modules/orders/validators/order-access.validator';
import { DeliveryNotificationService } from '../../../../src/modules/orders/services/delivery-notification.service';
import { NotificationsService } from '../../../../src/modules/notifications/notifications.service';
import { FirebaseService } from '../../../../src/modules/firebase/firebase.service';
import { DeliveryAssignmentService } from '../../../../src/modules/orders/services/delivery-assignment.service';
import { OrderStatus, DeliveryStatus } from '../../../../src/common/enums';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { NotificationChannel } from '../../../../src/common/enums/notification-channel.enum';
import { NotificationType } from '../../../../src/common/enums/notification-type.enum';
import { Order } from '../../../../src/database/entities/order.entity';
import { OrderItem } from '../../../../src/database/entities/order-item.entity';
import { Product } from '../../../../src/database/entities/product.entity';
import { DeliveryAssignment } from '../../../../src/database/entities/delivery-assignment.entity';
import { DiscountType } from '../../../../src/common/enums/discount-type.enum';

describe('OrderActionsService', () => {
  let service: OrderActionsService;
  let orderRepo: jest.Mocked<Repository<Order>>;
  let orderItemRepo: jest.Mocked<Repository<OrderItem>>;
  let productRepo: jest.Mocked<Repository<Product>>;
  let deliveryAssignmentRepo: jest.Mocked<Repository<DeliveryAssignment>>;
  let orderAccessValidator: jest.Mocked<OrderAccessValidator>;
  let deliveryNotificationService: jest.Mocked<DeliveryNotificationService>;
  let notificationsService: jest.Mocked<NotificationsService>;
  let firebaseService: jest.Mocked<FirebaseService>;
  let deliveryAssignmentService: jest.Mocked<DeliveryAssignmentService>;

  const mockOrderId = 1;
  const mockUserId = 10;
  const mockCustomerId = 10;
  const mockMerchantId = 20;

  const createMockOrder = (
    status: OrderStatus = OrderStatus.PENDING,
  ): Partial<Order> => ({
    id: mockOrderId,
    customerId: mockCustomerId,
    ownerId: mockMerchantId,
    status,
    items: [],
    deliveryAssignments: [],
  });

  const mockAssignment: Partial<DeliveryAssignment> = {
    id: 1,
    orderId: mockOrderId,
    deliveryId: 30,
    status: DeliveryStatus.ACCEPTED,
  };

  const mockProductWithStock: Partial<Product> = {
    id: 100,
    hasStock: true,
    stockQuantity: 10,
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrderActionsService,
        {
          provide: getRepositoryToken(Order),
          useValue: { findOne: jest.fn(), save: jest.fn() },
        },
        {
          provide: getRepositoryToken(OrderItem),
          useValue: { find: jest.fn() },
        },
        {
          provide: getRepositoryToken(Product),
          useValue: { findOne: jest.fn(), increment: jest.fn(), find: jest.fn().mockResolvedValue([]) },
        },
        {
          provide: getRepositoryToken(DeliveryAssignment),
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
          },
        },
        {
          provide: OrderAccessValidator,
          useValue: {
            validateOrderModificationAccess: jest.fn(),
            validateOrderStatusUpdateAccess: jest.fn(),
            validateStatusTransition: jest.fn(),
          },
        },
        {
          provide: DeliveryNotificationService,
          useValue: { notifyReadyForOrder: jest.fn() },
        },
        {
          provide: NotificationsService,
          useValue: { sendToUser: jest.fn() },
        },
        {
          provide: FirebaseService,
          useValue: {
            orderDocumentExists: jest.fn(),
            updateOrderDocument: jest.fn(),
            setDeliveryId: jest.fn(),
          },
        },
        {
          provide: DeliveryAssignmentService,
          useValue: { cancelPendingDeliveryNotifications: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<OrderActionsService>(OrderActionsService);
    orderRepo = module.get(getRepositoryToken(Order));
    orderItemRepo = module.get(getRepositoryToken(OrderItem));
    productRepo = module.get(getRepositoryToken(Product));
    deliveryAssignmentRepo = module.get(getRepositoryToken(DeliveryAssignment));
    orderAccessValidator = module.get(OrderAccessValidator);
    deliveryNotificationService = module.get(DeliveryNotificationService);
    notificationsService = module.get(NotificationsService);
    firebaseService = module.get(FirebaseService);
    deliveryAssignmentService = module.get(DeliveryAssignmentService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('confirmOrder', () => {
    it('يؤكد الطلب ويعيده', async () => {
      const order = createMockOrder();
      orderRepo.findOne.mockResolvedValue(order as Order);
      orderRepo.save.mockResolvedValue({
        ...order,
        status: OrderStatus.CONFIRMED,
      } as Order);

      const result = await service.confirmOrder(
        mockOrderId,
        mockUserId,
        UserRole.MERCHANT,
      );

      expect(result.status).toBe(OrderStatus.CONFIRMED);
      expect(orderRepo.save).toHaveBeenCalled();
    });

    it('يرمي NotFoundException إذا كان الطلب غير موجود', async () => {
      orderRepo.findOne.mockResolvedValue(null);

      await expect(
        service.confirmOrder(999, mockUserId, UserRole.MERCHANT),
      ).rejects.toThrow(NotFoundException);
    });

    it('يرمي BadRequestException إذا لم يكن PENDING', async () => {
      orderRepo.findOne.mockResolvedValue(
        createMockOrder(OrderStatus.DELIVERED) as Order,
      );

      await expect(
        service.confirmOrder(mockOrderId, mockUserId, UserRole.MERCHANT),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('rejectOrder', () => {
    it('يرفض الطلب ويعيد المخزون', async () => {
      const order = createMockOrder();
      orderRepo.findOne.mockResolvedValue(order as Order);
      orderItemRepo.find.mockResolvedValue([
        { id: 1, productId: 100, quantity: 2, offerId: null } as OrderItem,
      ]);
      productRepo.find.mockResolvedValue([mockProductWithStock as Product]);
      orderRepo.save.mockResolvedValue({
        ...order,
        status: OrderStatus.REJECTED,
      } as Order);

      const result = await service.rejectOrder(
        mockOrderId,
        mockUserId,
        UserRole.MERCHANT,
        'Out of stock',
      );

      expect(result.status).toBe(OrderStatus.REJECTED);
      expect(productRepo.increment).toHaveBeenCalledWith(
        { id: 100 },
        'stockQuantity',
        2,
      );
    });
  });

  describe('updateOrderStatus', () => {
    it('يحدّث الحالة ويعيد الطلب', async () => {
      const order = createMockOrder();
      orderRepo.findOne.mockResolvedValue(order as Order);
      orderRepo.save.mockResolvedValue({
        ...order,
        status: OrderStatus.CONFIRMED,
      } as Order);
      firebaseService.orderDocumentExists.mockResolvedValue(false);

      const result = await service.updateOrderStatus(
        mockOrderId,
        OrderStatus.CONFIRMED,
        mockUserId,
        UserRole.MERCHANT,
      );

      expect(result.status).toBe(OrderStatus.CONFIRMED);
      expect(
        orderAccessValidator.validateOrderStatusUpdateAccess,
      ).toHaveBeenCalled();
      expect(
        orderAccessValidator.validateStatusTransition,
      ).toHaveBeenCalledWith(OrderStatus.PENDING, OrderStatus.CONFIRMED);
    });

    it('يعيد المخزون عند الإلغاء', async () => {
      const order = createMockOrder();
      orderRepo.findOne.mockResolvedValue(order as Order);
      orderItemRepo.find.mockResolvedValue([
        { id: 1, productId: 100, quantity: 2, offerId: null } as OrderItem,
      ]);
      productRepo.find.mockResolvedValue([mockProductWithStock as Product]);
      orderRepo.save.mockResolvedValue({
        ...order,
        status: OrderStatus.CANCELLED,
      } as Order);
      firebaseService.orderDocumentExists.mockResolvedValue(false);

      const result = await service.updateOrderStatus(
        mockOrderId,
        OrderStatus.CANCELLED,
        mockCustomerId,
        UserRole.CUSTOMER,
        'Changed mind',
      );

      expect(result.status).toBe(OrderStatus.CANCELLED);
      expect(productRepo.increment).toHaveBeenCalled();
    });

    it('يُحدّث Firebase إذا كان المستند موجوداً', async () => {
      const order = createMockOrder();
      orderRepo.findOne.mockResolvedValue(order as Order);
      orderRepo.save.mockResolvedValue({
        ...order,
        status: OrderStatus.CONFIRMED,
      } as Order);
      firebaseService.orderDocumentExists.mockResolvedValue(true);
      deliveryAssignmentRepo.findOne.mockResolvedValue(null);

      await service.updateOrderStatus(
        mockOrderId,
        OrderStatus.CONFIRMED,
        mockUserId,
        UserRole.MERCHANT,
      );

      expect(firebaseService.updateOrderDocument).toHaveBeenCalledWith(
        mockOrderId,
        OrderStatus.CONFIRMED,
      );
    });

    it('يُرسل إشعار READY_FOR_PICKUP عبر DeliveryNotificationService', async () => {
      const order = createMockOrder();
      orderRepo.findOne.mockResolvedValue(order as Order);
      orderRepo.save.mockResolvedValue({
        ...order,
        status: OrderStatus.READY_FOR_PICKUP,
      } as Order);
      firebaseService.orderDocumentExists.mockResolvedValue(false);

      await service.updateOrderStatus(
        mockOrderId,
        OrderStatus.READY_FOR_PICKUP,
        mockUserId,
        UserRole.MERCHANT,
      );

      expect(
        deliveryNotificationService.notifyReadyForOrder,
      ).toHaveBeenCalledWith(mockOrderId);
    });

    it('يرمي NotFoundException إذا كان الطلب غير موجود', async () => {
      orderRepo.findOne.mockResolvedValue(null);

      await expect(
        service.updateOrderStatus(
          999,
          OrderStatus.CONFIRMED,
          mockUserId,
          UserRole.MERCHANT,
        ),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('sendStatusNotifications', () => {
    it('يُرسل إشعار للعميل عند التأكيد (التاجر ليس لديه إشعار CONFIRMED)', async () => {
      const order = createMockOrder(OrderStatus.CONFIRMED) as Order;
      deliveryAssignmentRepo.findOne.mockResolvedValue(null);

      await service.sendStatusNotifications(order, OrderStatus.CONFIRMED);

      // CONFIRMED: customer فقط (التاجر ليس لديه إشعار CONFIRMED)
      expect(notificationsService.sendToUser).toHaveBeenCalledTimes(1);
      expect(notificationsService.sendToUser).toHaveBeenCalledWith(
        mockCustomerId,
        NotificationType.ORDER_CONFIRMED,
        expect.any(String),
        expect.any(String),
        NotificationChannel.FIREBASE,
        expect.any(Object),
      );
    });

    it('يُحدّث حالة DeliveryAssignment عند PICKED_UP', async () => {
      const order = createMockOrder() as Order;
      deliveryAssignmentRepo.findOne.mockResolvedValue(
        mockAssignment as DeliveryAssignment,
      );
      deliveryAssignmentRepo.save.mockResolvedValue({
        ...mockAssignment,
        status: DeliveryStatus.PICKED,
      } as DeliveryAssignment);

      await service.sendStatusNotifications(order, OrderStatus.PICKED_UP);

      expect(deliveryAssignmentRepo.save).toHaveBeenCalledWith(
        expect.objectContaining({ status: DeliveryStatus.PICKED }),
      );
    });
  });

  describe('cancelOrder', () => {
    it('يلغي الطلب عبر updateOrderStatus', async () => {
      const order = createMockOrder();
      orderRepo.findOne.mockResolvedValue(order as Order);
      orderItemRepo.find.mockResolvedValue([]);
      orderRepo.save.mockResolvedValue({
        ...order,
        status: OrderStatus.CANCELLED,
      } as Order);
      firebaseService.orderDocumentExists.mockResolvedValue(false);

      const result = await service.cancelOrder(
        mockOrderId,
        mockCustomerId,
        UserRole.CUSTOMER,
      );

      expect(result.status).toBe(OrderStatus.CANCELLED);
    });
  });
});

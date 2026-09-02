import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, BadRequestException } from '@nestjs/common';
import { OrderAccessValidator } from '../../../../src/modules/orders/validators/order-access.validator';
import { SettingsService } from '../../../../src/modules/settings/settings.service';
import { UserRole } from '../../../../src/common/enums/user-role.enum';
import { OrderStatus, DeliveryStatus } from '../../../../src/common/enums';
import { Order } from '../../../../src/database/entities/order.entity';

describe('OrderAccessValidator', () => {
  let validator: OrderAccessValidator;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrderAccessValidator,
        { provide: SettingsService, useValue: { getSettingByKey: jest.fn() } },
      ],
    }).compile();

    validator = module.get<OrderAccessValidator>(OrderAccessValidator);
  });

  describe('validateOrderAccess', () => {
    const mockOrder = {
      id: 1,
      customerId: 10,
      ownerId: 20,
      deliveryAssignments: [],
    } as Order;

    it('يسمح لـ ADMIN برؤية أي طلب', () => {
      const result = validator.validateOrderAccess(mockOrder, {
        role: UserRole.ADMIN,
        userId: 1,
      });
      expect(result.canAccess).toBe(true);
    });

    it('يسمح لـ MERCHANT برؤية طلبه', () => {
      const result = validator.validateOrderAccess(mockOrder, {
        role: UserRole.MERCHANT,
        userId: 20,
      });
      expect(result.canAccess).toBe(true);
    });

    it('يرفض MERCHANT رؤية طلب غيره', () => {
      const result = validator.validateOrderAccess(mockOrder, {
        role: UserRole.MERCHANT,
        userId: 99,
      });
      expect(result.canAccess).toBe(false);
    });

    it('يسمح لـ CUSTOMER برؤية طلبه', () => {
      const result = validator.validateOrderAccess(mockOrder, {
        role: UserRole.CUSTOMER,
        userId: 10,
      });
      expect(result.canAccess).toBe(true);
    });

    it('يسمح لـ DELIVERY برؤية الطلب المعيّن له', () => {
      const assignedOrder = {
        ...mockOrder,
        deliveryAssignments: [{ deliveryId: 30 }],
      } as Order;
      const result = validator.validateOrderAccess(assignedOrder, {
        role: UserRole.DELIVERY,
        userId: 30,
      });
      expect(result.canAccess).toBe(true);
    });
  });

  describe('validateOrderModificationAccess', () => {
    it('يسمح لـ ADMIN', () => {
      expect(() =>
        validator.validateOrderModificationAccess(
          {} as Order,
          UserRole.ADMIN,
          1,
          'update',
        ),
      ).not.toThrow();
    });

    it('يسمح لـ MERCHANT لطلبه', () => {
      expect(() =>
        validator.validateOrderModificationAccess(
          { ownerId: 20 } as Order,
          UserRole.MERCHANT,
          20,
          'update',
        ),
      ).not.toThrow();
    });

    it('يرفض MERCHANT لتعديل طلب غيره', () => {
      expect(() =>
        validator.validateOrderModificationAccess(
          { ownerId: 20 } as Order,
          UserRole.MERCHANT,
          99,
          'update',
        ),
      ).toThrow(ForbiddenException);
    });

    it('يرفض CUSTOMER', () => {
      expect(() =>
        validator.validateOrderModificationAccess(
          {} as Order,
          UserRole.CUSTOMER,
          10,
          'update',
        ),
      ).toThrow(ForbiddenException);
    });
  });

  describe('validateOrderStatusUpdateAccess', () => {
    it('يسمح لـ ADMIN', () => {
      expect(() =>
        validator.validateOrderStatusUpdateAccess(
          {} as Order,
          OrderStatus.CONFIRMED,
          UserRole.ADMIN,
          1,
        ),
      ).not.toThrow();
    });

    it('يسمح لـ MERCHANT لطلبه', () => {
      expect(() =>
        validator.validateOrderStatusUpdateAccess(
          { ownerId: 20 } as Order,
          OrderStatus.CONFIRMED,
          UserRole.MERCHANT,
          20,
        ),
      ).not.toThrow();
    });

    it('يسمح لـ CUSTOMER بإلغاء طلبه', () => {
      expect(() =>
        validator.validateOrderStatusUpdateAccess(
          { customerId: 10, status: OrderStatus.PENDING } as Order,
          OrderStatus.CANCELLED,
          UserRole.CUSTOMER,
          10,
        ),
      ).not.toThrow();
    });

    it('يرفض CUSTOMER تغيير حالة غير CANCELLED', () => {
      expect(() =>
        validator.validateOrderStatusUpdateAccess(
          { customerId: 10 } as Order,
          OrderStatus.CONFIRMED,
          UserRole.CUSTOMER,
          10,
        ),
      ).toThrow(ForbiddenException);
    });

    it('يرفض CUSTOMER الإلغاء بعد READY_FOR_PICKUP', () => {
      expect(() =>
        validator.validateOrderStatusUpdateAccess(
          { customerId: 10, status: OrderStatus.DELIVERED } as Order,
          OrderStatus.CANCELLED,
          UserRole.CUSTOMER,
          10,
        ),
      ).toThrow(BadRequestException);
    });
  });

  describe('validateStatusTransition', () => {
    it('يسمح PENDING -> CONFIRMED', () => {
      expect(() =>
        validator.validateStatusTransition(
          OrderStatus.PENDING,
          OrderStatus.CONFIRMED,
        ),
      ).not.toThrow();
    });

    it('يسمح PENDING -> CANCELLED', () => {
      expect(() =>
        validator.validateStatusTransition(
          OrderStatus.PENDING,
          OrderStatus.CANCELLED,
        ),
      ).not.toThrow();
    });

    it('يسمح DELIVERED -> PAID', () => {
      expect(() =>
        validator.validateStatusTransition(
          OrderStatus.DELIVERED,
          OrderStatus.PAID,
        ),
      ).not.toThrow();
    });

    it('يرفض PENDING -> DELIVERED', () => {
      expect(() =>
        validator.validateStatusTransition(
          OrderStatus.PENDING,
          OrderStatus.DELIVERED,
        ),
      ).toThrow(BadRequestException);
    });

    it('يرفض COMPLETE -> أي حالة', () => {
      expect(() =>
        validator.validateStatusTransition(
          OrderStatus.COMPLETE,
          OrderStatus.PENDING,
        ),
      ).toThrow(BadRequestException);
    });
  });
});

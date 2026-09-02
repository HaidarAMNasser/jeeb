import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { BadRequestException } from '@nestjs/common';
import { DeliveryRestrictionService } from '../../../../src/modules/orders/services/delivery-restriction.service';
import { Order } from '../../../../src/database/entities/order.entity';
import { DeliveryAssignment } from '../../../../src/database/entities/delivery-assignment.entity';
import { DeliveryStatus } from '../../../../src/common/enums/delivery-status.enum';
import { OrderStatus } from '../../../../src/common/enums/order-status.enum';

describe('DeliveryRestrictionService', () => {
  let service: DeliveryRestrictionService;
  let orderRepo: jest.Mocked<any>;
  let assignmentRepo: jest.Mocked<any>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeliveryRestrictionService,
        { provide: getRepositoryToken(Order), useValue: {} },
        {
          provide: getRepositoryToken(DeliveryAssignment),
          useValue: { find: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<DeliveryRestrictionService>(
      DeliveryRestrictionService,
    );
    orderRepo = module.get(getRepositoryToken(Order));
    assignmentRepo = module.get(getRepositoryToken(DeliveryAssignment));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('checkIncompleteOrders', () => {
    it('يرجع أنه لا يوجد طلبات غير مكتملة', async () => {
      assignmentRepo.find.mockResolvedValue([]);

      const result = await service.checkIncompleteOrders(1);

      expect(result.hasIncompleteOrders).toBe(false);
      expect(result.incompleteCount).toBe(0);
    });

    it('يرجع عدد الطلبات غير المكتملة', async () => {
      const mockAssignments = [
        {
          order: { status: OrderStatus.PICKED_UP },
          deliveryId: 1,
          status: DeliveryStatus.ACCEPTED,
        },
        {
          order: { status: OrderStatus.ON_THE_WAY },
          deliveryId: 1,
          status: DeliveryStatus.ACCEPTED,
        },
      ];
      assignmentRepo.find.mockResolvedValue(mockAssignments);

      const result = await service.checkIncompleteOrders(1);

      expect(result.incompleteCount).toBeGreaterThan(0);
    });
  });

  describe('validateDeliveryRestrictions', () => {
    it('يرمي BadRequestException إذا كان هناك طلبات غير مكتملة', async () => {
      // MAX_INCOMPLETE_ORDERS = 0 in constants
      assignmentRepo.find.mockResolvedValue([
        {
          order: { status: OrderStatus.PICKED_UP },
          deliveryId: 1,
          status: DeliveryStatus.ACCEPTED,
        },
      ]);

      await expect(
        service.validateDeliveryRestrictions(1, 'accept new order'),
      ).rejects.toThrow(BadRequestException);
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { DeliveryNotificationService } from '../../../../src/modules/orders/services/delivery-notification.service';
import { DeliveryAssignment } from '../../../../src/database/entities/delivery-assignment.entity';

describe('DeliveryNotificationService', () => {
  let service: DeliveryNotificationService;

  const mockDeliveryAssignmentRepo = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeliveryNotificationService,
        {
          provide: getRepositoryToken(DeliveryAssignment),
          useValue: mockDeliveryAssignmentRepo,
        },
      ],
    }).compile();

    service = module.get<DeliveryNotificationService>(
      DeliveryNotificationService,
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('notifyReadyForOrder', () => {
    it('should log notification for order', async () => {
      const loggerSpy = jest.spyOn(service['logger'], 'log');
      const debugSpy = jest.spyOn(service['logger'], 'debug');

      await service.notifyReadyForOrder(1);

      expect(loggerSpy).toHaveBeenCalledWith(
        expect.stringContaining('notifyReadyForOrder called for order 1'),
      );
      expect(debugSpy).toHaveBeenCalledWith(
        expect.stringContaining('Order 1 ready for pickup'),
      );
    });
  });

  describe('handleNotificationResult', () => {
    it('should log success when notification succeeds', async () => {
      const loggerSpy = jest.spyOn(service['logger'], 'log');

      await service.handleNotificationResult(10, true);

      expect(loggerSpy).toHaveBeenCalledWith(
        expect.stringContaining(
          'Notification sent successfully for assignment 10',
        ),
      );
    });

    it('should log error when notification fails', async () => {
      const errorSpy = jest.spyOn(service['logger'], 'error');

      await service.handleNotificationResult(10, false, 'Connection timeout');

      expect(errorSpy).toHaveBeenCalledWith(
        expect.stringContaining('for assignment 10: Connection timeout'),
      );
    });

    it('should log error with default message when error not provided', async () => {
      const errorSpy = jest.spyOn(service['logger'], 'error');

      await service.handleNotificationResult(10, false);

      expect(errorSpy).toHaveBeenCalledWith(
        expect.stringContaining('for assignment 10: Unknown error'),
      );
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { DistanceController } from '../../../../src/modules/distance/distance.controller';
import { DistanceService } from '../../../../src/modules/distance/distance.service';

describe('DistanceController', () => {
  let controller: DistanceController;
  let distanceService: jest.Mocked<DistanceService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [DistanceController],
      providers: [
        {
          provide: DistanceService,
          useValue: {
            calculateDistanceWithTip: jest.fn(),
            calculateDeliveryCostWithProducts: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<DistanceController>(DistanceController);
    distanceService = module.get(DistanceService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('calculateDistance', () => {
    it('should return distance result', async () => {
      const dto = { source: { lat: 25.2, lng: 55.3 }, destination: { lat: 25.3, lng: 55.4 } };
      const expected = { distance: 15000, distanceKm: 15, estimatedTip: 1000 };
      distanceService.calculateDistanceWithTip.mockResolvedValue(expected as any);

      const result = await controller.calculateDistance(dto);

      expect(distanceService.calculateDistanceWithTip).toHaveBeenCalledWith(dto.source, dto.destination);
      expect(result).toEqual({ success: true, data: expected });
    });
  });

  describe('calculateDeliveryCost', () => {
    it('should return delivery cost result', async () => {
      const dto = { merchantId: 1, destination: { lat: 25.2, lng: 55.3 }, products: [] };
      const expected = { distance: 15000, deliveryCost: 1000, products: [] };
      distanceService.calculateDeliveryCostWithProducts.mockResolvedValue(expected as any);

      const result = await controller.calculateDeliveryCost(dto as any);

      expect(distanceService.calculateDeliveryCostWithProducts).toHaveBeenCalledWith(1, dto.destination, []);
      expect(result).toEqual({ success: true, data: expected });
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { FirebaseDriverLocatorService } from '../../../../src/modules/orders/services/firebase-driver-locator.service';
import { DistanceService } from '../../../../src/modules/distance/distance.service';

describe('FirebaseDriverLocatorService', () => {
  let service: FirebaseDriverLocatorService;
  let distanceService: jest.Mocked<DistanceService>;

  beforeEach(async () => {
    process.env.DRIVER_LOCATOR_MODE = 'MOCK';

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FirebaseDriverLocatorService,
        {
          provide: DistanceService,
          useValue: { calculateDistance: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<FirebaseDriverLocatorService>(
      FirebaseDriverLocatorService,
    );
    distanceService = module.get(DistanceService);
  });

  afterEach(() => {
    delete process.env.DRIVER_LOCATOR_MODE;
    jest.clearAllMocks();
  });

  describe('getMode', () => {
    it('يرجع MOCK', () => {
      expect(service.getMode()).toBe('MOCK');
    });
  });

  describe('isMockMode', () => {
    it('يرجع true', () => {
      expect(service.isMockMode()).toBe(true);
    });
  });

  describe('getNearestDrivers', () => {
    it('يرجع أقرب السائقين المتاحين بدون reference', async () => {
      const result = await service.getNearestDrivers(3);
      expect(result).toHaveLength(3);
    });

    it('يرتب السائقين حسب المسافة', async () => {
      distanceService.calculateDistance
        .mockReturnValueOnce(1000)
        .mockReturnValueOnce(500)
        .mockReturnValueOnce(2000);

      const result = await service.getNearestDrivers(2, {
        lat: 37.77,
        lon: -122.42,
      });

      expect(result).toHaveLength(2);
      expect(distanceService.calculateDistance).toHaveBeenCalled();
    });

    it('يرمي BadRequestException للإحداثيات الفارغة', async () => {
      await expect(
        service.getNearestDrivers(2, { lat: null as any, lon: null as any }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});

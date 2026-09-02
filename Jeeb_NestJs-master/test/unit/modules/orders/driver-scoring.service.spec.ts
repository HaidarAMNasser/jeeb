import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { DriverScoringService } from '../../../../src/modules/orders/services/driver-scoring.service';
import { SettingsService } from '../../../../src/modules/settings/settings.service';
import { GoogleDirectionsService } from '../../../../src/modules/distance/google-directions.service';
import { DeliveryAssignment } from '../../../../src/database/entities/delivery-assignment.entity';

describe('DriverScoringService', () => {
  let service: DriverScoringService;
  let assignmentRepo: jest.Mocked<any>;
  let settingsService: jest.Mocked<SettingsService>;
  let googleDirectionsService: jest.Mocked<GoogleDirectionsService>;

  const mockDriver = (id: number) => ({
    id,
    firstName: `Driver${id}`,
    lastName: 'Test',
    phone: `123${id}`,
    email: `d${id}@t.com`,
    currentLat: 24.7 + id * 0.01,
    currentLng: 46.7 + id * 0.01,
    notificationChannel: 'FIREBASE',
    fcmToken: 'token',
  });

  const mockQB = {
    select: jest.fn().mockReturnThis(),
    addSelect: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    groupBy: jest.fn().mockReturnThis(),
    getRawMany: jest.fn().mockResolvedValue([]),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DriverScoringService,
        {
          provide: getRepositoryToken(DeliveryAssignment),
          useValue: { createQueryBuilder: jest.fn().mockReturnValue(mockQB) },
        },
        {
          provide: SettingsService,
          useValue: { getSettingByKey: jest.fn() },
        },
        {
          provide: GoogleDirectionsService,
          useValue: { getMultipleRoutes: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<DriverScoringService>(DriverScoringService);
    assignmentRepo = module.get(getRepositoryToken(DeliveryAssignment));
    settingsService = module.get(SettingsService);
    googleDirectionsService = module.get(GoogleDirectionsService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('scoreDrivers', () => {
    it('يرجع مصفوفة فارغة إذا لم يكن هناك سائقين', async () => {
      const result = await service.scoreDrivers(
        { lat: 24.7, lng: 46.7 },
        [],
        new Map(),
      );
      expect(result).toEqual([]);
    });

    it('يسجل السائقين ويصنفهم', async () => {
      const merchantLocation = { lat: 24.7, lng: 46.7 };
      const drivers = [mockDriver(1), mockDriver(2)];
      const haversineDistances = new Map<number, number>([
        [1, 1500],
        [2, 2500],
      ]);

      const routeResults = new Map<number, any>([
        [
          1,
          {
            distanceMeters: 1200,
            durationInTrafficSeconds: 180,
            durationSeconds: 200,
            source: 'GOOGLE_DIRECTIONS',
          },
        ],
        [
          2,
          {
            distanceMeters: 2200,
            durationInTrafficSeconds: 300,
            durationSeconds: 320,
            source: 'GOOGLE_DIRECTIONS',
          },
        ],
      ]);
      googleDirectionsService.getMultipleRoutes.mockResolvedValue(routeResults);

      mockQB.getRawMany.mockResolvedValue([
        { deliveryId: 1, accepted: 8, declined: 2, total: 10 },
        { deliveryId: 2, accepted: 3, declined: 7, total: 10 },
      ]);

      const result = await service.scoreDrivers(
        merchantLocation,
        drivers,
        haversineDistances,
      );

      expect(result).toHaveLength(2);
      expect(result[0].finalScore).toBeLessThan(result[1].finalScore);
      expect(result[0]).toHaveProperty('driver');
      expect(result[0]).toHaveProperty('routeDetails');
      expect(result[0]).toHaveProperty('acceptanceRate');
      expect(result[0]).toHaveProperty('breakdown');
    });

    it('يستخدم Haversine كـ fallback إذا لم توجد Directions', async () => {
      const merchantLocation = { lat: 24.7, lng: 46.7 };
      const drivers = [mockDriver(1)];
      const haversineDistances = new Map<number, number>([[1, 2000]]);

      googleDirectionsService.getMultipleRoutes.mockResolvedValue(new Map());

      mockQB.getRawMany.mockResolvedValue([]);

      const result = await service.scoreDrivers(
        merchantLocation,
        drivers,
        haversineDistances,
      );

      expect(result).toHaveLength(1);
      expect(result[0].routeDetails.routeSource).toBe('HAVERSINE_FALLBACK');
    });
  });

  describe('getAcceptanceRates', () => {
    it('يرجع 0.5 لكل السائقين الجدد', async () => {
      mockQB.getRawMany.mockResolvedValue([]);

      const rates = await service.getAcceptanceRates([1, 2, 3]);

      expect(rates.get(1)).toBe(0.5);
      expect(rates.get(2)).toBe(0.5);
      expect(rates.get(3)).toBe(0.5);
    });

    it('يحسب معدل القبول ACCEPTED / (ACCEPTED + DECLINED)', async () => {
      mockQB.getRawMany.mockResolvedValue([
        { deliveryId: 1, accepted: 8, declined: 2, total: 10 },
      ]);

      const rates = await service.getAcceptanceRates([1]);

      expect(rates.get(1)).toBe(0.8);
    });

    it('يعالج الأخطاء ويعيد 0.5', async () => {
      mockQB.getRawMany.mockRejectedValue(new Error('DB error'));

      const rates = await service.getAcceptanceRates([1]);

      expect(rates.get(1)).toBe(0.5);
    });
  });
});

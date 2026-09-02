import { Test, TestingModule } from '@nestjs/testing';
import { GeoLocationService } from '../../../../src/modules/notifications/geo-location.service';

describe('GeoLocationService', () => {
  let service: GeoLocationService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [GeoLocationService],
    }).compile();

    service = module.get<GeoLocationService>(GeoLocationService);
  });

  describe('getLocationFromIp', () => {
    it('يعيد "محلي" للـ localhost IPv6', async () => {
      const result = await service.getLocationFromIp('::1');
      expect(result).toBe('محلي');
    });

    it('يعيد "محلي" للـ 127.0.0.1', async () => {
      const result = await service.getLocationFromIp('127.0.0.1');
      expect(result).toBe('محلي');
    });

    it('يعيد "محلي" للـ local network', async () => {
      const result = await service.getLocationFromIp('192.168.1.1');
      expect(result).toBe('محلي');
    });

    it('يعيد IP fallback لـ empty string', async () => {
      const result = await service.getLocationFromIp('');
      expect(result).toBe('محلي');
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { LocationController } from '../../../../src/modules/location/location.controller';
import { LocationService } from '../../../../src/modules/location/location.service';
import { PaginationQueryDto } from '../../../../src/common/dto/pagination-query.dto';

describe('LocationController', () => {
  let controller: LocationController;
  let locationService: jest.Mocked<LocationService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [LocationController],
      providers: [
        {
          provide: LocationService,
          useValue: {
            findAllCountries: jest.fn(),
            findCitiesByCountry: jest.fn(),
            updateDriverLocation: jest.fn(),
            getDriverLocation: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<LocationController>(LocationController);
    locationService = module.get(LocationService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('getCountries', () => {
    it('should delegate to service with query', async () => {
      const query: PaginationQueryDto = { page: 1, limit: 10 };
      const expected = { data: [{ id: 1, name: 'UAE' }], total: 1, page: 1, limit: 10 };
      locationService.findAllCountries.mockResolvedValue(expected as any);

      const result = await controller.getCountries(query);

      expect(locationService.findAllCountries).toHaveBeenCalledWith(query);
      expect(result).toEqual(expected);
    });
  });

  describe('getCities', () => {
    it('should delegate to service with countryId and query', async () => {
      const query: PaginationQueryDto = { page: 1, limit: 10 };
      const expected = { data: [{ id: 1, name: 'Dubai', countryId: 1 }], total: 1, page: 1, limit: 10 };
      locationService.findCitiesByCountry.mockResolvedValue(expected as any);

      const result = await controller.getCities(1, query);

      expect(locationService.findCitiesByCountry).toHaveBeenCalledWith(1, query);
      expect(result).toEqual(expected);
    });
  });

  describe('updateLocation', () => {
    it('should delegate to service and return success', async () => {
      locationService.updateDriverLocation.mockResolvedValue(undefined);

      const result = await controller.updateLocation({ driverId: 1, lat: 25.2, lng: 55.3 });

      expect(locationService.updateDriverLocation).toHaveBeenCalledWith(1, 25.2, 55.3);
      expect(result).toEqual({ success: true });
    });
  });

  describe('getLocation', () => {
    it('should delegate to service and return location', async () => {
      const expected = { lat: 25.2, lng: 55.3 };
      locationService.getDriverLocation.mockResolvedValue(expected);

      const result = await controller.getLocation(1);

      expect(locationService.getDriverLocation).toHaveBeenCalledWith(1);
      expect(result).toEqual(expected);
    });
  });
});

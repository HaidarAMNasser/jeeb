import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { LocationService } from '../../../../src/modules/location/location.service';
import { User } from '../../../../src/database/entities/user.entity';
import { Country } from '../../../../src/database/entities/country.entity';
import { City } from '../../../../src/database/entities/city.entity';
import { SearchService, CaseSensitivity } from '../../../../src/common/search';

describe('LocationService', () => {
  let service: LocationService;
  let strategy: any;
  let userRepo: any;
  let countryRepo: any;
  let cityRepo: any;
  let searchService: any;

  beforeEach(async () => {
    strategy = {
      updateLocation: jest.fn(),
      getDriverLocation: jest.fn(),
    };
    userRepo = {
      findOne: jest.fn(),
      update: jest.fn(),
    };
    countryRepo = {
      createQueryBuilder: jest.fn(),
    };
    cityRepo = {
      createQueryBuilder: jest.fn(),
    };
    searchService = {
      buildSearchConditions: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LocationService,
        { provide: 'LocationTracker', useValue: strategy },
        { provide: getRepositoryToken(User), useValue: userRepo },
        { provide: getRepositoryToken(Country), useValue: countryRepo },
        { provide: getRepositoryToken(City), useValue: cityRepo },
        { provide: SearchService, useValue: searchService },
      ],
    }).compile();

    service = module.get<LocationService>(LocationService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('findAllCountries', () => {
    it('should return paginated countries with search', async () => {
      const qb = {
        where: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[{ id: 1, name: 'UAE' }], 1]),
      };
      countryRepo.createQueryBuilder.mockReturnValue(qb);

      const searchParams = { condition: 'country.name LIKE :search', paramName: 'search', paramValue: '%UAE%' };
      searchService.buildSearchConditions.mockReturnValue(searchParams);

      const result = await service.findAllCountries({ page: 1, limit: 10, search: 'UAE' });

      expect(searchService.buildSearchConditions).toHaveBeenCalledWith(
        ['country.name'],
        'UAE',
        CaseSensitivity.INSENSITIVE,
      );
      expect(qb.where).toHaveBeenCalledWith(searchParams.condition, { search: searchParams.paramValue });
      expect(result.data).toHaveLength(1);
      expect(result.total).toBe(1);
    });

    it('should return countries without search', async () => {
      const qb = {
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[{ id: 1, name: 'UAE' }], 1]),
      };
      countryRepo.createQueryBuilder.mockReturnValue(qb);

      const result = await service.findAllCountries({ page: 1, limit: 10 });

      expect(searchService.buildSearchConditions).not.toHaveBeenCalled();
      expect(result.data).toHaveLength(1);
    });
  });

  describe('findCitiesByCountry', () => {
    it('should return paginated cities filtered by countryId', async () => {
      const qb = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[{ id: 1, name: 'Dubai', countryId: 1 }], 1]),
      };
      cityRepo.createQueryBuilder.mockReturnValue(qb);

      const result = await service.findCitiesByCountry(1, { page: 1, limit: 10 });

      expect(qb.where).toHaveBeenCalledWith('city.countryId = :countryId', { countryId: 1 });
      expect(result.data).toHaveLength(1);
    });

    it('should apply search filter when query has search', async () => {
      const qb = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[{ id: 1, name: 'Dubai', countryId: 1 }], 1]),
      };
      cityRepo.createQueryBuilder.mockReturnValue(qb);
      searchService.buildSearchConditions.mockReturnValue({
        condition: 'city.name LIKE :search',
        paramName: 'search',
        paramValue: '%Dubai%',
      });

      const result = await service.findCitiesByCountry(1, { page: 1, limit: 10, search: 'Dubai' });

      expect(searchService.buildSearchConditions).toHaveBeenCalledWith(['city.name'], 'Dubai', CaseSensitivity.INSENSITIVE);
      expect(result.data).toHaveLength(1);
    });
  });

  describe('updateDriverLocation', () => {
    it('should update real-time strategy and local DB', async () => {
      strategy.updateLocation.mockResolvedValue(undefined);
      userRepo.update.mockResolvedValue(undefined);

      await service.updateDriverLocation(1, 25.2, 55.3);

      expect(strategy.updateLocation).toHaveBeenCalledWith(1, 25.2, 55.3);
      expect(userRepo.update).toHaveBeenCalledWith(1, { currentLat: 25.2, currentLng: 55.3 });
    });

    it('should still update local DB if strategy fails', async () => {
      strategy.updateLocation.mockRejectedValue(new Error('Strategy failed'));
      userRepo.update.mockResolvedValue(undefined);

      await service.updateDriverLocation(1, 25.2, 55.3);

      expect(userRepo.update).toHaveBeenCalledWith(1, { currentLat: 25.2, currentLng: 55.3 });
    });
  });

  describe('getDriverLocation', () => {
    it('should return real-time location when available', async () => {
      const loc = { lat: 25.2, lng: 55.3 };
      strategy.getDriverLocation.mockResolvedValue(loc);

      const result = await service.getDriverLocation(1);

      expect(result).toEqual(loc);
    });

    it('should fallback to local DB when real-time returns null', async () => {
      strategy.getDriverLocation.mockResolvedValue(null);
      userRepo.findOne.mockResolvedValue({ currentLat: 25.2, currentLng: 55.3 });

      const result = await service.getDriverLocation(1);

      expect(userRepo.findOne).toHaveBeenCalledWith({
        where: { id: 1 },
        select: ['currentLat', 'currentLng'],
      });
      expect(result).toEqual({ lat: 25.2, lng: 55.3 });
    });

    it('should return null when no location found', async () => {
      strategy.getDriverLocation.mockResolvedValue(null);
      userRepo.findOne.mockResolvedValue({ currentLat: null, currentLng: null });

      const result = await service.getDriverLocation(1);

      expect(result).toBeNull();
    });
  });
});

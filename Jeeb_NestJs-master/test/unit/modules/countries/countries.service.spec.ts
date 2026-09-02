import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { CountriesService } from '../../../../src/modules/countries/countries.service';
import { Country } from '../../../../src/database/entities/country.entity';
import { SearchService, CaseSensitivity } from '../../../../src/common/search';

describe('CountriesService', () => {
  let service: CountriesService;
  let countryRepo: any;
  let searchService: any;

  beforeEach(async () => {
    countryRepo = {
      createQueryBuilder: jest.fn(),
      findOne: jest.fn(),
    };
    searchService = {
      buildSearchConditions: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CountriesService,
        { provide: getRepositoryToken(Country), useValue: countryRepo },
        { provide: SearchService, useValue: searchService },
      ],
    }).compile();

    service = module.get<CountriesService>(CountriesService);
  });

  describe('findAll', () => {
    it('should return paginated active countries', async () => {
      const qb = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[{ id: 1, name: 'Syria' }], 1]),
      };
      countryRepo.createQueryBuilder.mockReturnValue(qb);

      const result = await service.findAll({ page: 1, limit: 10 });

      expect(qb.where).toHaveBeenCalledWith('country.isActive = :isActive', { isActive: true });
      expect(result.data).toHaveLength(1);
      expect(result.total).toBe(1);
    });

    it('should apply search when provided', async () => {
      const qb = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[{ id: 1, name: 'Syria' }], 1]),
      };
      countryRepo.createQueryBuilder.mockReturnValue(qb);
      searchService.buildSearchConditions.mockReturnValue({
        condition: "country.name->>'en' LIKE :search",
        paramName: 'search',
        paramValue: '%Syria%',
      });

      await service.findAll({ page: 1, limit: 10, search: 'Syria' });

      expect(searchService.buildSearchConditions).toHaveBeenCalledWith(
        ["country.name->>'en'"],
        'Syria',
        CaseSensitivity.INSENSITIVE,
      );
    });
  });

  describe('findOne', () => {
    it('should return country when found', async () => {
      const country = { id: 1, name: 'Syria' };
      countryRepo.findOne.mockResolvedValue(country);

      const result = await service.findOne(1);

      expect(result).toEqual(country);
    });

    it('should throw NotFoundException when not found', async () => {
      countryRepo.findOne.mockResolvedValue(null);

      await expect(service.findOne(999)).rejects.toThrow(NotFoundException);
    });
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { NotFoundException } from '@nestjs/common';
import { CitiesService } from '../../../../src/modules/cities/cities.service';
import { City } from '../../../../src/database/entities/city.entity';
import { SearchService, CaseSensitivity } from '../../../../src/common/search';

describe('CitiesService', () => {
  let service: CitiesService;
  let cityRepo: any;
  let searchService: any;

  beforeEach(async () => {
    cityRepo = {
      createQueryBuilder: jest.fn(),
      findOne: jest.fn(),
    };
    searchService = {
      buildSearchConditions: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CitiesService,
        { provide: getRepositoryToken(City), useValue: cityRepo },
        { provide: SearchService, useValue: searchService },
      ],
    }).compile();

    service = module.get<CitiesService>(CitiesService);
  });

  describe('findAll', () => {
    it('should return paginated cities filtered by countryId', async () => {
      const qb = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[{ id: 1, name: 'Damascus', country: { id: 1 } }], 1]),
      };
      cityRepo.createQueryBuilder.mockReturnValue(qb);

      const result = await service.findAll({ page: 1, limit: 10 }, 1);

      expect(qb.where).toHaveBeenCalledWith('city.countryId = :countryId', { countryId: 1 });
      expect(result.data).toHaveLength(1);
    });

    it('should not filter by countryId when not provided', async () => {
      const qb = {
        leftJoinAndSelect: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[{ id: 1, name: 'Damascus' }], 1]),
      };
      cityRepo.createQueryBuilder.mockReturnValue(qb);

      const result = await service.findAll({ page: 1, limit: 10 });

      expect(qb.where).not.toHaveBeenCalled();
      expect(result.data).toHaveLength(1);
    });
  });

  describe('findOne', () => {
    it('should return city when found', async () => {
      const city = { id: 1, name: 'Damascus', country: { id: 1 } };
      cityRepo.findOne.mockResolvedValue(city);

      const result = await service.findOne(1);

      expect(result).toEqual(city);
    });

    it('should throw NotFoundException when not found', async () => {
      cityRepo.findOne.mockResolvedValue(null);

      await expect(service.findOne(999)).rejects.toThrow(NotFoundException);
    });
  });
});

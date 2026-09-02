import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Repository } from 'typeorm';
import { AreasService } from '../../../../src/modules/areas/areas.service';
import { Area } from '../../../../src/database/entities/area.entity';
import { SearchService, CaseSensitivity } from '../../../../src/common/search';
import { REDIS_CLIENT } from '../../../../src/common/redis/redis.constants';
import { UserRole } from '../../../../src/common/enums/user-role.enum';

describe('AreasService', () => {
  let service: AreasService;
  let areaRepo: jest.Mocked<Repository<Area>>;
  let searchService: jest.Mocked<SearchService>;
  let redis: jest.Mocked<any>;

  const now = new Date();
  const mockArea: Area = {
    id: 1,
    name: 'Downtown',
    price: 5000,
    description: 'Central district',
    createdAt: now,
    updatedAt: now,
  };

  const mockAreaCached = { ...mockArea, createdAt: now.toISOString(), updatedAt: now.toISOString() };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AreasService,
        {
          provide: getRepositoryToken(Area),
          useValue: {
            create: jest.fn(),
            save: jest.fn(),
            findOne: jest.fn(),
            findAndCount: jest.fn(),
            merge: jest.fn(),
            remove: jest.fn(),
            createQueryBuilder: jest.fn(),
          },
        },
        {
          provide: SearchService,
          useValue: {
            buildSearchConditions: jest.fn(),
          },
        },
        {
          provide: REDIS_CLIENT,
          useValue: {
            get: jest.fn(),
            set: jest.fn(),
            del: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<AreasService>(AreasService);
    areaRepo = module.get(getRepositoryToken(Area));
    searchService = module.get(SearchService);
    redis = module.get(REDIS_CLIENT);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    const dto = { name: 'New Area', price: 3000 };

    it('should throw ForbiddenException if not ADMIN', async () => {
      await expect(service.create(dto, UserRole.CUSTOMER)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should create area and clear list cache', async () => {
      areaRepo.create.mockReturnValue(mockArea);
      areaRepo.save.mockResolvedValue(mockArea);

      const result = await service.create(dto, UserRole.ADMIN);

      expect(areaRepo.create).toHaveBeenCalledWith(dto);
      expect(areaRepo.save).toHaveBeenCalledWith(mockArea);
      expect(redis.del).toHaveBeenCalledWith('areas:list:*');
      expect(result).toEqual(mockArea);
    });
  });

  describe('findAll', () => {
    const defaultQuery = { page: 1, limit: 10 };

    it('should throw BadRequestException when min_price > max_price', async () => {
      await expect(
        service.findAll({ min_price: 100, max_price: 50 }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should return cached result when available', async () => {
      const cachedResult = { data: [mockAreaCached], total: 1, page: 1, limit: 10 };
      redis.get.mockResolvedValue(JSON.stringify(cachedResult));

      const result = await service.findAll(defaultQuery);

      expect(redis.get).toHaveBeenCalled();
      expect(areaRepo.createQueryBuilder).not.toHaveBeenCalled();
      expect(result).toEqual(cachedResult);
    });

    it('should query DB and cache result when no cache', async () => {
      redis.get.mockResolvedValue(null);

      const mockQueryBuilder = {
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[mockArea], 1]),
      };
      areaRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);

      const result = await service.findAll(defaultQuery);

      expect(areaRepo.createQueryBuilder).toHaveBeenCalledWith('area');
      expect(mockQueryBuilder.orderBy).toHaveBeenCalledWith('area.createdAt', 'DESC');
      expect(redis.set).toHaveBeenCalled();
      expect(result).toEqual({ data: [mockArea], total: 1, page: 1, limit: 10 });
    });

    it('should apply price filters when provided', async () => {
      redis.get.mockResolvedValue(null);
      const mockQueryBuilder = {
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[mockArea], 1]),
      };
      areaRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);

      await service.findAll({ min_price: 1000, max_price: 10000 });

      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'area.price >= :min_price',
        { min_price: 1000 },
      );
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'area.price <= :max_price',
        { max_price: 10000 },
      );
    });

    it('should apply search when provided', async () => {
      redis.get.mockResolvedValue(null);
      const mockQueryBuilder = {
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([[mockArea], 1]),
      };
      areaRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);
      searchService.buildSearchConditions.mockReturnValue({
        condition: 'area.name ILIKE :search_0',
        paramName: 'search_0',
        paramValue: '%downtown%',
      });

      await service.findAll({ search: 'downtown' });

      expect(searchService.buildSearchConditions).toHaveBeenCalledWith(
        ['area.name', 'area.description', 'CAST(area.price AS TEXT)'],
        'downtown',
        CaseSensitivity.INSENSITIVE,
      );
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'area.name ILIKE :search_0',
        { search_0: '%downtown%' },
      );
    });
  });

  describe('findOne', () => {
    it('should return cached area when available', async () => {
      redis.get.mockResolvedValue(JSON.stringify(mockAreaCached));

      const result = await service.findOne(1);

      expect(redis.get).toHaveBeenCalledWith('areas:1');
      expect(areaRepo.findOne).not.toHaveBeenCalled();
      expect(result).toEqual(mockAreaCached);
    });

    it('should query DB and cache result when no cache', async () => {
      redis.get.mockResolvedValue(null);
      areaRepo.findOne.mockResolvedValue(mockArea);

      const result = await service.findOne(1);

      expect(areaRepo.findOne).toHaveBeenCalledWith({ where: { id: 1 } });
      expect(redis.set).toHaveBeenCalled();
      expect(result).toEqual(mockArea);
    });

    it('should throw NotFoundException when area does not exist', async () => {
      redis.get.mockResolvedValue(null);
      areaRepo.findOne.mockResolvedValue(null);

      await expect(service.findOne(999)).rejects.toThrow(NotFoundException);
    });
  });

  describe('update', () => {
    const dto = { name: 'Updated Area' };

    it('should throw ForbiddenException if not ADMIN', async () => {
      await expect(service.update(1, dto, UserRole.CUSTOMER)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should update area and invalidate caches', async () => {
      redis.get.mockResolvedValue(null);
      areaRepo.findOne.mockResolvedValue(mockArea);
      areaRepo.merge.mockReturnValue({ ...mockArea, ...dto });
      areaRepo.save.mockResolvedValue({ ...mockArea, ...dto });

      const result = await service.update(1, dto, UserRole.ADMIN);

      expect(areaRepo.merge).toHaveBeenCalledWith(mockArea, dto);
      expect(areaRepo.save).toHaveBeenCalled();
      expect(redis.del).toHaveBeenCalledWith('areas:1');
      expect(redis.del).toHaveBeenCalledWith('areas:list:*');
      expect(result).toEqual({ ...mockArea, ...dto });
    });
  });

  describe('remove', () => {
    it('should throw ForbiddenException if not ADMIN', async () => {
      await expect(service.remove(1, UserRole.CUSTOMER)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should remove area and invalidate caches', async () => {
      redis.get.mockResolvedValue(null);
      areaRepo.findOne.mockResolvedValue(mockArea);
      areaRepo.remove.mockResolvedValue(mockArea);

      const result = await service.remove(1, UserRole.ADMIN);

      expect(areaRepo.remove).toHaveBeenCalledWith(mockArea);
      expect(redis.del).toHaveBeenCalledWith('areas:1');
      expect(redis.del).toHaveBeenCalledWith('areas:list:*');
      expect(result).toEqual({ message: 'Area deleted successfully' });
    });

    it('should throw NotFoundException when area does not exist', async () => {
      redis.get.mockResolvedValue(null);
      areaRepo.findOne.mockResolvedValue(null);

      await expect(service.remove(999, UserRole.ADMIN)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});

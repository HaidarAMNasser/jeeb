import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import Redis from 'ioredis';
import { Area } from '../../database/entities/area.entity';
import { CreateAreaDto } from './dto/create-area.dto';
import { UpdateAreaDto } from './dto/update-area.dto';
import { GetAreasQueryDto } from './dto/get-areas-query.dto';
import { PaginatedResult } from '../../common/interfaces/paginated-result.interface';
import { UserRole } from '../../common/enums/user-role.enum';
import { SearchService, CaseSensitivity } from '../../common/search';
import { REDIS_CLIENT } from '../../common/redis/redis.constants';

const AREA_CACHE_TTL = 600;

@Injectable()
export class AreasService {
  constructor(
    @InjectRepository(Area)
    private readonly areaRepo: Repository<Area>,
    private readonly searchService: SearchService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  async create(createAreaDto: CreateAreaDto, role: UserRole): Promise<Area> {
    if (role !== UserRole.ADMIN) {
      throw new ForbiddenException('Only Admins can create areas');
    }

    const area = this.areaRepo.create(createAreaDto);
    const saved = await this.areaRepo.save(area);
    await this.redis.del('areas:list:*');
    return saved;
  }

  async findAll(query: GetAreasQueryDto): Promise<PaginatedResult<Area>> {
    const { page = 1, limit = 10, search, min_price, max_price } = query;

    if (
      min_price !== undefined &&
      max_price !== undefined &&
      min_price > max_price
    ) {
      throw new BadRequestException(
        'min_price must be less than or equal to max_price',
      );
    }

    const cacheKey = `areas:list:${page}:${limit}:${search || ''}:${min_price ?? ''}:${max_price ?? ''}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    const skip = (page - 1) * limit;
    const queryBuilder = this.areaRepo.createQueryBuilder('area');

    if (min_price !== undefined) {
      queryBuilder.andWhere('area.price >= :min_price', { min_price });
    }

    if (max_price !== undefined) {
      queryBuilder.andWhere('area.price <= :max_price', { max_price });
    }

    if (search?.trim()) {
      const searchResult = this.searchService.buildSearchConditions(
        ['area.name', 'area.description', 'CAST(area.price AS TEXT)'],
        search.trim(),
        CaseSensitivity.INSENSITIVE,
      );

      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    const [data, total] = await queryBuilder
      .orderBy('area.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    const result = { data, total, page, limit };
    await this.redis.set(cacheKey, JSON.stringify(result), 'EX', AREA_CACHE_TTL);
    return result;
  }

  async findOne(id: number): Promise<Area> {
    const cacheKey = `areas:${id}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    const area = await this.areaRepo.findOne({ where: { id } });
    if (!area) {
      throw new NotFoundException(`Area with ID ${id} not found`);
    }

    await this.redis.set(cacheKey, JSON.stringify(area), 'EX', AREA_CACHE_TTL);
    return area;
  }

  async update(
    id: number,
    updateAreaDto: UpdateAreaDto,
    role: UserRole,
  ): Promise<Area> {
    if (role !== UserRole.ADMIN) {
      throw new ForbiddenException('Only Admins can update areas');
    }

    const area = await this.findOne(id);
    this.areaRepo.merge(area, updateAreaDto);
    const saved = await this.areaRepo.save(area);
    await Promise.all([
      this.redis.del(`areas:${id}`),
      this.redis.del('areas:list:*'),
    ]);
    return saved;
  }

  async remove(id: number, role: UserRole): Promise<{ message: string }> {
    if (role !== UserRole.ADMIN) {
      throw new ForbiddenException('Only Admins can delete areas');
    }

    const area = await this.findOne(id);
    await this.areaRepo.remove(area);
    await Promise.all([
      this.redis.del(`areas:${id}`),
      this.redis.del('areas:list:*'),
    ]);
    return { message: 'Area deleted successfully' };
  }
}

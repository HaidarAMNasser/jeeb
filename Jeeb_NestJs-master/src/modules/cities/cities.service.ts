import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { City } from '../../database/entities/city.entity';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';
import { PaginatedResult } from '../../common/interfaces/paginated-result.interface';
import { SearchService, CaseSensitivity } from '../../common/search';

@Injectable()
export class CitiesService {
  constructor(
    @InjectRepository(City)
    private readonly cityRepo: Repository<City>,
    private readonly searchService: SearchService,
  ) {}

  async findAll(
    query: PaginationQueryDto,
    countryId?: number,
  ): Promise<PaginatedResult<City>> {
    const { page = 1, limit = 10, search } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.cityRepo.createQueryBuilder('city');
    queryBuilder.leftJoinAndSelect('city.country', 'country');

    if (countryId) {
      queryBuilder.where('city.countryId = :countryId', { countryId });
    }

    if (search) {
      const searchResult = this.searchService.buildSearchConditions(
        ["city.name->>'en'"],
        search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    const [data, total] = await queryBuilder
      .orderBy('city.id', 'ASC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      data,
      total,
      page,
      limit,
    };
  }

  async findOne(id: number) {
    const city = await this.cityRepo.findOne({
      where: { id },
      relations: ['country'],
    });
    if (!city) {
      throw new NotFoundException(`City with ID ${id} not found`);
    }
    return city;
  }
}

import { Injectable, Inject, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../database/entities/user.entity';
import { Country } from '../../database/entities/country.entity';
import { City } from '../../database/entities/city.entity';
import * as locationTrackerInterface from './interfaces/location-tracker.interface';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';
import { PaginatedResult } from '../../common/interfaces/paginated-result.interface';
import { SearchService, CaseSensitivity } from '../../common/search';

@Injectable()
export class LocationService {
  private readonly logger = new Logger(LocationService.name);

  constructor(
    @Inject('LocationTracker')
    private readonly strategy: locationTrackerInterface.LocationTracker,
    @InjectRepository(User) private readonly userRepository: Repository<User>,
    @InjectRepository(Country)
    private readonly countryRepository: Repository<Country>,
    @InjectRepository(City) private readonly cityRepository: Repository<City>,
    private readonly searchService: SearchService,
  ) {}

  async findAllCountries(
    query: PaginationQueryDto,
  ): Promise<PaginatedResult<Country>> {
    const { page, limit } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.countryRepository.createQueryBuilder('country');

    if (query.search) {
      const searchResult = this.searchService.buildSearchConditions(
        ['country.name'],
        query.search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.where(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    const [data, total] = await queryBuilder
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

  async findCitiesByCountry(
    countryId: number,
    query: PaginationQueryDto,
  ): Promise<PaginatedResult<City>> {
    const { page, limit } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.cityRepository.createQueryBuilder('city');
    queryBuilder.where('city.countryId = :countryId', { countryId });

    if (query.search) {
      const searchResult = this.searchService.buildSearchConditions(
        ['city.name'],
        query.search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    const [data, total] = await queryBuilder
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

  /**
   * Updates the driver's location in both the local DB (last known) and the real-time strategy (Firebase/WebSocket).
   */
  async updateDriverLocation(
    driverId: number,
    lat: number,
    lng: number,
  ): Promise<void> {
    // 1. Update Real-time Strategy (Firebase)
    // We do this first or in parallel. If it fails, we might still want to update local DB.
    try {
      await this.strategy.updateLocation(driverId, lat, lng);
    } catch (error: any) {
      this.logger.error(
        `Failed to update real-time location strategy: ${error.message}`,
      );
      // Continue to update local DB? Yes, probably.
    }

    // 2. Update Local DB (Last Known Location)
    // Optimization: We might want to throttle this if updates are very frequent,
    // but for now we update every time or let the client throttle.
    await this.userRepository.update(driverId, {
      currentLat: lat,
      currentLng: lng,
    });

    this.logger.debug(`Updated local DB location for driver ${driverId}`);
  }

  async getDriverLocation(
    driverId: number,
  ): Promise<{ lat: number; lng: number } | null> {
    // Try to get from real-time source first
    const realTimeLoc = await this.strategy.getDriverLocation(driverId);
    if (realTimeLoc) {
      return realTimeLoc;
    }

    // Fallback to local DB
    const user = await this.userRepository.findOne({
      where: { id: driverId },
      select: ['currentLat', 'currentLng'],
    });

    if (user && user.currentLat && user.currentLng) {
      return { lat: user.currentLat, lng: user.currentLng };
    }

    return null;
  }
}

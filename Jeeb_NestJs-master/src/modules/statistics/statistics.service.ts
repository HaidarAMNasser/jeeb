import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Merchant } from '../../database/entities/merchant.entity';
import { User } from '../../database/entities/user.entity';
import { Order } from '../../database/entities/order.entity';
import { SearchService } from '../../common/search/search.service';
import { UserRole } from '../../common/enums/user-role.enum';
import { MerchantStatsQueryDto } from './dto/merchant-stats-query.dto';
import { PaginatedResult } from '../../common/interfaces/paginated-result.interface';

export interface MerchantStatsItem {
  id: number;
  userId: number;
  name: string | null;
  type: string;
  location: {
    country: { id: number; name: { ar: string; en: string } } | null;
    city: { id: number; name: { ar: string; en: string } } | null;
    coordinates: { lat: number; lng: number } | null;
  };
  stats: {
    totalOrders: number;
    totalRevenue: number;
  };
}

@Injectable()
export class StatisticsService {
  constructor(
    @InjectRepository(Merchant)
    private readonly merchantRepo: Repository<Merchant>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    private readonly searchService: SearchService,
  ) {}

  async getMerchantStats(
    query: MerchantStatsQueryDto,
  ): Promise<PaginatedResult<MerchantStatsItem>> {
    const { page, limit, search, from, to, merchantId } = query;
    const skip = (page - 1) * limit;

    const qb = this.merchantRepo
      .createQueryBuilder('merchant')
      .innerJoinAndSelect('merchant.user', 'user')
      .leftJoinAndSelect('user.country', 'country')
      .leftJoinAndSelect('user.city', 'city')
      .where('user.role = :role', { role: UserRole.MERCHANT });

    if (merchantId) {
      qb.andWhere('merchant.userId = :merchantId', { merchantId });
    }

    if (search) {
      const searchResult = this.searchService.buildSearchConditions(
        ['merchant.restaurantName', 'user.firstName', 'user.lastName'],
        search,
      );
      qb.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    const total = await qb.getCount();

    const merchants = await qb
      .orderBy('merchant.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getMany();

    if (merchants.length === 0) {
      return { data: [], total, page, limit };
    }

    const userIds = merchants.map((m) => m.userId);

    const statsQb = this.orderRepo
      .createQueryBuilder('order')
      .select([
        'order.ownerId as "ownerId"',
        'COUNT(order.id)::int as "totalOrders"',
        'COALESCE(SUM(order.totalAmount), 0)::int as "totalRevenue"',
      ])
      .where('order.ownerId IN (:...userIds)', { userIds });

    if (from) {
      statsQb.andWhere('order.createdAt >= :from', { from: new Date(from) });
    }
    if (to) {
      statsQb.andWhere('order.createdAt <= :to', { to: new Date(to) });
    }

    const stats = await statsQb.groupBy('order.ownerId').getRawMany();

    const statsMap = new Map<
      number,
      { totalOrders: number; totalRevenue: number }
    >();
    for (const stat of stats) {
      statsMap.set(stat.ownerId, {
        totalOrders: Number(stat.totalOrders),
        totalRevenue: Number(stat.totalRevenue),
      });
    }

    const data: MerchantStatsItem[] = merchants.map((merchant) => {
      const merchantStats = statsMap.get(merchant.userId);
      return {
        id: merchant.id,
        userId: merchant.userId,
        name: merchant.restaurantName,
        type: merchant.type,
        location: {
          country: merchant.user.country
            ? { id: merchant.user.country.id, name: merchant.user.country.name }
            : null,
          city: merchant.user.city
            ? { id: merchant.user.city.id, name: merchant.user.city.name }
            : null,
          coordinates: merchant.user.location,
        },
        stats: {
          totalOrders: merchantStats?.totalOrders ?? 0,
          totalRevenue: merchantStats?.totalRevenue ?? 0,
        },
      };
    });

    return { data, total, page, limit };
  }
}

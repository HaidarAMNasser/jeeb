import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../database/entities/user.entity';
import { Product } from '../../database/entities/product.entity';
import { Offer } from '../../database/entities/offer.entity';
import { Image } from '../../database/entities/image.entity';
import { SearchService, CaseSensitivity } from '../../common/search';
import { StorageService } from '../../common/storage/storage.service';
import { UserRole, ImageEntityType, MerchantType } from '../../common/enums';
import { GlobalSearchQueryDto } from './dto/global-search-query.dto';

export interface SearchSectionResult<T> {
  data: T[];
  pagination: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
  };
}

@Injectable()
export class GlobalSearchService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
    @InjectRepository(Offer)
    private readonly offerRepository: Repository<Offer>,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
    private readonly searchService: SearchService,
    private readonly storageService: StorageService,
  ) {}

  async searchAll(queryDto: GlobalSearchQueryDto) {
    const { q, limit = 10, page = 1 } = queryDto;
    const searchVal = q?.trim();

    if (!searchVal) {
      return {
        products: {
          data: [],
          pagination: {
            total: 0,
            page,
            limit,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          },
        },
        offers: {
          data: [],
          pagination: {
            total: 0,
            page,
            limit,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          },
        },
        merchants: {
          data: [],
          pagination: {
            total: 0,
            page,
            limit,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          },
        },
        pagination: {
          page,
          limit,
          total: 0,
          totalPages: 0,
          hasNextPage: false,
          hasPreviousPage: false,
        },
      };
    }

    const skip = (page - 1) * limit;

    const [merchantsResult, productsResult, offersResult] = await Promise.all([
      this.searchMerchantsSection(searchVal, limit, skip),
      this.searchProductsSection(searchVal, limit, skip),
      this.searchOffersSection(searchVal, limit, skip),
    ]);

    const total =
      merchantsResult.pagination.total +
      productsResult.pagination.total +
      offersResult.pagination.total;
    const totalPages = Math.ceil(total / limit);
    const hasNextPage = page < totalPages;
    const hasPreviousPage = page > 1;

    return {
      products: productsResult,
      offers: offersResult,
      merchants: merchantsResult,
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNextPage,
        hasPreviousPage,
      },
    };
  }

  private async searchMerchantsSection(
    query: string,
    limit: number,
    skip: number,
  ): Promise<SearchSectionResult<any>> {
    const queryBuilder = this.getMerchantsQuery(query);
    const total = await queryBuilder.getCount();

    const users = await queryBuilder.skip(skip).take(limit).getMany();

    const data = await Promise.all(
      users.map(async (user) => {
        const images = await this.imageRepository.find({
          where: { entityType: ImageEntityType.USER, entityId: user.id },
          take: 1,
        });
        const hidePhoneNumber = user.merchant?.hidePhoneNumber === true;
        return {
          id: user.id,
          name:
            user.merchant?.restaurantName ||
            `${user.firstName} ${user.lastName}`,
          restaurantName: user.merchant?.restaurantName || null,
          type: user.merchant?.type || MerchantType.RESTAURANT,
          email: user.email,
          phone: hidePhoneNumber ? undefined : user.phone,
          hidePhoneNumber: user.merchant?.hidePhoneNumber ?? false,
          image: images[0]
            ? this.storageService.resolveUrl(images[0].url)
            : null,
          merchantId: user.merchant?.id,
        };
      }),
    );

    const totalPages = Math.ceil(total / limit);
    const currentPage = Math.floor(skip / limit) + 1;

    return {
      data,
      pagination: {
        total,
        page: currentPage,
        limit,
        totalPages,
        hasNextPage: currentPage < totalPages,
        hasPreviousPage: currentPage > 1,
      },
    };
  }

  private async searchProductsSection(
    query: string,
    limit: number,
    skip: number,
  ): Promise<SearchSectionResult<any>> {
    const queryBuilder = this.getProductsQuery(query);
    const total = await queryBuilder.getCount();

    const products = await queryBuilder.skip(skip).take(limit).getMany();

    const data = await Promise.all(
      products.map(async (product) => {
        const images = await this.imageRepository.find({
          where: { entityType: ImageEntityType.PRODUCT, entityId: product.id },
          take: 1,
        });
        return {
          id: product.id,
          name: product.name,
          price: product.price,
          image: images[0]
            ? this.storageService.resolveUrl(images[0].url)
            : null,
          merchantId: product.merchantId,
          categoryId: product.categoryId,
        };
      }),
    );

    const totalPages = Math.ceil(total / limit);
    const currentPage = Math.floor(skip / limit) + 1;

    return {
      data,
      pagination: {
        total,
        page: currentPage,
        limit,
        totalPages,
        hasNextPage: currentPage < totalPages,
        hasPreviousPage: currentPage > 1,
      },
    };
  }

  private async searchOffersSection(
    query: string,
    limit: number,
    skip: number,
  ): Promise<SearchSectionResult<any>> {
    const queryBuilder = this.getOffersQuery(query);
    const total = await queryBuilder.getCount();

    const offers = await queryBuilder.skip(skip).take(limit).getMany();

    const data = offers.map((offer) => ({
      id: offer.id,
      name: offer.name,
      discountValue: offer.discountValue,
      discountType: offer.discountType,
      merchantId: offer.merchantId,
    }));

    const totalPages = Math.ceil(total / limit);
    const currentPage = Math.floor(skip / limit) + 1;

    return {
      data,
      pagination: {
        total,
        page: currentPage,
        limit,
        totalPages,
        hasNextPage: currentPage < totalPages,
        hasPreviousPage: currentPage > 1,
      },
    };
  }

  private getMerchantsQuery(query: string) {
    const searchResult = this.searchService.buildSearchConditions(
      [
        'user.firstName',
        'user.lastName',
        'user.email',
        'user.phone',
        'merchant.restaurantName',
      ],
      query,
      CaseSensitivity.INSENSITIVE,
    );

    return this.userRepository
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.merchant', 'merchant')
      .where('user.role = :role', { role: UserRole.MERCHANT })
      .andWhere('user.verifiedAt IS NOT NULL')
      .andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
  }

  private getProductsQuery(query: string) {
    const searchResult = this.searchService.buildSearchConditions(
      ["product.name->>'ar'", "product.name->>'en'"],
      query,
      CaseSensitivity.INSENSITIVE,
    );

    return this.productRepository
      .createQueryBuilder('product')
      .where(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      })
      .andWhere('product.commissionConfirmed = :confirmed', {
        confirmed: true,
      });
  }

  private getOffersQuery(query: string) {
    const searchResult = this.searchService.buildSearchConditions(
      ["offer.name->>'ar'", "offer.name->>'en'"],
      query,
      CaseSensitivity.INSENSITIVE,
    );

    return this.offerRepository
      .createQueryBuilder('offer')
      .where(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      })
      .andWhere('offer.isActive = :active', { active: true });
  }
}

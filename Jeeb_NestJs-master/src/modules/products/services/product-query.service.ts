import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Product } from '../../../database/entities/product.entity';
import { User } from '../../../database/entities/user.entity';
import { Image } from '../../../database/entities/image.entity';
import { Review } from '../../../database/entities/review.entity';
import { GetProductsQueryDto } from '../dto/get-products-query.dto';
import {
  UserRole,
  ImageEntityType,
  ReviewEntityType,
} from '../../../common/enums';
import { PaginatedResult } from '../../../common/interfaces/paginated-result.interface';
import { SearchService, CaseSensitivity } from '../../../common/search';
import { GoogleDirectionsService } from '../../distance/google-directions.service';
import { ProductImagesService } from './product-images.service';
import { ProductPricingService } from './product-pricing.service';
import { ProductEnrichmentService } from './product-enrichment.service';
import { ProductResponseMapper } from '../mappers/product-response.mapper';

@Injectable()
export class ProductQueryService {
  private readonly logger = new Logger(ProductQueryService.name);

  constructor(
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly searchService: SearchService,
    private readonly googleDirectionsService: GoogleDirectionsService,
    private readonly productImagesService: ProductImagesService,
    private readonly productPricingService: ProductPricingService,
    private readonly productEnrichmentService: ProductEnrichmentService,
    private readonly productResponseMapper: ProductResponseMapper,
  ) {}

  async findAll(
    query: GetProductsQueryDto,
    userId?: number,
    role?: UserRole,
  ): Promise<PaginatedResult<any>> {
    const { page = 1, limit = 10 } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.productRepo.createQueryBuilder('product');

    queryBuilder.leftJoinAndMapMany(
      'product.images',
      Image,
      'image',
      'image.entityId = product.id AND image.entityType = :type',
      { type: ImageEntityType.PRODUCT },
    );

    if (role === UserRole.MERCHANT && userId) {
      queryBuilder.andWhere('product.merchantId = :userId', { userId });
    } else if (query.merchantId !== undefined && query.merchantId !== null) {
      queryBuilder.andWhere('product.merchantId = :merchantId', {
        merchantId: query.merchantId,
      });
    }

    if (role === UserRole.CUSTOMER || (!role && !userId)) {
      queryBuilder.andWhere('product.commissionConfirmed = :confirmed', {
        confirmed: true,
      });
    }

    if (query.categoryId !== undefined && query.categoryId !== null) {
      queryBuilder.andWhere('product.categoryId = :categoryId', {
        categoryId: query.categoryId,
      });
    }

    const searchValue = query.search?.trim();
    if (searchValue && searchValue.length > 0) {
      const searchResult = this.searchService.buildSearchConditions(
        ["product.name->>'ar'", "product.name->>'en'"],
        searchValue,
        CaseSensitivity.INSENSITIVE,
      );

      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    const finalPriceSql = `(
      (CASE 
        WHEN product."discountType" = 'PERCENTAGE' THEN (product.price - FLOOR(product.price * COALESCE(product.discount, 0) / 100.0))
        WHEN product."discountType" = 'FIXED' THEN GREATEST(0, product.price - COALESCE(product.discount, 0))
        ELSE product.price
      END) + 
      FLOOR(
        (CASE 
          WHEN product."discountType" = 'PERCENTAGE' THEN (product.price - FLOOR(product.price * COALESCE(product.discount, 0) / 100.0))
          WHEN product."discountType" = 'FIXED' THEN GREATEST(0, product.price - COALESCE(product.discount, 0))
          ELSE product.price
        END) * COALESCE(product."commissionRate", 0) / 100.0
      )
    )`;

    if (query.minPrice !== undefined && query.minPrice !== null) {
      queryBuilder.andWhere(`${finalPriceSql} >= :minPrice`, {
        minPrice: query.minPrice,
      });
    }

    if (query.maxPrice !== undefined && query.maxPrice !== null) {
      queryBuilder.andWhere(`${finalPriceSql} <= :maxPrice`, {
        maxPrice: query.maxPrice,
      });
    }

    if (
      query.minRating !== undefined &&
      query.minRating !== null &&
      query.minRating >= 1
    ) {
      queryBuilder.andWhere(
        (qb) => {
          const subQuery = qb
            .subQuery()
            .select('AVG(review.rating)')
            .from(Review, 'review')
            .where('review.entityId = product.id')
            .andWhere('review.entityType = :reviewType')
            .getQuery();
          return `COALESCE(${subQuery}, 0) >= :minRating`;
        },
        { minRating: query.minRating, reviewType: ReviewEntityType.PRODUCT },
      );
    }

    const [data, total] = await queryBuilder
      .skip(skip)
      .take(limit)
      .orderBy('product.createdAt', 'DESC')
      .getManyAndCount();

    this.productImagesService.resolveImageUrls(data);
    this.productPricingService.resolveComputedFields(data);

    const customerLocation = await this.getCustomerLocation(
      userId ?? 0,
      role ?? UserRole.CUSTOMER,
    );
    const isCustomer =
      role === UserRole.CUSTOMER && !!userId && customerLocation !== null;
    let sortedData = data;

    if (isCustomer && customerLocation) {
      sortedData = await this.sortProductsByDistance(data, customerLocation);
    }

    const productIds = sortedData.map((p) => p.id);
    const reviewsMap =
      await this.productEnrichmentService.getProductReviews(productIds);
    const favoriteProductIds =
      await this.productEnrichmentService.getFavoriteProductIds(
        userId,
        productIds,
      );
    const inCartMap = await this.productEnrichmentService.getProductsInCart(
      userId,
      productIds,
    );

    const formattedData = sortedData.map((product) =>
      this.productResponseMapper.formatProductResponse(
        product,
        reviewsMap.get(product.id) || [],
        favoriteProductIds.has(product.id),
        inCartMap.get(product.id) || 0,
      ),
    );

    return {
      data: formattedData,
      total,
      page,
      limit,
    };
  }

  async getCustomerLocation(
    userId: number,
    role: UserRole,
  ): Promise<{ lat: number; lng: number } | null> {
    if (role !== UserRole.CUSTOMER) {
      return null;
    }

    const user = await this.userRepo.findOne({
      where: { id: userId },
      select: ['location', 'currentLat', 'currentLng'],
    });

    if (user) {
      if (user.location?.lat && user.location?.lng) {
        return { lat: user.location.lat, lng: user.location.lng };
      }
      if (user.currentLat && user.currentLng) {
        return { lat: user.currentLat, lng: user.currentLng };
      }
    }

    return null;
  }

  async sortProductsByDistance(
    products: Product[],
    customerLocation: { lat: number; lng: number },
  ): Promise<Product[]> {
    try {
      const merchantsWithProducts = new Map<number, Product[]>();

      for (const product of products) {
        const merchantId = product.merchantId;
        if (merchantId === null || merchantId === undefined) {
          continue;
        }
        if (!merchantsWithProducts.has(merchantId)) {
          merchantsWithProducts.set(merchantId, []);
        }
        merchantsWithProducts.get(merchantId)!.push(product);
      }

      const merchants = await this.userRepo.find({
        where: { id: In([...merchantsWithProducts.keys()]) },
        select: ['id', 'location', 'currentLat', 'currentLng'],
      });

      const merchantLocations = merchants.filter(
        (m) => m.location?.lat && m.location?.lng,
      );

      if (merchantLocations.length === 0) {
        return products;
      }

      const destinations = merchantLocations.map((m) => ({
        id: m.id,
        coordinate: { lat: m.location!.lat, lng: m.location!.lng },
      }));

      const routeResults = await this.googleDirectionsService.getMultipleRoutes(
        customerLocation,
        destinations,
      );

      const merchantDistances = new Map<number, number>();
      for (const [merchantId, _] of merchantsWithProducts) {
        const route = routeResults.get(merchantId);
        merchantDistances.set(merchantId, route?.distanceKm || Infinity);
      }

      const sortedMerchants = [...merchantsWithProducts.entries()].sort(
        (a, b) => {
          const distA = merchantDistances.get(a[0]) || Infinity;
          const distB = merchantDistances.get(b[0]) || Infinity;
          return distA - distB;
        },
      );

      return sortedMerchants.flatMap(([_, prods]) => prods);
    } catch (error) {
      this.logger.error(
        'Failed to sort by distance, returning unsorted',
        error,
      );
      return products;
    }
  }
}

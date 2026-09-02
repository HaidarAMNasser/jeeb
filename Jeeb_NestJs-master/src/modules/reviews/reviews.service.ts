import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review } from '../../database/entities/review.entity';
import { ReviewEntityType } from '../../common/enums/review-entity-type.enum';
import { Order } from '../../database/entities/order.entity';
import { Product } from '../../database/entities/product.entity';
import { User } from '../../database/entities/user.entity';
import { UserRole } from '../../common/enums/user-role.enum';
import { CreateReviewDto } from './dto/create-review.dto';
import { UpdateReviewDto } from './dto/update-review.dto';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { PaginationQueryDto } from '../../common/dto/pagination-query.dto';
import { PaginatedResult } from '../../common/interfaces/paginated-result.interface';

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(Review)
    private readonly reviewsRepository: Repository<Review>,
    @InjectRepository(Order)
    private readonly ordersRepository: Repository<Order>,
    @InjectRepository(Product)
    private readonly productsRepository: Repository<Product>,
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async create(createReviewDto: CreateReviewDto, reviewerId: number) {
    const { entityType, entityId, rating, comment } = createReviewDto;

    if (entityType === ReviewEntityType.ORDER) {
      const order = await this.ordersRepository.findOne({
        where: { id: entityId },
        relations: ['customer'],
      });

      if (!order) {
        throw new NotFoundException('Order not found');
      }

      if (order.status !== OrderStatus.DELIVERED) {
        throw new BadRequestException(
          'Order must be delivered to leave a review',
        );
      }

      if (order.customerId !== reviewerId) {
        throw new BadRequestException('You can only review your own orders');
      }

      // Check if review already exists for this order
      const existingReview = await this.reviewsRepository.findOne({
        where: {
          entityType: ReviewEntityType.ORDER,
          entityId: entityId,
          reviewerId: reviewerId,
        },
      });

      if (existingReview) {
        throw new BadRequestException('You have already reviewed this order');
      }
    } else if (entityType === ReviewEntityType.PRODUCT) {
      const product = await this.productsRepository.findOne({
        where: { id: entityId },
      });

      if (!product) {
        throw new NotFoundException('Product not found');
      }
      // Allow multiple reviews for products by same user (as requested)
    } else if (entityType === ReviewEntityType.MERCHANT) {
      const merchant = await this.usersRepository.findOne({
        where: { id: entityId, role: UserRole.MERCHANT },
      });

      if (!merchant) {
        throw new NotFoundException('Merchant not found');
      }

      // Check if review already exists for this merchant by this customer
      const existingReview = await this.reviewsRepository.findOne({
        where: {
          entityType: ReviewEntityType.MERCHANT,
          entityId: entityId,
          reviewerId: reviewerId,
        },
      });

      if (existingReview) {
        throw new BadRequestException(
          'You have already reviewed this merchant',
        );
      }
    }

    const review = this.reviewsRepository.create({
      rating,
      comment,
      reviewerId,
      entityType,
      entityId,
    });

    return await this.reviewsRepository.save(review);
  }

  async findAllByDriver(
    driverId: number,
    query: PaginationQueryDto,
  ): Promise<PaginatedResult<any>> {
    const { page = 1, limit = 10 } = query;
    const skip = (page - 1) * limit;

    // Similar approach for drivers
    const orders = await this.ordersRepository.find({
      select: ['id'],
      where: {
        deliveryAssignment: {
          deliveryId: driverId,
        },
      },
      relations: ['deliveryAssignment'],
    });
    const orderIds = orders.map((o) => o.id);

    if (orderIds.length === 0) {
      return {
        data: [],
        total: 0,
        page,
        limit,
        totalPages: 0,
      };
    }

    const [reviews, total] = await this.reviewsRepository
      .createQueryBuilder('review')
      .leftJoinAndSelect('review.reviewer', 'reviewer')
      .where('review.entityType = :type', { type: ReviewEntityType.ORDER })
      .andWhere('review.entityId IN (:...ids)', { ids: orderIds })
      .orderBy('review.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      data: reviews,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async findAllPublicByMerchant(
    merchantId: number,
    query: PaginationQueryDto,
  ): Promise<PaginatedResult<any>> {
    const { page = 1, limit = 10 } = query;
    const skip = (page - 1) * limit;

    const merchantProducts = await this.productsRepository.find({
      select: ['id'],
      where: { merchantId },
    });
    const productIds = merchantProducts.map((p) => p.id);

    if (productIds.length === 0) {
      return {
        data: [],
        total: 0,
        page,
        limit,
        totalPages: 0,
      };
    }

    const [reviews, total] = await this.reviewsRepository
      .createQueryBuilder('review')
      .leftJoinAndSelect('review.reviewer', 'reviewer')
      .where('review.entityType = :type', { type: ReviewEntityType.PRODUCT })
      .andWhere('review.entityId IN (:...ids)', { ids: productIds })
      .orderBy('review.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      data: reviews,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // --- Admin Operations ---

  async findAll(query: PaginationQueryDto): Promise<PaginatedResult<Review>> {
    const { page, limit } = query;
    const skip = (page - 1) * limit;

    const [data, total] = await this.reviewsRepository.findAndCount({
      relations: ['reviewer'],
      order: { createdAt: 'DESC' },
      take: limit,
      skip: skip,
    });

    return {
      data,
      total,
      page,
      limit,
    };
  }

  async findOne(id: number) {
    const review = await this.reviewsRepository.findOne({
      where: { id },
      relations: ['reviewer'],
    });
    if (!review) throw new NotFoundException('Review not found');
    return review;
  }

  async update(id: number, updateData: UpdateReviewDto) {
    const review = await this.findOne(id);
    Object.assign(review, updateData);
    return this.reviewsRepository.save(review);
  }

  async remove(id: number) {
    const review = await this.findOne(id);
    return this.reviewsRepository.remove(review);
  }

  // --- Merchant Operations ---

  async findAllForMerchant(
    merchantId: number,
    query: PaginationQueryDto,
  ): Promise<PaginatedResult<Review>> {
    const { page, limit } = query;
    const skip = (page - 1) * limit;

    // Get reviews for merchant's products
    const merchantProducts = await this.productsRepository.find({
      select: ['id'],
      where: { merchantId },
    });
    const productIds = merchantProducts.map((p) => p.id);

    // Build query for reviews
    const queryBuilder = this.reviewsRepository
      .createQueryBuilder('review')
      .leftJoinAndSelect('review.reviewer', 'reviewer');

    // Filter by Type=PRODUCT AND EntityId IN productIds
    if (productIds.length === 0) {
      return {
        data: [],
        total: 0,
        page,
        limit,
      };
    }

    // Construct WHERE clause for products only
    queryBuilder.where(
      '(review.entityType = :productType AND review.entityId IN (:...pIds))',
      {
        productType: ReviewEntityType.PRODUCT,
        pIds: productIds,
      },
    );

    const [data, total] = await queryBuilder
      .orderBy('review.createdAt', 'DESC')
      .take(limit)
      .skip(skip)
      .getManyAndCount();

    return {
      data,
      total,
      page,
      limit,
    };
  }

  async findOneForMerchant(id: number, merchantId: number) {
    const review = await this.reviewsRepository.findOne({
      where: { id },
      relations: ['reviewer'],
    });

    if (!review) throw new NotFoundException('Review not found');

    await this.checkReviewOwnership(review, merchantId);
    return review;
  }

  async updateForMerchant(
    id: number,
    updateData: UpdateReviewDto,
    merchantId: number,
  ) {
    const review = await this.reviewsRepository.findOne({
      where: { id },
    });

    if (!review) throw new NotFoundException('Review not found');

    await this.checkReviewOwnership(review, merchantId);

    Object.assign(review, updateData);
    return this.reviewsRepository.save(review);
  }

  async removeForMerchant(id: number, merchantId: number) {
    const review = await this.reviewsRepository.findOne({
      where: { id },
    });

    if (!review) throw new NotFoundException('Review not found');

    await this.checkReviewOwnership(review, merchantId);

    return this.reviewsRepository.remove(review);
  }

  async findOneForCustomer(id: number, customerId: number) {
    const review = await this.reviewsRepository.findOne({
      where: { id },
      relations: ['reviewer'],
    });

    if (!review) throw new NotFoundException('Review not found');

    if (review.reviewerId !== customerId) {
      throw new ForbiddenException('You can only access your own reviews');
    }

    return review;
  }

  async updateForCustomer(
    id: number,
    updateData: UpdateReviewDto,
    customerId: number,
  ) {
    const review = await this.reviewsRepository.findOne({
      where: { id },
    });

    if (!review) throw new NotFoundException('Review not found');

    if (review.reviewerId !== customerId) {
      throw new ForbiddenException('You can only update your own reviews');
    }

    Object.assign(review, updateData);
    return this.reviewsRepository.save(review);
  }

  async removeForCustomer(id: number, customerId: number) {
    const review = await this.reviewsRepository.findOne({
      where: { id },
    });

    if (!review) throw new NotFoundException('Review not found');

    if (review.reviewerId !== customerId) {
      throw new ForbiddenException('You can only delete your own reviews');
    }

    return this.reviewsRepository.remove(review);
  }

  private async checkReviewOwnership(review: Review, merchantId: number) {
    let isOwner = false;

    if (review.entityType === ReviewEntityType.PRODUCT) {
      const product = await this.productsRepository.findOne({
        where: { id: review.entityId },
      });
      if (product && product.merchantId === merchantId) {
        isOwner = true;
      }
    }

    if (!isOwner) {
      throw new ForbiddenException(
        'You can only access reviews for your own products',
      );
    }
  }

  async findByProduct(
    productId: number,
    query: PaginationQueryDto,
  ): Promise<PaginatedResult<any>> {
    const { page = 1, limit = 10 } = query;
    const skip = (page - 1) * limit;

    const [reviews, total] = await this.reviewsRepository.findAndCount({
      where: {
        entityType: ReviewEntityType.PRODUCT,
        entityId: productId,
      },
      relations: ['reviewer'],
      order: {
        createdAt: 'DESC',
      },
      skip,
      take: limit,
    });

    return {
      data: reviews,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }
}

import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Review } from '../../../database/entities/review.entity';
import { Favorite } from '../../../database/entities/favorite.entity';
import { CartItem } from '../../../database/entities/cart-item.entity';
import { Image } from '../../../database/entities/image.entity';
import { StorageService } from '../../../common/storage/storage.service';
import {
  ImageEntityType,
  ReviewEntityType,
  FavoriteEntityType,
} from '../../../common/enums';

@Injectable()
export class ProductEnrichmentService {
  constructor(
    @InjectRepository(Review)
    private readonly reviewRepo: Repository<Review>,
    @InjectRepository(Favorite)
    private readonly favoriteRepo: Repository<Favorite>,
    @InjectRepository(CartItem)
    private readonly cartItemRepo: Repository<CartItem>,
    private readonly storageService: StorageService,
  ) {}

  async getProductReviews(productIds: number[]): Promise<Map<number, any[]>> {
    if (productIds.length === 0) return new Map();

    const reviews = await this.reviewRepo
      .createQueryBuilder('review')
      .leftJoinAndSelect('review.reviewer', 'reviewer')
      .leftJoinAndMapMany(
        'review.reviewerImages',
        Image,
        'reviewerImage',
        'reviewerImage.entityId = reviewer.id AND reviewerImage.entityType = :type',
        { type: ImageEntityType.USER },
      )
      .where('review.entityType = :entityType', {
        entityType: ReviewEntityType.PRODUCT,
      })
      .andWhere('review.entityId IN (:...productIds)', { productIds })
      .orderBy('review.createdAt', 'DESC')
      .take(6)
      .getMany();

    const reviewsMap = new Map<number, any[]>();
    for (const id of productIds) {
      reviewsMap.set(id, []);
    }

    for (const review of reviews) {
      const productReviews = reviewsMap.get(review.entityId) || [];
      const reviewAny = review as any;

      const reviewerImage =
        reviewAny.reviewerImages && reviewAny.reviewerImages.length > 0
          ? reviewAny.reviewerImages[0]
          : null;

      if (reviewerImage) {
        reviewerImage.url =
          this.storageService.resolveUrl(reviewerImage.url) ||
          reviewerImage.url;
        reviewerImage.mobileUrl = this.storageService.resolveUrl(
          reviewerImage.mobileUrl,
        );
        reviewerImage.thumbnailUrl = this.storageService.resolveUrl(
          reviewerImage.thumbnailUrl,
        );
      }

      productReviews.push({
        id: review.id,
        rating: review.rating,
        comment: review.comment,
        createdAt: review.createdAt,
        reviewer: {
          id: review.reviewer?.id,
          firstName: review.reviewer?.firstName,
          lastName: review.reviewer?.lastName,
          image: reviewerImage,
          imageId: reviewerImage?.id ?? null,
        },
      });

      reviewsMap.set(review.entityId, productReviews);
    }

    return reviewsMap;
  }

  async getFavoriteProductIds(
    userId: number | undefined,
    productIds: number[],
  ): Promise<Set<number>> {
    if (!userId || productIds.length === 0) {
      return new Set<number>();
    }

    const favorites = await this.favoriteRepo.find({
      where: {
        userId,
        entityType: FavoriteEntityType.PRODUCT,
        entityId: In(productIds),
      },
    });

    return new Set(favorites.map((f) => f.entityId));
  }

  async checkIsFavorite(
    userId: number | undefined,
    productId: number,
  ): Promise<boolean> {
    if (!userId) return false;

    const favorite = await this.favoriteRepo.findOne({
      where: {
        userId,
        entityType: FavoriteEntityType.PRODUCT,
        entityId: productId,
      },
    });

    return !!favorite;
  }

  async getProductsInCart(
    userId: number | undefined,
    productIds: number[],
  ): Promise<Map<number, number>> {
    if (!userId || productIds.length === 0) {
      return new Map<number, number>();
    }

    const cartItems = await this.cartItemRepo
      .createQueryBuilder('item')
      .innerJoin('item.cart', 'cart')
      .where('cart.customerId = :userId', { userId })
      .andWhere('item.productId IN (:...productIds)', { productIds })
      .getMany();

    const map = new Map<number, number>();
    for (const item of cartItems) {
      map.set(item.productId, item.quantity);
    }
    return map;
  }
}

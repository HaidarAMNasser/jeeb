import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like } from 'typeorm';
import { Coupon } from '../../database/entities/coupon.entity';
import { CouponUsage } from '../../database/entities/coupon-usage.entity';
import { CouponTargetType } from '../../common/enums/coupon-target-type.enum';
import { UserRole } from '../../common/enums/user-role.enum';

@Injectable()
export class CouponsService {
  constructor(
    @InjectRepository(Coupon)
    private readonly couponRepo: Repository<Coupon>,
    @InjectRepository(CouponUsage)
    private readonly usageRepo: Repository<CouponUsage>,
  ) {}

  /**
   * Create a new coupon (Admin or Merchant)
   */
  async create(
    createCouponDto: Partial<Coupon>,
    ownerId?: number,
    ownerRole?: UserRole,
  ): Promise<Coupon> {
    // If merchant creates coupon, validate restrictions
    if (ownerRole === UserRole.MERCHANT && ownerId) {
      // Merchant can only create GLOBAL or USER coupons for other contexts is disallowed;
      // Merchants can create PRODUCT coupons for their own items
      if (
        createCouponDto.targetType === CouponTargetType.GLOBAL ||
        createCouponDto.targetType === CouponTargetType.USER
      ) {
        throw new ForbiddenException(
          'Merchants can only create coupons for their products',
        );
      }

      // Set ownerId for merchant-created coupons
      createCouponDto.ownerId = ownerId;

      // Validate that target belongs to merchant
      if (
        createCouponDto.targetType === CouponTargetType.PRODUCT &&
        createCouponDto.targetId !== ownerId
      ) {
        throw new ForbiddenException(
          'You can only create coupons for your own products',
        );
      }
    }

    // If Admin creates coupon without owner, it's a global/system coupon
    if (ownerRole === UserRole.ADMIN && !createCouponDto.ownerId) {
      // Admin can create any type including GLOBAL
      createCouponDto.targetType =
        createCouponDto.targetType || CouponTargetType.GLOBAL;
    }

    const coupon = this.couponRepo.create(createCouponDto);
    return this.couponRepo.save(coupon);
  }

  /**
   * Find all coupons with filters
   */
  async findAll(options: {
    targetType?: CouponTargetType;
    targetId?: number;
    ownerId?: number;
    isActive?: boolean;
    page?: number;
    limit?: number;
  }): Promise<{ data: Coupon[]; total: number }> {
    const {
      targetType,
      targetId,
      ownerId,
      isActive,
      page = 1,
      limit = 10,
    } = options;

    const where: any = {};

    if (targetType) where.targetType = targetType;
    if (targetId) where.targetId = targetId;
    if (ownerId !== undefined) where.ownerId = ownerId;
    if (isActive !== undefined) where.isActive = isActive;

    const [data, total] = await this.couponRepo.findAndCount({
      where,
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { data, total };
  }

  /**
   * Get coupons by owner (for merchant admin panel)
   */
  async findByOwner(
    ownerId: number,
    options: {
      page?: number;
      limit?: number;
    } = {},
  ): Promise<{ data: Coupon[]; total: number }> {
    const { page = 1, limit = 10 } = options;

    const [data, total] = await this.couponRepo.findAndCount({
      where: { ownerId },
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { data, total };
  }

  /**
   * Search coupons by code
   */
  async search(
    query: string,
    options: {
      page?: number;
      limit?: number;
    } = {},
  ): Promise<{ data: Coupon[]; total: number }> {
    const { page = 1, limit = 10 } = options;

    const [data, total] = await this.couponRepo.findAndCount({
      where: { code: Like(`%${query}%`) },
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    return { data, total };
  }

  /**
   * Find one coupon by ID
   */
  async findOne(id: number): Promise<Coupon> {
    const coupon = await this.couponRepo.findOne({ where: { id } });

    if (!coupon) {
      throw new NotFoundException(`Coupon with ID ${id} not found`);
    }

    return coupon;
  }

  /**
   * Update coupon (only owner or admin)
   */
  async update(
    id: number,
    updateCouponDto: Partial<Coupon>,
    ownerId?: number,
    ownerRole?: UserRole,
  ): Promise<Coupon> {
    const coupon = await this.findOne(id);

    // Check permissions
    if (ownerRole === UserRole.MERCHANT && coupon.ownerId !== ownerId) {
      throw new ForbiddenException('You can only update your own coupons');
    }

    // Prevent changing critical fields for non-admins
    if (ownerRole === UserRole.MERCHANT) {
      if (
        updateCouponDto.targetType &&
        updateCouponDto.targetType !== coupon.targetType
      ) {
        throw new ForbiddenException('Cannot change coupon target type');
      }
      if (
        updateCouponDto.targetId &&
        updateCouponDto.targetId !== coupon.targetId
      ) {
        throw new ForbiddenException('Cannot change coupon target');
      }
    }

    await this.couponRepo.update(id, updateCouponDto);
    return this.findOne(id);
  }

  /**
   * Delete coupon (only owner or admin)
   */
  async remove(
    id: number,
    ownerId?: number,
    ownerRole?: UserRole,
  ): Promise<void> {
    const coupon = await this.findOne(id);

    // Check permissions
    if (ownerRole === UserRole.MERCHANT && coupon.ownerId !== ownerId) {
      throw new ForbiddenException('You can only delete your own coupons');
    }

    await this.couponRepo.delete(id);
  }

  /**
   * Validate coupon for use
   */
  async validateCoupon(
    code: string,
    userId: number,
    context?: {
      restaurantId?: number;
      productId?: number;
      orderAmount?: number;
    },
  ): Promise<Coupon> {
    const coupon = await this.couponRepo.findOne({ where: { code } });

    if (!coupon) {
      throw new NotFoundException('Coupon not found');
    }

    if (!coupon.isActive) {
      throw new BadRequestException('Coupon is inactive');
    }

    if (coupon.expiresAt < new Date()) {
      throw new BadRequestException('Coupon has expired');
    }

    if (coupon.usageLimit && coupon.usedCount >= coupon.usageLimit) {
      throw new BadRequestException('Coupon usage limit reached');
    }

    // Check target type restrictions
    if (coupon.targetType === CouponTargetType.PRODUCT) {
      if (context?.restaurantId && coupon.targetId !== context.restaurantId) {
        throw new BadRequestException(
          'Coupon is not applicable to this restaurant',
        );
      }
    }

    if (coupon.targetType === CouponTargetType.PRODUCT) {
      if (context?.productId && coupon.targetId !== context.productId) {
        throw new BadRequestException(
          'Coupon is not applicable to this product',
        );
      }
    }

    if (coupon.targetType === CouponTargetType.USER) {
      if (coupon.targetId !== userId) {
        throw new BadRequestException('Coupon is not applicable to this user');
      }
    }

    // Check if user already used this coupon
    const userUsage = await this.usageRepo.findOne({
      where: { couponId: coupon.id, userId },
    });

    if (userUsage) {
      throw new BadRequestException('You have already used this coupon');
    }

    return coupon;
  }

  /**
   * Calculate discount amount
   */
  calculateDiscount(coupon: Coupon, orderAmount: number): number {
    let discount = 0;

    if (coupon.type === 'PERCENTAGE') {
      discount = (orderAmount * coupon.value) / 100;
    } else {
      discount = coupon.value;
    }

    if (coupon.maxDiscountAmount) {
      discount = Math.min(discount, coupon.maxDiscountAmount);
    }

    // Ensure discount doesn't exceed order amount
    return Math.min(discount, orderAmount);
  }

  /**
   * Apply coupon to an order
   */
  async applyCoupon(
    code: string,
    userId: number,
    orderId: number,
    context?: {
      restaurantId?: number;
      productId?: number;
    },
  ): Promise<void> {
    const coupon = await this.validateCoupon(code, userId, context);

    // Track usage
    const usage = this.usageRepo.create({
      couponId: coupon.id,
      userId,
      orderId,
    });

    await this.usageRepo.save(usage);

    // Increment global usage count
    await this.couponRepo.increment({ id: coupon.id }, 'usedCount', 1);
  }

  /**
   * Get coupon usage statistics
   */
  async getUsageStats(couponId: number): Promise<{
    totalUsage: number;
    uniqueUsers: number;
  }> {
    const totalUsage = await this.usageRepo.count({
      where: { couponId },
    });

    // Count unique users who used this coupon
    const usages = await this.usageRepo.find({ where: { couponId } });
    const uniqueUsers = new Set(usages.map((u) => u.userId)).size;

    return { totalUsage, uniqueUsers };
  }
}

import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Coupon } from '../../database/entities/coupon.entity';
import { CouponUsage } from '../../database/entities/coupon-usage.entity';
import { CouponTargetType } from '../../common/enums/coupon-target-type.enum';

@Injectable()
export class CouponsService {
  constructor(
    @InjectRepository(Coupon)
    private readonly couponRepo: Repository<Coupon>,
    @InjectRepository(CouponUsage)
    private readonly usageRepo: Repository<CouponUsage>,
  ) {}

  async create(createCouponDto: Partial<Coupon>): Promise<Coupon> {
    const coupon = this.couponRepo.create(createCouponDto);
    return this.couponRepo.save(coupon);
  }

  async validateCoupon(
    code: string,
    userId: number,
    restaurantId?: number,
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

    // Check if coupon is restricted to a specific restaurant
    if (
      restaurantId &&
      coupon.targetType === CouponTargetType.PRODUCT &&
      coupon.targetId !== restaurantId
    ) {
      throw new BadRequestException(
        'Coupon is not applicable to this restaurant',
      );
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

  async applyCoupon(
    code: string,
    userId: number,
    orderId: number,
  ): Promise<void> {
    const coupon = await this.validateCoupon(code, userId);

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
}

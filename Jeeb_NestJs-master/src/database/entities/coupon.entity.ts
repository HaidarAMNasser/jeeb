import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { CouponTargetType } from '../../common/enums/coupon-target-type.enum';

@Entity('coupons')
export class Coupon {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  code: string;

  @Column({ type: 'enum', enum: ['PERCENTAGE', 'FIXED'] })
  type: 'PERCENTAGE' | 'FIXED';

  @Column({ type: 'int' })
  value: number; // Percentage (e.g., 10 for 10%) or Fixed Amount in smallest currency unit

  @Column({ type: 'int', nullable: true })
  maxDiscountAmount: number | null; // Cap on discount amount

  @Column({ type: 'int', nullable: true })
  usageLimit: number | null; // Total times this coupon can be used globally

  @Column({ type: 'int', default: 0 })
  usedCount: number;

  @Column({ type: 'timestamp' })
  expiresAt: Date;

  @Column({ default: true })
  isActive: boolean;

  // نوع الكوبون: GLOBAL, RESTAURANT, PRODUCT, USER
  @Column({
    type: 'enum',
    enum: CouponTargetType,
    default: CouponTargetType.GLOBAL,
  })
  targetType: CouponTargetType;

  // معرف الكائن المستهدف (restaurantId, productId, userId) - null للـ GLOBAL
  @Column({ type: 'int', nullable: true })
  targetId: number | null;

  // معرف صاحب المطعم الذي أنشأ الكوبون (للمدراء فقط)
  @Column({ type: 'int', nullable: true })
  ownerId: number | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

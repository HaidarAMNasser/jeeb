import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  ManyToMany,
  OneToMany as OneToManyAlt,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from './user.entity';
import { Product } from './product.entity';
import { Order } from './order.entity';
import { OfferProduct } from './offer-product.entity';
import { Image } from './image.entity';
import { DiscountType } from '../../common/enums';

@Entity('offers')
export class Offer {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({
    type: 'jsonb',
    comment: 'Stores name in { ar: string, en: string }',
    transformer: {
      to(value: string): any {
        return { ar: value };
      },
      from(value: any): string {
        return value?.ar || value;
      },
    },
  })
  name: string;

  @Column({
    type: 'jsonb',
    nullable: true,
    transformer: {
      to(value: string): any {
        return { ar: value };
      },
      from(value: any): string {
        return value?.ar || value;
      },
    },
  })
  description: string | null;

  @Column({
    type: 'enum',
    enum: DiscountType,
  })
  discountType: DiscountType;

  @Column({ type: 'float' })
  discountValue: number;

  @Column({ type: 'timestamp', nullable: true })
  startDate: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  endDate: Date | null;

  @Column({ default: true })
  isActive: boolean;

  @Column({ nullable: true })
  merchantId: number | null;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'merchantId' })
  merchant: User;

  @OneToMany(() => OfferProduct, (op) => op.offer)
  offerProducts: OfferProduct[];

  @OneToManyAlt(() => Image, (image) => image.entityId, {
    onDelete: 'CASCADE',
  })
  images: Image[];

  @ManyToMany(() => Order, (order) => order.offers)
  orders: Order[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

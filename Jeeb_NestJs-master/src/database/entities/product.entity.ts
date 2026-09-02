import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Category } from './category.entity';
import { Image } from './image.entity';
import { Review } from './review.entity';
import { User } from './user.entity';
import { OfferProduct } from './offer-product.entity';
import { OrderItem } from './order-item.entity';
import { ExternalProvider, DiscountType } from '../../common/enums';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  merchantId: number | null;

  @ManyToOne(() => User, (user) => user.products, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'merchantId' })
  merchant: User;

  @Column({ nullable: true })
  categoryId: number | null;

  @ManyToOne(() => Category, (category) => category.products, {
    onDelete: 'SET NULL',
    nullable: true,
  })
  @JoinColumn({ name: 'categoryId' })
  category: Category | null;

  @Column({
    type: 'jsonb',
    comment: 'Stores name in { ar: string, en: string }',
    transformer: {
      to(value: string): any {
        return { ar: value };
      },
      from(value: any): string {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return
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
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return
        return value?.ar || value;
      },
    },
  })
  shortDescription: string | null;

  @Column({
    type: 'jsonb',
    nullable: true,
    transformer: {
      to(value: string): any {
        return { ar: value };
      },
      from(value: any): string {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return
        return value?.ar || value;
      },
    },
  })
  description: string | null;

  @Column({
    type: 'int',
    nullable: true,
    comment: 'Number of servings (e.g., 4 people)',
  })
  personCount: number | null;

  @Column({ type: 'integer' })
  price: number; // smallest currency unit

  @Column({ type: 'float', nullable: true })
  discount: number | null; // Discount value (percentage or fixed amount)

  @Column({
    type: 'enum',
    enum: DiscountType,
    nullable: true,
  })
  discountType: DiscountType | null;

  @Column({ default: true })
  isAvailable: boolean;

  @Column({ default: false })
  hasStock: boolean;

  @Column({ type: 'int', nullable: true })
  stockQuantity: number | null;

  // External Integration
  @Column({ default: false })
  isExternal: boolean;

  @Column({
    type: 'enum',
    enum: ExternalProvider,
    nullable: true,
  })
  externalProvider: ExternalProvider | null;

  @Column({ type: 'varchar', nullable: true })
  externalId: string | null; // ID in the external system (e.g. UberEats Product ID)

  @Column({ type: 'jsonb', nullable: true })
  externalMetadata: Record<string, unknown> | null; // Additional data from external API

  // Commission fields - managed exclusively by ADMIN
  @Column({ type: 'float', nullable: true })
  commissionRate: number | null; // App commission rate on this product

  @Column({ default: false })
  commissionConfirmed: boolean; // true only after admin sets the commission

  // Virtual relation for TypeORM to populate images manually
  // Note: Since we are using a polymorphic 'entityId' on the Image table, standard OneToMany doesn't work out-of-the-box
  // without a discriminator.
  // However, we can use a "virtual" OneToMany if we define the inverse properly, OR we manually load images.
  // For simplicity and standard TypeORM usage without complex discriminators, we often load these manually or use a custom condition.
  // But let's try to define it such that `product.images` works.
  // Since we avoided a direct FK in Image, we can't use @OneToMany standardly.
  // We will remove @OneToMany here and handle loading in the Service (repository.find({ where: { entityType: PRODUCT, entityId: id } }))
  // OR we can use a getter/property if we load them manually.

  // For now, let's keep it as a property that is populated manually or via query builder.
  images: Image[];

  // Virtual relation for reviews - populated manually in service
  reviews: Review[];

  @OneToMany(() => OfferProduct, (op) => op.product)
  offerProducts: OfferProduct[];

  @OneToMany(() => OrderItem, (item) => item.product)
  orderItems: OrderItem[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

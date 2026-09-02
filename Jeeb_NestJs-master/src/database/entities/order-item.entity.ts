import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { Order } from './order.entity';
import { Product } from './product.entity';

@Entity('order_items')
export class OrderItem {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  orderId: number;

  @Column({ type: 'int', nullable: true })
  productId: number | null;

  @Column({ type: 'int', nullable: true })
  offerId: number | null;

  @ManyToOne(() => Order, (order: Order) => order.items, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'orderId' })
  order!: Order;

  @ManyToOne(() => Product, (product: Product) => product.orderItems, {
    nullable: true,
    onDelete: 'SET NULL',
  })
  @JoinColumn({ name: 'productId' })
  product: Product;

  @Column()
  productName: string;

  @Column()
  quantity: number;

  @Column({
    type: 'int',
    comment: 'Original product price before any discounts (for analytics)',
  })
  originalUnitPrice: number;

  @Column({
    type: 'int',
    comment: 'Stored in smallest currency unit (e.g., Cents, Halalas)',
  })
  unitPrice: number;

  @Column({
    type: 'int',
    comment: 'quantity * unitPrice (Stored in smallest currency unit)',
  })
  totalPrice: number;

  @Column({ type: 'float', default: 0, comment: 'Commission rate percentage' })
  commissionRate: number;

  @Column({
    type: 'int',
    default: 0,
    comment: 'Commission amount added to price',
  })
  commissionAmount: number;

  @Column({ type: 'int', default: 0, comment: 'Product discount value' })
  productDiscountValue: number;
}

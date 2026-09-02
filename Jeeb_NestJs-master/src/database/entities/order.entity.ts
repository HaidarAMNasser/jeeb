import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  OneToOne,
  ManyToMany,
  JoinTable,
  JoinColumn,
  Index,
} from 'typeorm';
import { OrderStatus, PaymentMethod, DeliveryStatus } from '../../common/enums';
import { User } from './user.entity';
import { OrderItem } from './order-item.entity';
import { DeliveryAssignment } from './delivery-assignment.entity';
import { PaymentTransaction } from './payment-transaction.entity';
import { Offer } from './offer.entity';
import { OrderPaymentReceipt } from './order-payment-receipt.entity';
import { Image } from './image.entity';
import { Area } from './area.entity';

@Entity('orders')
@Index(['status', 'createdAt'])
@Index(['ownerId'])
@Index(['customerId'])
@Index(['areaId'])
export class Order {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  customerId: number;

  @Column({ type: 'varchar', length: 100, nullable: true })
  customerName: string | null;

  @Column({ type: 'varchar', length: 20, nullable: true })
  phone: string | null;

  @ManyToOne(() => User, (user: User) => user.orders, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'customerId' })
  customer!: User;

  @Column({ type: 'int', nullable: true })
  ownerId?: number;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'ownerId' })
  owner?: User;

  @Column({ type: 'int', nullable: true })
  areaId?: number;

  @ManyToOne(() => Area, { nullable: true })
  @JoinColumn({ name: 'areaId' })
  area?: Area;

  // Financials (Stored in smallest currency unit: Halalas/Cents)
  @Column({ type: 'int', comment: 'Stored in smallest unit' })
  totalAmount: number;

  @Column({ type: 'int', default: 0, comment: 'Stored in smallest unit' })
  deliveryFee: number;

  @Column({ type: 'int', default: 0, comment: 'Stored in smallest unit' })
  discountAmount: number;

  @Column({ type: 'varchar', length: 50, nullable: true })
  couponCode: string | null;

  // New: Applied offers (many-to-many)
  @ManyToMany(() => Offer, (offer) => offer.orders)
  @JoinTable({
    name: 'order_offers',
    joinColumn: { name: 'orderId', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'offerId', referencedColumnName: 'id' },
  })
  offers: Offer[];

  @Column({ type: 'int', default: 0, comment: 'Stored in smallest unit' })
  tipAmount: number;

  @Column({ type: 'int', default: 0 })
  platformCommission: number;

  @Column({ type: 'int', default: 0 })
  ownerRevenue: number;

  // Currency Snapshot (To handle multi-currency & exchange rate fluctuations)
  @Column({ length: 3 })
  currencyCode: string; // e.g., 'SAR', 'USD'

  @Column({ type: 'decimal', precision: 10, scale: 4, default: 1 })
  exchangeRate: number; // Rate at the time of order (Base Currency -> Order Currency)

  @Column({
    type: 'enum',
    enum: PaymentMethod,
    default: PaymentMethod.CASH,
  })
  paymentMethod: PaymentMethod;

  @Column({
    type: 'enum',
    enum: OrderStatus,
    default: OrderStatus.PENDING,
  })
  status: OrderStatus;

  @Column({ type: 'timestamp', nullable: true })
  deliveryDeadline: Date;

  @Column({
    type: 'int',
    nullable: true,
    comment: 'Meal preparation time in minutes',
  })
  mealPreparationTime: number | null;

  @Column({ type: 'int', nullable: true, comment: 'Delivery time in minutes' })
  deliveryTime: number | null;

  @Column({ type: 'timestamp', nullable: true })
  cancelledAt: Date | null;

  @Column({
    type: 'enum',
    enum: OrderStatus,
    nullable: true,
    comment: 'Previous status before cancellation for restore functionality',
  })
  previousStatus: OrderStatus | null;

  @Column({ type: 'jsonb', nullable: true })
  deliveryCoordinates: {
    latitude: number;
    longitude: number;
    address?: string;
    landmark?: string;
    specialInstructions?: string;
  }; // Customer delivery location coordinates and details

  @Column({ type: 'jsonb', nullable: true })
  finalLocation: { lat: number; lng: number } | null;

  // Backward-compatible getters for older code paths that may reference finalLat/finalLng
  get finalLat(): number | null {
    return this.finalLocation?.lat ?? null;
  }

  get finalLng(): number | null {
    return this.finalLocation?.lng ?? null;
  }

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations

  @OneToMany(() => OrderItem, (item: OrderItem) => item.order, {
    cascade: true,
  })
  items!: OrderItem[];

  @OneToMany(
    () => DeliveryAssignment,
    (assignment: DeliveryAssignment) => assignment.order,
  )
  deliveryAssignments!: DeliveryAssignment[];

  // Helper to maintain compatibility if needed, though most queries now join the assigned one
  get deliveryAssignment(): DeliveryAssignment | undefined {
    return this.deliveryAssignments?.find(
      (a) =>
        a.status === DeliveryStatus.ASSIGNED ||
        a.status === DeliveryStatus.ACCEPTED ||
        a.status === DeliveryStatus.PICKED ||
        a.status === DeliveryStatus.COMPLETED,
    );
  }

  @OneToOne(
    () => PaymentTransaction,
    (payment: PaymentTransaction) => payment.order,
  )
  paymentTransaction!: PaymentTransaction;

  @OneToMany(() => OrderPaymentReceipt, (receipt) => receipt.order)
  paymentReceipts!: OrderPaymentReceipt[];
}

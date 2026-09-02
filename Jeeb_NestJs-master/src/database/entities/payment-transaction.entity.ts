import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Order } from './order.entity';
import { PaymentProvider, PaymentStatus } from '../../common/enums';

@Entity('payment_transactions')
export class PaymentTransaction {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  orderId: number;

  @OneToOne(() => Order, (order: Order) => order.paymentTransaction)
  @JoinColumn({ name: 'orderId' })
  order!: Order;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  @Column({
    type: 'enum',
    enum: PaymentProvider,
  })
  provider: PaymentProvider; // SYRIATEL_CASH, STRIPE, USDT, etc.

  @Column({
    type: 'enum',
    enum: PaymentStatus,
    default: PaymentStatus.PENDING,
  })
  status: PaymentStatus;

  @Column({ type: 'varchar', nullable: true })
  providerReference: string; // Transaction ID from Stripe/Syriatel/Blockchain

  @Column({ type: 'jsonb', nullable: true })
  metadata: any; // Store extra details (e.g., wallet address for USDT)

  @CreateDateColumn()
  createdAt: Date;
}

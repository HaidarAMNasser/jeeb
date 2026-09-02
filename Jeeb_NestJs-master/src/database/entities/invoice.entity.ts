import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
} from 'typeorm';
import { Order } from './order.entity';

export enum InvoiceType {
  CUSTOMER = 'CUSTOMER', // Invoice TO Customer (Receivable)
  VENDOR = 'VENDOR', // Invoice FROM Vendor (Payable)
}

@Entity('invoices')
export class Invoice {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  orderId: number;

  @ManyToOne(() => Order)
  @JoinColumn({ name: 'orderId' })
  order: Order;

  @Column({
    type: 'enum',
    enum: InvoiceType,
  })
  type: InvoiceType;

  @Column({ type: 'int', comment: 'Amount in smallest currency unit' })
  amount: number;

  @Column({ default: 'PENDING' }) // PENDING, PAID, CANCELLED
  status: string;

  @Column({ type: 'jsonb', nullable: true })
  breakdown: Record<string, string | number> | null; // Details of calculation (e.g., base price, commission, markup)

  @CreateDateColumn()
  createdAt: Date;
}

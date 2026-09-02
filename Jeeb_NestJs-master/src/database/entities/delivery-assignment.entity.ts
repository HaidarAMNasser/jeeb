import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToOne,
  JoinColumn,
  ManyToOne,
} from 'typeorm';
import { Order } from './order.entity';
import { User } from './user.entity';
import { DeliveryStatus } from '../../common/enums';

@Entity('delivery_assignments')
export class DeliveryAssignment {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  orderId: number;

  @ManyToOne(() => Order, (order) => order.deliveryAssignments)
  @JoinColumn({ name: 'orderId' })
  order!: Order;

  @Column()
  deliveryId: number;

  @ManyToOne(() => User, (user) => user.deliveries)
  @JoinColumn({ name: 'deliveryId' })
  delivery!: User;

  @CreateDateColumn()
  assignedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  acceptedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  pickedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  deliveredAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  paidAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  unassignedAt: Date;

  // Grouping for automatic delivery notification rounds
  @Column({ type: 'int', default: 0 })
  groupIndex: number;

  @Column({ type: 'timestamp', nullable: true })
  notifiedAt: Date;

  // Optional: track the driver assigned in this group (alias for compatibility with existing deliveryId)
  // deliveryId serves as the actual driver assignment in this domain
  // @Column({ type: 'int', nullable: true })
  // assignedDriverId?: number;

  @Column({
    type: 'enum',
    enum: DeliveryStatus,
    default: DeliveryStatus.ASSIGNED,
  })
  status: DeliveryStatus;
}

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { MerchantType } from '../../common/enums/merchant-type.enum';

@Entity('merchants')
export class Merchant {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int', unique: true })
  userId: number;

  @OneToOne(() => User, (user) => user.merchant, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ type: 'varchar', nullable: true })
  restaurantName: string | null;

  @Column({ default: false })
  isOpen: boolean;

  @Column({ type: 'varchar', nullable: true })
  description: string | null;

  @Column({ type: 'boolean', default: false })
  hidePhoneNumber?: boolean;

  @Column({ type: 'int', nullable: true })
  estimatedDeliveryMinutes?: number | null;

  @Column({
    type: 'enum',
    enum: MerchantType,
    default: MerchantType.RESTAURANT,
  })
  type: MerchantType;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

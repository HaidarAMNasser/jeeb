import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { User } from './user.entity';
import { LoyaltyTransaction } from './loyalty-transaction.entity';

@Entity('loyalty_account')
export class LoyaltyAccount {
  @PrimaryGeneratedColumn()
  id: number;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ unique: true })
  userId: number;

  @Column({ type: 'int', default: 0 })
  pointsBalance: number;

  @OneToMany(
    () => LoyaltyTransaction,
    (transaction) => transaction.loyaltyAccount,
  )
  transactions: LoyaltyTransaction[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

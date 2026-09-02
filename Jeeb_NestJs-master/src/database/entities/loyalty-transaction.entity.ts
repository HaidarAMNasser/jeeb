import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
  JoinColumn,
} from 'typeorm';
import { LoyaltyAccount } from './loyalty-account.entity';
import { LoyaltyTransactionType } from '../../common/enums/loyalty-type.enum';

@Entity('loyalty_transactions')
export class LoyaltyTransaction {
  @PrimaryGeneratedColumn()
  id: number;

  @ManyToOne(() => LoyaltyAccount, (account) => account.transactions, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'loyaltyAccountId' })
  loyaltyAccount: LoyaltyAccount;

  @Column()
  loyaltyAccountId: number;

  @Column()
  userId: number;

  @Column()
  amount: number;

  @Column({ type: 'enum', enum: LoyaltyTransactionType })
  type: LoyaltyTransactionType;

  @Column({ nullable: true })
  orderId: number;

  @Column({ nullable: true })
  relatedUserId: number;

  @Column({ type: 'int' })
  balanceAfter: number;

  @Column({ type: 'text', nullable: true })
  description: string;

  @CreateDateColumn()
  createdAt: Date;
}

import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
} from 'typeorm';
import { User } from './user.entity';
import { CartItem } from './cart-item.entity';
import { CartOffer } from './cart-offer.entity';

@Entity('carts')
export class Cart {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  customerId: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'customerId' })
  customer: User;

  @Column({ nullable: true })
  merchantId: number | null;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'merchantId' })
  merchant: User | null;

  @OneToMany(() => CartItem, (item) => item.cart, {
    cascade: true,
    onDelete: 'CASCADE',
  })
  items: CartItem[];

  @OneToMany(() => CartOffer, (offer) => offer.cart, {
    cascade: true,
    onDelete: 'CASCADE',
  })
  offers: CartOffer[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

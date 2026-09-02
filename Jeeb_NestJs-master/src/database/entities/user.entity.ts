import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  DeleteDateColumn,
  OneToMany,
  OneToOne,
  ManyToOne,
  JoinColumn,
  Index,
  Check,
} from 'typeorm';
import { Exclude } from 'class-transformer';
import { UserRole } from '../../common/enums';
import { NotificationChannel } from '../../common/enums/notification-channel.enum';
import { Order } from './order.entity';
import { DeliveryAssignment } from './delivery-assignment.entity';
import { Wallet } from './wallet.entity';
import { Product } from './product.entity';
import { Country } from './country.entity';
import { City } from './city.entity';
import { Review } from './review.entity';
import { Favorite } from './favorite.entity';
import { Image } from './image.entity';
import { RolePermission } from './role-permission.entity';
import { Merchant } from './merchant.entity';
import { LoyaltyAccount } from './loyalty-account.entity';
import { Area } from './area.entity';

@Entity('users')
export class User {
  @Column({ type: 'double precision', nullable: true })
  currentLat?: number;

  @Column({ type: 'double precision', nullable: true })
  currentLng?: number;
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  firstName: string;

  @Column()
  lastName: string;

  @Column({ type: 'varchar', unique: true, nullable: true })
  email: string | null;

  @Column({ select: false }) // Hide password by default
  password: string;

  @Column()
  phone: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.CUSTOMER,
  })
  role: UserRole;

  @Column({
    type: 'enum',
    enum: NotificationChannel,
    default: NotificationChannel.FIREBASE,
  })
  notificationChannel: NotificationChannel;

  @Column({ type: 'varchar', nullable: true })
  firebaseToken: string | null;

  @Column({ type: 'int', nullable: true })
  countryId: number;

  @ManyToOne(() => Country)
  @JoinColumn({ name: 'countryId' })
  country!: Country;

  @Column({ type: 'int', nullable: true })
  cityId: number;

  @ManyToOne(() => City)
  @JoinColumn({ name: 'cityId' })
  city!: City;

  @Index()
  @Column({ type: 'int', nullable: true })
  areaId?: number;

  @ManyToOne(() => Area, { nullable: true })
  @JoinColumn({ name: 'areaId' })
  area?: Area;

  @Column({ type: 'varchar', nullable: true })
  address: string;

  @Column({ default: false })
  isOnline: boolean; // For Delivery role

  @Column({ default: true })
  isActive: boolean; // Account active status - admin can suspend/activate accounts

  @Column({ nullable: true, type: 'timestamp' })
  verifiedAt: Date | null; // Account verification timestamp

  @Column({ type: 'jsonb', nullable: true })
  location: { lat: number; lng: number } | null; // For Delivery live tracking

  @Column({ type: 'date', nullable: true })
  birthday: Date | null; // User's birthday for age verification and special offers

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @DeleteDateColumn()
  deletedAt: Date | null;

  // Relations
  @OneToMany(() => Product, (product) => product.merchant)
  products!: Product[];

  @OneToMany(() => Order, (order) => order.customer)
  orders!: Order[];

  @OneToMany(() => Order, (order) => order.owner)
  merchantOrders!: Order[];

  @OneToMany(() => DeliveryAssignment, (assignment) => assignment.delivery)
  deliveries!: DeliveryAssignment[];

  @OneToMany(() => Review, (review) => review.reviewer)
  reviews!: Review[];

  @OneToMany(() => Favorite, (favorite) => favorite.user)
  favorites!: Favorite[];

  @OneToMany(() => Image, (image) => image.user)
  images!: Image[];

  @OneToOne(() => Wallet, (wallet) => wallet.user)
  wallet!: Wallet;

  // Office Owner relations - Delivery drivers belonging to this office owner
  @OneToMany(() => User, (user) => user.officeOwner)
  deliveryDrivers?: User[];

  // Relation to the office owner (for delivery drivers)
  @ManyToOne(() => User, (user) => user.deliveryDrivers)
  @JoinColumn({ name: 'officeOwnerId' })
  officeOwner?: User;

  @Column({ type: 'int', nullable: true })
  officeOwnerId?: number;

  @Exclude()
  get image(): Image | null {
    return this.images && this.images.length > 0 ? this.images[0] : null;
  }

  // Role-based permissions
  @OneToMany(() => RolePermission, (permission) => permission.user)
  rolePermissions!: RolePermission[];

  // Merchant profile (for MERCHANT role)
  @OneToOne(() => Merchant, (merchant) => merchant.user, {
    nullable: true,
    onDelete: 'CASCADE',
  })
  // @JoinColumn({ name: 'id', referencedColumnName: 'userId' })
  merchant?: Merchant | null;

  // Loyalty account relation
  @OneToOne(() => LoyaltyAccount, (account) => account.user, {
    nullable: true,
    onDelete: 'CASCADE',
  })
  loyaltyAccount: LoyaltyAccount;

  // Login tracking fields
  @Column({ nullable: true, type: 'timestamp', name: 'last_login_at' })
  lastLoginAt: Date | null;

  @Column({
    nullable: true,
    type: 'varchar',
    length: 45,
    name: 'last_login_ip',
  })
  lastLoginIp: string | null;
}

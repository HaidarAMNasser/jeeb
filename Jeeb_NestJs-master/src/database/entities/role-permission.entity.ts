import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { User } from './user.entity';

export enum PermissionAction {
  CREATE = 'create',
  READ = 'read',
  UPDATE = 'update',
  DELETE = 'delete',
  MANAGE = 'manage',
}

export enum PermissionResource {
  USERS = 'users',
  PRODUCTS = 'products',
  ORDERS = 'orders',
  CATEGORIES = 'categories',
  COUPONS = 'coupons',
  DELIVERY = 'delivery',
  WALLET = 'wallet',
  REVIEWS = 'reviews',
  REPORTS = 'reports',
  SETTINGS = 'settings',
  MERCHANTS = 'merchants',
  CUSTOMERS = 'customers',
}

@Entity('role_permissions')
@Unique(['userId', 'resource'])
export class RolePermission {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int' })
  userId: number;

  @ManyToOne(() => User, (user) => user.rolePermissions, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({
    type: 'enum',
    enum: PermissionResource,
  })
  resource: PermissionResource;

  @Column({
    type: 'simple-array', // Store as comma-separated values: 'create,read,update'
  })
  actions: string; // Store actions as string array

  @Column({ default: true })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

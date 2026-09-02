import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from './user.entity';

export enum BlockType {
  LOGIN = 'LOGIN',
  IP = 'IP',
}

@Entity('login_blocks')
export class LoginBlock {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true, name: 'user_id' })
  userId: number | null;

  @ManyToOne(() => User, { onDelete: 'CASCADE', nullable: true })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'varchar', length: 255, name: 'email' })
  @Index()
  email: string;

  @Column({ type: 'int', name: 'block_level', default: 1 })
  @Index()
  blockLevel: number;

  @Column({ type: 'timestamp', name: 'blocked_at' })
  blockedAt: Date;

  @Column({ type: 'timestamp', nullable: true, name: 'expires_at' })
  @Index()
  expiresAt: Date | null;

  @Column({
    type: 'enum',
    enum: BlockType,
    default: BlockType.LOGIN,
    name: 'block_type',
  })
  blockType: BlockType;

  @Column({ type: 'varchar', length: 45, nullable: true, name: 'ip_address' })
  ipAddress: string | null;

  @Column({ type: 'int', name: 'attempts_count', default: 0 })
  attemptsCount: number;

  @Column({ type: 'text', nullable: true })
  reason: string | null;

  @Column({ default: true, name: 'is_active' })
  @Index()
  isActive: boolean;

  @Column({ default: false, name: 'is_permanent' })
  isPermanent: boolean;

  @Column({ type: 'timestamp', nullable: true, name: 'unblocked_at' })
  unblockedAt: Date | null;

  @Column({ nullable: true, name: 'unblocked_by' })
  unblockedBy: number | null;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'unblocked_by' })
  unblockedByUser: User;

  @Column({ type: 'text', nullable: true, name: 'admin_note' })
  adminNote: string | null;

  @CreateDateColumn()
  @Index()
  createdAt: Date;
}

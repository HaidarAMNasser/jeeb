import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from './user.entity';
import { AuditAction } from '../../common/enums';

@Entity('audit_logs')
export class AuditLog {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  userId: number; // Who performed the action

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user!: User;

  @Column()
  entityName: string; // e.g., 'Order', 'User', 'Restaurant'

  @Column()
  entityId: number; // The ID of the affected record

  @Column({
    type: 'enum',
    enum: AuditAction,
  })
  action: AuditAction;

  @Column({ type: 'jsonb', nullable: true })
  oldData: any; // Data before change (null for CREATE)

  @Column({ type: 'jsonb', nullable: true })
  newData: any; // Data after change (null for DELETE)

  @Column({ type: 'varchar', nullable: true })
  ipAddress: string; // Optional: IP address of the user

  @Column({ type: 'varchar', nullable: true })
  userAgent: string; // Optional: Browser/Device info

  @CreateDateColumn()
  createdAt: Date;
}

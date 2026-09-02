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
import { NotificationLog } from './notification-log.entity';

export enum RecipientStatus {
  PENDING = 'PENDING',
  RECEIVED = 'RECEIVED',
  READ = 'READ',
}

@Entity('notification_recipients')
export class NotificationRecipient {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  @Index()
  notificationId: number;

  @ManyToOne(() => NotificationLog, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'notificationId' })
  notification: NotificationLog;

  @Column()
  @Index()
  userId: number;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ type: 'timestamp', nullable: true })
  receivedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  @Index()
  readAt: Date;

  @Column({
    type: 'enum',
    enum: RecipientStatus,
    default: RecipientStatus.PENDING,
  })
  status: RecipientStatus;

  @CreateDateColumn()
  createdAt: Date;
}

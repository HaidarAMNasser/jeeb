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
import { ReviewEntityType } from '../../common/enums/review-entity-type.enum';

@Entity('reviews')
@Index(['reviewerId', 'entityType', 'entityId'], {
  unique: true,
  where: '"entityType" = \'ORDER\'',
}) // Ensure one review per user per order (only for order reviews)
export class Review {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int' })
  rating: number; // 1-5

  @Column({ type: 'text', nullable: true })
  comment: string | null;

  @Column()
  reviewerId: number;

  @ManyToOne(() => User, (user) => user.reviews)
  @JoinColumn({ name: 'reviewerId' })
  reviewer: User;

  @Column({ type: 'enum', enum: ReviewEntityType })
  entityType: ReviewEntityType;

  @Column()
  entityId: number;

  @CreateDateColumn()
  createdAt: Date;
}

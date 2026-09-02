import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
  ManyToOne,
} from 'typeorm';
import { ImageEntityType } from '../../common/enums/image-entity-type.enum';
import { User } from './user.entity';

@Entity('images')
@Index(['entityType', 'entityId'])
export class Image {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'enum', enum: ImageEntityType })
  entityType: ImageEntityType;

  @Column()
  entityId: number;

  @Column({ type: 'text' })
  url: string;

  @Column({ type: 'text', nullable: true })
  mobileUrl: string | null;

  @Column({ type: 'text', nullable: true })
  thumbnailUrl: string | null;

  @Column({ default: false })
  isMain: boolean;

  @Column({ default: 0 })
  displayOrder: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @ManyToOne(() => User, (user) => user.images, {
    onDelete: 'CASCADE',
    onUpdate: 'CASCADE',
  })
  user: User;
}

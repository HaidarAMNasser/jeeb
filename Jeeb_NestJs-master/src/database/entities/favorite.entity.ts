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
import { FavoriteEntityType } from '../../common/enums/favorite-entity-type.enum';

@Entity('favorites')
@Index(['userId', 'entityType', 'entityId'], { unique: true }) // Prevent duplicates
export class Favorite {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  userId: number;

  @ManyToOne(() => User, (user) => user.favorites, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({
    type: 'enum',
    enum: FavoriteEntityType,
  })
  entityType: FavoriteEntityType;

  @Column()
  entityId: number;

  @CreateDateColumn()
  createdAt: Date;
}

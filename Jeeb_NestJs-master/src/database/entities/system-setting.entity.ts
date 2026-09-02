import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  UpdateDateColumn,
  CreateDateColumn,
  Index,
} from 'typeorm';

@Entity('system_settings')
@Index(['key'], { unique: true })
export class SystemSetting {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({
    type: 'varchar',
    length: 100,
    unique: true,
    nullable: false,
    comment: 'Setting key/name',
  })
  key: string;

  @Column({
    type: 'jsonb',
    nullable: true,
    comment: 'Setting value (any type)',
  })
  value: unknown;

  @Column({
    type: 'varchar',
    length: 255,
    nullable: true,
    comment: 'Description of the setting',
  })
  description: string;

  @Column({
    type: 'boolean',
    default: true,
    comment: 'Whether this setting is active',
  })
  isActive: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

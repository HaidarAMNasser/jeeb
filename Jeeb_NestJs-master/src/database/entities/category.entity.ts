import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Product } from './product.entity';
import { Image } from './image.entity';

@Entity('categories')
export class Category {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({
    type: 'jsonb',
    comment: 'Stores name in { ar: string, en: string }',
    transformer: {
      to(value: string): any {
        return { ar: value };
      },
      from(value: any): string {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return
        return value?.ar || value;
      },
    },
  })
  name: string;

  @Column({
    type: 'jsonb',
    nullable: true,
    transformer: {
      to(value: string): any {
        return { ar: value };
      },
      from(value: any): string {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-return
        return value?.ar || value;
      },
    },
  })
  description: string;

  // Virtual relation for TypeORM to populate images manually
  images: Image[];

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: 0 })
  displayOrder: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Relations

  // Products belonging to this category
  @OneToMany(() => Product, (product) => product.category)
  products: Product[];
}

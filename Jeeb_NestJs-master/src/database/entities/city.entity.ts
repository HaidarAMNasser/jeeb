import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Country } from './country.entity';

@Entity('cities')
export class City {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({
    type: 'jsonb',
    comment: 'Stores name in { ar: string, en: string }',
  })
  name: { ar: string; en: string };

  @Column()
  countryId: number;

  @ManyToOne(() => Country, (country) => country.cities)
  @JoinColumn({ name: 'countryId' })
  country!: Country;
}

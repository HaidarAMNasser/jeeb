import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { City } from './city.entity';

@Entity('countries')
export class Country {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({
    type: 'jsonb',
    comment: 'Stores name in { ar: string, en: string }',
  })
  name: { ar: string; en: string };

  @Column({ unique: true })
  code: string; // SY, AE, TR...

  @Column({ type: 'varchar', nullable: true })
  callingCode: string; // +963, +971...

  // Currency Info
  @Column({ type: 'varchar', nullable: true })
  currencyCode: string; // SAR, USD, SYP

  @Column({ type: 'varchar', nullable: true })
  currencySymbol: string; // ر.س, $, £

  @Column({ type: 'varchar', nullable: true })
  currencySmallestUnit: string; // Halala, Cent, Piastre

  @Column({ type: 'int', default: 100 })
  currencyFactor: number; // How many smallest units make 1 main unit (e.g., 100)

  @Column({ default: true })
  isActive: boolean;

  @OneToMany(() => City, (city) => city.country)
  cities: City[];
}

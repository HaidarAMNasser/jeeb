import { DataSource } from 'typeorm';
import { Country } from '../src/database/entities/country.entity';
import { City } from '../src/database/entities/city.entity';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

const dataSource = new DataSource({
  type: 'postgres',
  host: DB_HOST || 'localhost',
  port: Number(DB_PORT) || 5432,
  username: DB_USERNAME || 'postgres',
  password: DB_PASSWORD || 'postgres',
  database: DB_DATABASE || 'jeeb_db',
  entities: [path.join(__dirname, '../src/database/entities/*.entity.{ts,js}')],
  synchronize: false,
});

async function seed() {
  try {
    await dataSource.initialize();
    console.log('Database connected.');

    const countryRepo = dataSource.getRepository(Country);
    const cityRepo = dataSource.getRepository(City);

    const syria = await countryRepo.save({
      name: { ar: 'سوريا', en: 'Syria' },
      code: 'SY',
      callingCode: '+963',
      currencyCode: 'SYP',
      currencySymbol: '£',
      currencySmallestUnit: 'Piastre',
      currencyFactor: 100,
      isActive: true,
    });
    console.log('Added Syria');

    const cities = [
      { name: { ar: 'اللاذقية', en: 'Latakia' } },
      { name: { ar: 'طرطوس', en: 'Tartus' } },
      { name: { ar: 'الرقة', en: 'Raqqa' } },
      { name: { ar: 'الحسكة', en: 'Al-Hasakah' } },
      { name: { ar: 'دير الزور', en: 'Deir ez-Zor' } },
      { name: { ar: 'حلب', en: 'Aleppo' } },
      { name: { ar: 'إدلب', en: 'Idlib' } },
      { name: { ar: 'حماة', en: 'Hama' } },
      { name: { ar: 'حمص', en: 'Homs' } },
      { name: { ar: 'دمشق', en: 'Damascus' } },
      { name: { ar: 'ريف دمشق', en: 'Rural Damascus' } },
      { name: { ar: 'السويداء', en: 'Al-Sweida' } },
      { name: { ar: 'القنيطرة', en: 'Quneitra' } },
      { name: { ar: 'درعا', en: 'Daraa' } },
    ];

    const savedCities = await cityRepo.save(
      cities.map((city) => ({
        ...city,
        country: syria,
      })),
    );
    console.log(`Added ${savedCities.length} Syrian cities`);

    console.log('Seeding completed successfully.');
  } catch (error) {
    console.error('Seeding failed:', error);
  } finally {
    await dataSource.destroy();
  }
}

seed();

import { DataSource } from 'typeorm';
import { User } from '../src/database/entities/user.entity';
import { Country } from '../src/database/entities/country.entity';
import { City } from '../src/database/entities/city.entity';
import { Merchant } from '../src/database/entities/merchant.entity';
import { UserRole } from '../src/common/enums/user-role.enum';
import { NotificationChannel } from '../src/common/enums/notification-channel.enum';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as bcrypt from 'bcrypt';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

const dataSource = new DataSource({
  type: 'postgres',
  host: DB_HOST || 'localhost',
  port: Number(DB_PORT) || 5432,
  username: DB_USERNAME || 'postgres',
  password: DB_PASSWORD || 'postgres',
  database: DB_DATABASE || 'delivery_jeeb',
  entities: [path.join(__dirname, '../src/database/entities/*.entity.{ts,js}')],
  synchronize: false,
});

async function seed() {
  try {
    console.log('🚀 Connecting to database for LARGE SCALE seeding...');
    await dataSource.initialize();
    console.log('✅ Database connected.');

    const userRepo = dataSource.getRepository(User);
    const merchantRepo = dataSource.getRepository(Merchant);
    const countryRepo = dataSource.getRepository(Country);
    const cityRepo = dataSource.getRepository(City);

    // 0. Schema Consistency
    console.log('🛠️ Ensuring schema consistency...');
    await dataSource.query(`ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "firebaseToken" varchar`);
    await dataSource.query(`ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "currentLat" double precision`);
    await dataSource.query(`ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "currentLng" double precision`);
    await dataSource.query(`ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "officeOwnerId" int`);

    const country = await countryRepo.findOne({ where: { code: 'SY' } });
    if (!country) throw new Error('Country SY not found');
    const city = await cityRepo.findOne({ where: { countryId: country.id } });
    if (!city) throw new Error('City not found');

    const hashedPassword = await bcrypt.hash('password', 10);
    const BATCH_SIZE = 1000;
    const COUNT_PER_ROLE = 10000;

    const roles = [
      { role: UserRole.MERCHANT, prefix: 'm' },
      { role: UserRole.DELIVERY, prefix: 'd' },
      { role: UserRole.CUSTOMER, prefix: 'c' },
    ];

    for (const { role, prefix } of roles) {
      console.log(`\n👤 Seeding ${COUNT_PER_ROLE} ${role} users...`);
      for (let i = 0; i < COUNT_PER_ROLE; i += BATCH_SIZE) {
        const usersBatch: any[] = [];
        for (let j = 0; j < BATCH_SIZE; j++) {
          const idx = i + j + 1;
          if (idx > COUNT_PER_ROLE) break;

          usersBatch.push({
            firstName: `${role}`,
            lastName: `User ${idx}`,
            email: `${prefix}.${idx}.${Date.now()}@jeeb-stress.com`,
            password: hashedPassword,
            phone: `+963${prefix === 'm' ? '7' : prefix === 'd' ? '8' : '9'}${idx.toString().padStart(6, '0')}`,
            role: role,
            notificationChannel: NotificationChannel.WHATSAPP,
            countryId: country.id,
            cityId: city.id,
            address: `Stress Test Area ${idx}`,
            verifiedAt: new Date(),
            isActive: true,
            isOnline: role === UserRole.DELIVERY,
          });
        }

        const result = await userRepo.insert(usersBatch);
        const insertedIds = result.identifiers.map(id => id.id);

        if (role === UserRole.MERCHANT) {
          const merchantsBatch = insertedIds.map((userId, index) => ({
            userId,
            restaurantName: `Stress Restaurant ${i + index + 1}`,
            description: `Automatic stress test merchant`,
            isOpen: true,
          }));
          await merchantRepo.insert(merchantsBatch);
        }

        console.log(`   ✅ Seeded ${role} ${i + 1} to ${Math.min(i + BATCH_SIZE, COUNT_PER_ROLE)}...`);
      }
    }

    console.log('\n✨ Large scale seeding completed successfully!');
    console.log(`Summary:`);
    console.log(`- Total Users: ${COUNT_PER_ROLE * 3}`);
    console.log(`- Merchants: ${COUNT_PER_ROLE}`);
    console.log(`- Delivery: ${COUNT_PER_ROLE}`);
    console.log(`- Customers: ${COUNT_PER_ROLE}`);

  } catch (error) {
    console.error('❌ Seeding failed:', error);
  } finally {
    await dataSource.destroy();
  }
}

seed();

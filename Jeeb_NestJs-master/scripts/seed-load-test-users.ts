import { DataSource } from 'typeorm';
import { User } from '../src/database/entities/user.entity';
import { Merchant } from '../src/database/entities/merchant.entity';
import { Country } from '../src/database/entities/country.entity';
import { City } from '../src/database/entities/city.entity';
import { UserRole } from '../src/common/enums/user-role.enum';
import { NotificationChannel } from '../src/common/enums/notification-channel.enum';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as bcrypt from 'bcrypt';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

async function seed() {
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

  try {
    await dataSource.initialize();
    console.log('✅ DB connected');

    const userRepo = dataSource.getRepository(User);
    const merchantRepo = dataSource.getRepository(Merchant);
    const country = await dataSource.getRepository(Country).findOne({ where: {} });
    const city = await dataSource.getRepository(City).findOne({ where: {} });
    if (!country || !city) throw new Error('No country/city found. Seed locations first.');

    const password = await bcrypt.hash('password', 10);
    const now = new Date();
    let count = 0;

    const loadUsers = [
      { email: 'loadtest.admin@jeeb.com', role: UserRole.ADMIN, phone: '+963991000000' },
      { email: 'loadtest.merchant1@jeeb.com', role: UserRole.MERCHANT, phone: '+963991000001' },
      { email: 'loadtest.customer1@jeeb.com', role: UserRole.CUSTOMER, phone: '+963991000002' },
      { email: 'loadtest.delivery1@jeeb.com', role: UserRole.DELIVERY, phone: '+963991000003' },
    ];

    for (const u of loadUsers) {
      let user = await userRepo.findOne({ where: { email: u.email } });
      if (!user) {
        user = userRepo.create({
          email: u.email,
          password,
          firstName: 'LoadTest',
          lastName: u.role.charAt(0) + u.role.slice(1).toLowerCase(),
          phone: u.phone,
          role: u.role,
          notificationChannel: NotificationChannel.EMAIL,
          countryId: country.id,
          cityId: city.id,
          address: 'Load Test Address',
          verifiedAt: now,
          isOnline: true,
          isActive: true,
        });
        user = await userRepo.save(user);
        count++;
        console.log(`+ Created ${u.role}: ${u.email}`);

        if (u.role === UserRole.MERCHANT) {
          const existing = await merchantRepo.findOne({ where: { userId: user.id } });
          if (!existing) {
            await merchantRepo.save(
              merchantRepo.create({
                userId: user.id,
                restaurantName: 'Load Test Restaurant',
                description: 'Restaurant for load testing',
                isOpen: true,
              }),
            );
            console.log(`  + Created merchant profile for ${u.email}`);
          }
        }
      } else {
        console.log(`= Already exists: ${u.email}`);
        // Ensure active
        if (!user.isActive || !user.verifiedAt) {
          user.isActive = true;
          user.verifiedAt = now;
          await userRepo.save(user);
          console.log(`  + Activated ${u.email}`);
        }
      }
    }

    console.log(`\n✅ Done. ${count} new users created.`);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  } finally {
    await dataSource.destroy();
  }
}

seed();

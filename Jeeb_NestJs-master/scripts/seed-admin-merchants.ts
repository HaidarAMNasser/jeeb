import { DataSource } from 'typeorm';
import { User } from '../src/database/entities/user.entity';
import { Country } from '../src/database/entities/country.entity';
import { City } from '../src/database/entities/city.entity';
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
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    const userRepo = dataSource.getRepository(User);
    const countryRepo = dataSource.getRepository(Country);
    const cityRepo = dataSource.getRepository(City);

    const syria = await countryRepo.findOne({ where: { code: 'SY' } });
    let damascus: City | null = null;

    let commonData: any = {};

    if (syria) {
      const cities = await cityRepo.find({ where: { countryId: syria.id } });
      damascus =
        cities.find(
          (c) =>
            (c.name as any).en === 'Damascus' || (c.name as any).ar === 'دمشق',
        ) || cities[0];

      commonData.countryId = syria.id;
      if (damascus) {
        commonData.cityId = damascus.id;
      }
    }

    const hashedPassword = await bcrypt.hash('password', 10);
    commonData = {
      ...commonData,
      password: hashedPassword,
      verifiedAt: new Date(),
      address: 'Damascus, Syria',
      isOnline: true,
    };

    const admins = [
      {
        email: 'sama@jeeb.com',
        firstName: 'Sama',
        lastName: 'Admin',
        phone: '+963950000001',
        role: UserRole.ADMIN,
        notificationChannel: NotificationChannel.EMAIL,
      },
      {
        email: 'haider@jeeb.com',
        firstName: 'Haider',
        lastName: 'Admin',
        phone: '+963950000002',
        role: UserRole.ADMIN,
        notificationChannel: NotificationChannel.EMAIL,
      },
      {
        email: 'admin3@jeeb.com',
        firstName: 'Admin',
        lastName: 'System',
        phone: '+963950000003',
        role: UserRole.ADMIN,
        notificationChannel: NotificationChannel.EMAIL,
      },
    ];

    const merchants = [
      {
        email: 'restaurant1@jeeb.com',
        firstName: 'Restaurant',
        lastName: 'One',
        phone: '+963960000001',
        role: UserRole.MERCHANT,
        notificationChannel: NotificationChannel.WHATSAPP,
        restaurantName: 'مطعم第一家',
      },
      {
        email: 'restaurant2@jeeb.com',
        firstName: 'Restaurant',
        lastName: 'Two',
        phone: '+963960000002',
        role: UserRole.MERCHANT,
        notificationChannel: NotificationChannel.WHATSAPP,
        restaurantName: 'مطعم الثاني',
      },
      {
        email: 'restaurant3@jeeb.com',
        firstName: 'Restaurant',
        lastName: 'Three',
        phone: '+963960000003',
        role: UserRole.MERCHANT,
        notificationChannel: NotificationChannel.WHATSAPP,
        restaurantName: 'مطعم النجاح',
      },
    ];

    const allUsers = [
      ...admins.map((u) => ({ ...u, type: 'Admin' })),
      ...merchants.map((u) => ({ ...u, type: 'Merchant' })),
    ];

    for (const userData of allUsers) {
      const { type, ...userInfo } = userData;
      const existingUser = await userRepo.findOne({
        where: { email: userInfo.email },
      });
      if (existingUser) {
        console.log(`User ${userInfo.email} already exists. Skipping...`);
        continue;
      }

      const newUser = userRepo.create({
        ...commonData,
        ...userInfo,
      });

      await userRepo.save(newUser);
      console.log(`Created ${type}: ${userInfo.email} (${userInfo.role})`);
    }

    console.log('\n=== Seeding Summary ===');
    console.log(
      'Admins created: sama@jeeb.com, haider@jeeb.com, admin3@jeeb.com',
    );
    console.log(
      'Merchants created: restaurant1@jeeb.com, restaurant2@jeeb.com, restaurant3@jeeb.com',
    );
    console.log('Password for all accounts: password');
    console.log('========================\n');
  } catch (error) {
    console.error('Seeding failed:', error);
  } finally {
    await dataSource.destroy();
  }
}

seed();

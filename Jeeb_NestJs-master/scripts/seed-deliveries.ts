import { DataSource } from 'typeorm';
import { User } from '../src/database/entities/user.entity';
import { Country } from '../src/database/entities/country.entity';
import { City } from '../src/database/entities/city.entity';
import { UserRole } from '../src/common/enums/user-role.enum';
import { NotificationChannel } from '../src/common/enums/notification-channel.enum';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as bcrypt from 'bcrypt';

// Load environment variables
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

// Delivery driver data
const deliveryNames = [
  { firstName: 'Ahmed', lastName: 'Ali' },
  { firstName: 'Mohammed', lastName: 'Hassan' },
  { firstName: 'Omar', lastName: 'Khalid' },
  { firstName: 'Youssef', lastName: 'Saeed' },
  { firstName: 'Abdullah', lastName: 'Fahd' },
  { firstName: 'Salem', lastName: 'Nasser' },
  { firstName: 'Khaled', lastName: 'Marwan' },
  { firstName: 'Hussein', lastName: 'Jamil' },
  { firstName: 'Ibrahim', lastName: 'Yousef' },
  { firstName: 'Mahmoud', lastName: 'Samir' },
  { firstName: 'Ali', lastName: 'Rashid' },
  { firstName: 'Fadi', lastName: 'Basil' },
  { firstName: 'Rami', lastName: 'Tarek' },
  { firstName: 'Nader', lastName: 'Wael' },
  { firstName: 'Samer', lastName: 'Bilal' },
  { firstName: 'Jamil', lastName: 'Farid' },
  { firstName: 'Tamer', lastName: 'Hani' },
  { firstName: 'Majed', lastName: 'Riyad' },
  { firstName: 'Wissam', lastName: 'Kamal' },
  { firstName: 'Ziad', lastName: 'Amir' },
];

const deliveryPhones = [
  '+963950111111',
  '+963950222222',
  '+963950333333',
  '+963950444444',
  '+963950555555',
  '+963950666666',
  '+963950777777',
  '+963950888888',
  '+963950999999',
  '+963951111111',
  '+963951222222',
  '+963951333333',
  '+963951444444',
  '+963951555555',
  '+963951666666',
  '+963951777777',
  '+963951888888',
  '+963951999999',
  '+963952111111',
  '+963952222222',
];

// Damascus coordinates with slight variations
const damascusCoords = [
  { lat: 33.5138, lng: 36.2765 },
  { lat: 33.5125, lng: 36.278 },
  { lat: 33.515, lng: 36.2745 },
  { lat: 33.5112, lng: 36.2791 },
  { lat: 33.5165, lng: 36.2732 },
  { lat: 33.5143, lng: 36.2758 },
  { lat: 33.5131, lng: 36.2772 },
  { lat: 33.5156, lng: 36.275 },
  { lat: 33.5128, lng: 36.2785 },
  { lat: 33.5147, lng: 36.2741 },
  { lat: 33.5119, lng: 36.2768 },
  { lat: 33.5162, lng: 36.2738 },
  { lat: 33.5135, lng: 36.2777 },
  { lat: 33.5141, lng: 36.2753 },
  { lat: 33.5123, lng: 36.2789 },
  { lat: 33.5158, lng: 36.2747 },
  { lat: 33.5137, lng: 36.2761 },
  { lat: 33.5115, lng: 36.2794 },
  { lat: 33.5168, lng: 36.2735 },
  { lat: 33.5145, lng: 36.2756 },
];

async function seed() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    const userRepo = dataSource.getRepository(User);
    const countryRepo = dataSource.getRepository(Country);
    const cityRepo = dataSource.getRepository(City);

    // Fetch Syria and Damascus for default location
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

    const hashedPassword = await bcrypt.hash('123456', 10);
    commonData = {
      ...commonData,
      password: hashedPassword,
      verifiedAt: new Date(),
      address: 'Test Address, Damascus',
      isOnline: true,
    };

    console.log('Creating 20 delivery drivers...');

    for (let i = 0; i < 20; i++) {
      const name = deliveryNames[i];
      const phone = deliveryPhones[i];
      const coords = damascusCoords[i];

      const userData = {
        email: `delivery${i + 1}@jeeb.com`,
        firstName: name.firstName,
        lastName: name.lastName,
        phone: phone,
        role: UserRole.DELIVERY,
        notificationChannel: NotificationChannel.WHATSAPP,
        currentLat: coords.lat,
        currentLng: coords.lng,
      };

      const existingUser = await userRepo.findOne({
        where: { email: userData.email },
      });

      if (existingUser) {
        console.log(
          `Delivery driver ${userData.email} already exists. Skipping...`,
        );
        continue;
      }

      const newUser = userRepo.create({
        ...commonData,
        ...userData,
      });

      await userRepo.save(newUser);
      console.log(
        `Created delivery driver: ${userData.email} (${userData.firstName} ${userData.lastName})`,
      );
    }

    console.log('Delivery drivers seeding completed successfully.');
  } catch (error) {
    console.error('Seeding failed:', error);
  } finally {
    await dataSource.destroy();
  }
}

seed();

import { DataSource } from 'typeorm';
import { User } from '../src/database/entities/user.entity';
import { Country } from '../src/database/entities/country.entity';
import { City } from '../src/database/entities/city.entity';
import { Merchant } from '../src/database/entities/merchant.entity';
import { Category } from '../src/database/entities/category.entity';
import { Product } from '../src/database/entities/product.entity';
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
    console.log('🚀 Connecting to database...');
    await dataSource.initialize();
    console.log('✅ Database connected.');

    const userRepo = dataSource.getRepository(User);
    const merchantRepo = dataSource.getRepository(Merchant);
    const categoryRepo = dataSource.getRepository(Category);
    const productRepo = dataSource.getRepository(Product);
    const countryRepo = dataSource.getRepository(Country);
    const cityRepo = dataSource.getRepository(City);

    // 0. Ensure missing columns exist in users table (to avoid QueryFailedError)
    console.log('🛠️ Ensuring schema consistency for User table...');
    try {
      await dataSource.query(`ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "firebaseToken" varchar`);
      await dataSource.query(`ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "currentLat" double precision`);
      await dataSource.query(`ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "currentLng" double precision`);
      await dataSource.query(`ALTER TABLE "users" ADD COLUMN IF NOT EXISTS "officeOwnerId" int`);
      console.log('   ✅ User table schema verified.');
    } catch (e) {
      console.warn('   ⚠️ Could not automatically check/add columns. Proceeding anyway...');
    }

    // 1. Get Country and City
    console.log('🌍 Fetching location data...');
    const country = await countryRepo.findOne({ where: { code: 'SY' } });
    if (!country) throw new Error('Country SY not found');
    const city = await cityRepo.findOne({ where: { countryId: country.id } });
    if (!city) throw new Error('City not found for SY');

    // 2. Create Categories
    console.log('📂 Ensuring categories exist...');
    const categoriesData = [
      'Burgers', 'Pizza', 'Sushi', 'Drinks', 'Desserts', 'Salads', 'Pasta', 'Chicken'
    ];
    const categories: Category[] = [];
    for (const name of categoriesData) {
      let cat = await categoryRepo.findOne({ where: { name: name as any } });
      if (!cat) {
        cat = categoryRepo.create({ name: name as any, isActive: true });
        cat = await categoryRepo.save(cat);
        console.log(`   + Created category: ${name}`);
      }
      categories.push(cat);
    }

    // 3. Create 10 Merchants
    console.log('🏪 Creating 10 stress-test merchants...');
    const hashedPassword = await bcrypt.hash('password', 10);
    const merchantUsers: User[] = [];

    for (let i = 1; i <= 10; i++) {
      const email = `stress.merchant${i}@jeeb.com`;
      let user = await userRepo.findOne({ where: { email } });
      
      if (!user) {
        user = userRepo.create({
          email,
          password: hashedPassword,
          firstName: `Stress`,
          lastName: `Merchant ${i}`,
          phone: `+96397000000${i-1}`,
          role: UserRole.MERCHANT,
          notificationChannel: NotificationChannel.WHATSAPP,
          countryId: country.id,
          cityId: city.id,
          address: 'Stress Test Street',
          verifiedAt: new Date(),
          isOnline: true,
          isActive: true,
        });
        user = await userRepo.save(user);
        
        // Create Merchant profile
        const merchant = merchantRepo.create({
          userId: user.id,
          restaurantName: `Stress Test Restaurant ${i}`,
          description: `Big scale stress test merchant number ${i}`,
          isOpen: true,
        });
        await merchantRepo.save(merchant);
        console.log(`   + Created merchant: ${email}`);
      }
      merchantUsers.push(user);
    }

    // 4. Create 5000 Products
    const TOTAL_PRODUCTS = 5000;
    const BATCH_SIZE = 500;
    console.log(`📦 Seeding ${TOTAL_PRODUCTS} products in batches of ${BATCH_SIZE}...`);

    for (let i = 0; i < TOTAL_PRODUCTS; i += BATCH_SIZE) {
      const productsBatch: Product[] = [];
      for (let j = 0; j < BATCH_SIZE; j++) {
        const productIndex = i + j + 1;
        if (productIndex > TOTAL_PRODUCTS) break;

        const merchant = merchantUsers[Math.floor(Math.random() * merchantUsers.length)];
        const category = categories[Math.floor(Math.random() * categories.length)];

        const product = productRepo.create({
          merchantId: merchant.id,
          categoryId: category.id,
          name: `Stress Product ${productIndex}` as any,
          description: `Description for stress product ${productIndex}. This is a long string to test database performance and JSON handling.` as any,
          price: Math.floor(Math.random() * 45000) + 5000,
          isAvailable: true,
          hasStock: true,
          stockQuantity: 100,
          commissionRate: 10,
          commissionConfirmed: true,
        });
        productsBatch.push(product);
      }

      await productRepo.save(productsBatch);
      console.log(`   ✅ Seeded products ${i + 1} to ${Math.min(i + BATCH_SIZE, TOTAL_PRODUCTS)}...`);
    }

    console.log('\n✨ Stress test seeding completed successfully!');
    console.log(`Summary:`);
    console.log(`- Categories: ${categories.length}`);
    console.log(`- Merchants: ${merchantUsers.length}`);
    console.log(`- Total Products: ${TOTAL_PRODUCTS}`);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
  } finally {
    await dataSource.destroy();
  }
}

seed();

import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import * as bcrypt from 'bcrypt';
import * as path from 'path';

config();

const dataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_DATABASE || 'delivery_jeeb',
  entities: [path.join(__dirname, '../src/database/entities/**/*.entity.ts')],
  logging: false,
});

const USERS = [
  {
    email: 'admin@gmail.com',
    password: 'password',
    firstName: 'Admin',
    lastName: 'System',
    phone: '+963900000001',
    role: 'ADMIN',
    isActive: true,
    verifiedAt: new Date(),
  },
  {
    email: 'merchant@gmail.com',
    password: 'password',
    firstName: 'Merchant',
    lastName: 'Owner',
    phone: '+963900000002',
    role: 'MERCHANT',
    isActive: true,
    verifiedAt: new Date(),
  },
  {
    email: 'user@gmail.com',
    password: 'password',
    firstName: 'Customer',
    lastName: 'User',
    phone: '+963900000003',
    role: 'CUSTOMER',
    isActive: true,
    verifiedAt: new Date(),
  },
  {
    email: 'delivery@gmail.com',
    password: 'password',
    firstName: 'Delivery',
    lastName: 'Driver',
    phone: '+963900000004',
    role: 'DELIVERY',
    isActive: true,
    verifiedAt: new Date(),
  },
];

async function seedUsers() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.\n');

    const hashedPassword = await bcrypt.hash('password', 10);

    for (const user of USERS) {
      const existing = await dataSource
        .createQueryBuilder()
        .select('user')
        .from('users', 'user')
        .where('user.email = :email', { email: user.email })
        .getOne();

      if (existing) {
        console.log(`⚠  ${user.role} (${user.email}) already exists — skipped`);
        continue;
      }

      await dataSource
        .createQueryBuilder()
        .insert()
        .into('users')
        .values({
          ...user,
          password: hashedPassword,
          notificationChannel: 'EMAIL',
          isOnline: false,
          createdAt: new Date(),
          updatedAt: new Date(),
        })
        .execute();

      console.log(`✅ ${user.role.padEnd(9)} — ${user.email} / password`);
    }

    console.log('\n🎉 All users created successfully!');
    console.log('\n📋 Login credentials:');
    for (const u of USERS) {
      console.log(`   ${u.role.padEnd(9)} → email: ${u.email}  |  password: password`);
    }

    await dataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    await dataSource.destroy();
    process.exit(1);
  }
}

seedUsers();

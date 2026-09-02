import { DataSource } from 'typeorm';
import { config } from 'dotenv';
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

async function listGuestUsers() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.\n');

    const guestUsers = await dataSource
      .createQueryBuilder()
      .select('user')
      .from('users', 'user')
      .addSelect('user.email')
      .where("user.email LIKE 'guest-%@jeeb.local'")
      .andWhere('user.deletedAt IS NULL')
      .getMany();

    if (guestUsers.length === 0) {
      console.log('❌ No guest users found.');
      await dataSource.destroy();
      process.exit(0);
    }

    console.log('📊 Guest Users Summary:');
    console.log('─'.repeat(50));
    console.log(`Total guest users: ${guestUsers.length}`);
    console.log('');

    guestUsers.forEach((user: any, index: number) => {
      console.log(`${index + 1}. ID: ${user.id}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Created: ${user.createdAt}`);
      console.log(`   Last Login: ${user.lastLoginAt || 'N/A'}`);
      console.log('');
    });

    await dataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    await dataSource.destroy();
    process.exit(1);
  }
}

listGuestUsers();
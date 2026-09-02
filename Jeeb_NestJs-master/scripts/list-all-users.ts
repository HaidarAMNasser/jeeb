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

async function listAllUsers() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.\n');

    const users = await dataSource
      .createQueryBuilder()
      .select('user')
      .from('users', 'user')
      .addSelect('user.email')
      .where('user.deletedAt IS NULL')
      .orderBy('user.createdAt', 'DESC')
      .limit(10)
      .getMany();

    console.log('📊 Last 10 Users:');
    console.log('─'.repeat(60));
    
    users.forEach((user: any, index: number) => {
      console.log(`${index + 1}. ID: ${user.id}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Created: ${user.createdAt}`);
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

listAllUsers();
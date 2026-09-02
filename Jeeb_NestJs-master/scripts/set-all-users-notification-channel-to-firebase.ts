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
  logging: true,
});

async function main() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    console.log('Setting notificationChannel to FIREBASE for all users...');

    const result = await dataSource
      .createQueryBuilder()
      .update('users')
      .set({ notificationChannel: 'FIREBASE' })
      .where('notificationChannel != :channel OR notificationChannel IS NULL', {
        channel: 'FIREBASE',
      })
      .execute();

    console.log(`✅ Updated ${result.affected} user(s) to FIREBASE.`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error updating notification channels:', error);
    process.exit(1);
  }
}

main();

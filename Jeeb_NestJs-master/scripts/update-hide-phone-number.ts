import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import * as path from 'path';

// Load environment variables from .env file
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

async function updateHidePhoneNumber() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    console.log('Updating hidePhoneNumber to false for all merchants...');

    const result = await dataSource
      .createQueryBuilder()
      .update('merchants')
      .set({ hidePhoneNumber: false })
      .execute();

    console.log(`✅ Updated ${result.affected} merchant(s) successfully.`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error updating merchants:', error);
    process.exit(1);
  }
}

updateHidePhoneNumber();

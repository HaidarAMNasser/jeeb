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
  synchronize: true, // This will update the schema without dropping data if possible
  logging: true,
});

async function syncSchema() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    console.log('Synchronizing schema...');
    // synchronize(false) means don't drop schema, just update
    await dataSource.synchronize(false);

    console.log('Schema synchronized successfully.');
    process.exit(0);
  } catch (error) {
    console.error('Error synchronizing schema:', error);
    process.exit(1);
  }
}

syncSchema();

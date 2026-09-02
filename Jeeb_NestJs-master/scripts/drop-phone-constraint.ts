import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

const dataSource = new DataSource({
  type: 'postgres',
  host: DB_HOST || 'localhost',
  port: Number(DB_PORT) || 5432,
  username: DB_USERNAME || 'postgres',
  password: DB_PASSWORD || 'postgres',
  database: DB_DATABASE || 'delivery_jeeb',
  synchronize: false,
});

async function run() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    console.log('Dropping unique constraint idx_user_phone_unique...');
    // Drop both index and constraint if they exist
    await dataSource.query(`DROP INDEX IF EXISTS "idx_user_phone_unique"`);
    // Some versions of TypeORM might have created a named constraint too
    await dataSource.query(`ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "idx_user_phone_unique"`);
    
    console.log('✅ Constraint dropped successfully.');
  } catch (error) {
    console.error('❌ Failed to drop constraint:', error);
  } finally {
    await dataSource.destroy();
  }
}

run();

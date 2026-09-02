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

async function fixDuplicatePhones() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.\n');

    console.log('=== Finding duplicate phone numbers ===');
    const duplicates = await dataSource.query(`
      SELECT phone, COUNT(*) as count 
      FROM users 
      GROUP BY phone 
      HAVING COUNT(*) > 1
    `);

    if (duplicates.length === 0) {
      console.log('No duplicate phone numbers found.');
      return;
    }

    console.log(`Found ${duplicates.length} duplicate phone numbers:`);
    console.log(duplicates);

    console.log('\n=== Fixing duplicate phone numbers ===');

    // Update duplicate phones to be unique by appending user ID
    const result = await dataSource.query(`
      UPDATE users 
      SET phone = phone || '-' || id::text
      WHERE phone IN (
        SELECT phone 
        FROM users 
        GROUP BY phone 
        HAVING COUNT(*) > 1
      )
    `);

    console.log('Updated', result.rowCount || 'multiple', 'records');

    console.log('\n=== Verifying fix ===');
    const remainingDuplicates = await dataSource.query(`
      SELECT phone, COUNT(*) as count 
      FROM users 
      GROUP BY phone 
      HAVING COUNT(*) > 1
    `);

    if (remainingDuplicates.length === 0) {
      console.log('✅ All phone numbers are now unique!');
    } else {
      console.log('⚠️ Still have duplicates:', remainingDuplicates);
    }

    // Show sample users
    console.log('\n=== Sample users ===');
    const users = await dataSource.query(`
      SELECT id, phone, email, role 
      FROM users 
      LIMIT 10
    `);
    console.table(users);

    console.log('\n✅ Script completed successfully!');
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await dataSource.destroy();
    process.exit(0);
  }
}

fixDuplicatePhones();

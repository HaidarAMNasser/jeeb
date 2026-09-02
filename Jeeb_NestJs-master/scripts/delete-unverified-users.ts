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

async function deleteUnverifiedUsers() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    // First, let's see how many unverified users exist
    const unverifiedUsers = await dataSource
      .createQueryBuilder()
      .select('user')
      .from('users', 'user')
      .where('user.verifiedAt IS NULL')
      .getMany();

    console.log(`Found ${unverifiedUsers.length} unverified user(s).`);

    if (unverifiedUsers.length === 0) {
      console.log('No unverified users to delete.');
      process.exit(0);
    }

    console.log('Unverified users:');
    unverifiedUsers.forEach((user: any) => {
      console.log(
        `  - ID: ${user.id}, Email: ${user.email}, Phone: ${user.phone}, Role: ${user.role}`,
      );
    });

    console.log('\nDeleting unverified users...');

    const result = await dataSource
      .createQueryBuilder()
      .delete()
      .from('users')
      .where('verifiedAt IS NULL')
      .execute();

    console.log(
      `✅ Deleted ${result.affected} unverified user(s) successfully.`,
    );
    process.exit(0);
  } catch (error) {
    console.error('❌ Error deleting unverified users:', error);
    process.exit(1);
  }
}

deleteUnverifiedUsers();

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

async function deleteGuestUsers(deleteThem: boolean = false) {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.\n');

    const guestUsers = await dataSource
      .createQueryBuilder()
      .select('user')
      .from('users', 'user')
      .where('user.email LIKE :pattern', { pattern: 'guest@jeeb.local' })
      .orWhere('user.email LIKE :pattern2', { pattern2: 'guest-%@jeeb.local' })
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

    if (deleteThem) {
      console.log('🗑️  Deleting guest users...');

      for (const user of guestUsers) {
        await dataSource
          .createQueryBuilder()
          .update('users')
          .set({ deletedAt: new Date() })
          .where('id = :id', { id: user.id })
          .execute();
        console.log(`   Deleted user ID: ${user.id}`);
      }

      console.log(`\n✅ Successfully deleted ${guestUsers.length} guest users.`);
    } else {
      console.log('⚠️  Run with --delete flag to actually delete users.');
      console.log('Example: npm run db:delete-guest -- --delete');
    }

    await dataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    await dataSource.destroy();
    process.exit(1);
  }
}

const args = process.argv.slice(2);
const shouldDelete = args.includes('--delete');

deleteGuestUsers(shouldDelete);
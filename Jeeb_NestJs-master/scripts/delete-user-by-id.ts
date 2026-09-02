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

async function deleteUser() {
  const userId = parseInt(process.argv[2], 10);

  if (!userId || isNaN(userId)) {
    console.error('❌ Please provide a valid user ID.');
    console.log('Usage: npm run db:delete-user -- <userId>');
    console.log('Example: npm run db:delete-user -- 123');
    process.exit(1);
  }

  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    console.log(`Looking for user with ID: ${userId}...`);

    const user = await dataSource
      .createQueryBuilder()
      .select('user')
      .from('users', 'user')
      .where('user.id = :id', { id: userId })
      .getOne();

    if (!user) {
      console.log(`❌ User with ID ${userId} not found.`);
      process.exit(0);
    }

    console.log('User found:');
    console.log(`  - ID: ${(user as any).id}`);
    console.log(`  - Email: ${(user as any).email}`);
    console.log(`  - Phone: ${(user as any).phone}`);
    console.log(`  - Role: ${(user as any).role}`);
    console.log(`  - verifiedAt: ${(user as any).verifiedAt}`);
    console.log(`  - isActive: ${(user as any).isActive}`);
    console.log(`  - createdAt: ${(user as any).createdAt}`);

    console.log('\nDeleting user...');

    const result = await dataSource
      .createQueryBuilder()
      .delete()
      .from('users')
      .where('id = :id', { id: userId })
      .execute();

    if (result.affected && result.affected > 0) {
      console.log(`✅ User with ID ${userId} deleted successfully.`);
    } else {
      console.log(`❌ Failed to delete user with ID ${userId}.`);
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error deleting user:', error);
    process.exit(1);
  }
}

deleteUser();

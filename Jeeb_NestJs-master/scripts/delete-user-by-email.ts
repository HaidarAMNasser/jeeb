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

async function deleteUserByEmail() {
  const email = process.argv[2];

  if (!email) {
    console.error('❌ Please provide an email address.');
    console.log('Usage: npm run db:delete-user-by-email -- <email>');
    console.log('Example: npm run db:delete-user-by-email -- user@example.com');
    process.exit(1);
  }

  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    console.log(`Looking for user with email: ${email}...`);

    const user = await dataSource
      .createQueryBuilder()
      .select('user')
      .from('users', 'user')
      .where('user.email = :email', { email })
      .getOne();

    if (!user) {
      console.log(`❌ User with email ${email} not found.`);
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
      .where('email = :email', { email })
      .execute();

    if (result.affected && result.affected > 0) {
      console.log(`✅ User with email ${email} deleted successfully.`);
    } else {
      console.log(`❌ Failed to delete user with email ${email}.`);
    }

    process.exit(0);
  } catch (error) {
    console.error('❌ Error deleting user:', error);
    process.exit(1);
  }
}

deleteUserByEmail();

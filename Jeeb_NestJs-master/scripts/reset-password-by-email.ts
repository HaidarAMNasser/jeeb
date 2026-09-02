import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import * as path from 'path';
import * as bcrypt from 'bcrypt';

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

async function resetPassword() {
  const email = process.argv[2];
  const newPassword = process.argv[3];

  if (!email || !newPassword) {
    console.error('❌ Please provide email and new password.');
    console.log('Usage: npm run db:reset-password -- <email> <newPassword>');
    console.log('Example: npm run db:reset-password -- admin@gmail.com password123');
    process.exit(1);
  }

  try {
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
      console.log(`❌ User with email '${email}' not found.`);
      await dataSource.destroy();
      process.exit(1);
    }

    console.log(`User found: ${(user as any).firstName} ${(user as any).lastName} (ID: ${(user as any).id})`);

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await dataSource
      .createQueryBuilder()
      .update('users')
      .set({ password: hashedPassword })
      .where('email = :email', { email })
      .execute();

    console.log(`✅ Password updated successfully for ${email}`);
    await dataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    await dataSource.destroy();
    process.exit(1);
  }
}

resetPassword();

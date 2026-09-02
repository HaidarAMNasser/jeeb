import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import * as bcrypt from 'bcrypt';
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

async function createAdminUser() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.\n');

    const email = 'assem@gmail.com';
    const password = 'password123';
    const firstName = 'Assem';
    const lastName = 'Admin';

    // Check if user already exists
    const existingUser = await dataSource
      .createQueryBuilder()
      .select('user')
      .from('users', 'user')
      .where('user.email = :email', { email })
      .getOne();

    if (existingUser) {
      console.log('❌ User with this email already exists.');
      
      if (existingUser.deletedAt) {
        console.log('   User is soft-deleted. Restoring...');
        await dataSource
          .createQueryBuilder()
          .update('users')
          .set({ deletedAt: null, isActive: true })
          .where('id = :id', { id: existingUser.id })
          .execute();
        console.log('✅ User restored successfully.');
      }
      
      await dataSource.destroy();
      process.exit(0);
    }

    // Create password hash
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert new admin user
await dataSource
          .createQueryBuilder()
          .insert()
          .into('users')
          .values({
            email,
            password: hashedPassword,
            firstName,
            lastName,
            phone: '+963000000000',
            role: 'ADMIN',
            notificationChannel: 'EMAIL',
            isActive: true,
            isOnline: false,
            verifiedAt: new Date(),
            createdAt: new Date(),
            updatedAt: new Date(),
          })
          .execute();

    console.log('✅ Admin user created successfully!');
    console.log('');
    console.log('📊 Admin User Details:');
    console.log('   - Email:', email);
    console.log('   - Password: password123');
    console.log('   - Role: ADMIN');
    console.log('');
    console.log('📝 You can now login with:');
    console.log('   POST /auth/login');
    console.log('   { "email": "assem@gmail.com", "password": "password123" }');

    await dataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    await dataSource.destroy();
    process.exit(1);
  }
}

createAdminUser();
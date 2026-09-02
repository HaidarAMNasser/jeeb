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
  synchronize: false,
  dropSchema: false,
});

async function fixUserMerchantConstraint() {
  try {
    console.log('🔧 Connecting to database...');
    await dataSource.initialize();
    console.log('✅ Database connected.');

    // Check if merchants table exists
    console.log('🔍 Checking if merchants table exists...');
    const tableCheck = await dataSource.query(`
     SELECT EXISTS (
       SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'merchants'
      );
    `);

    const merchantsTableExists =
      tableCheck[0]?.exists || tableCheck[0]?.bool || false;

    if (!merchantsTableExists) {
      console.log('❌ merchants table does not exist!');
      console.log(
        '💡 Please run "npm run db:sync" first to create the missing tables.',
      );
      console.log('   Or run: ts-node scripts/sync-schema.ts');
      throw new Error('merchants table does not exist. Run schema sync first.');
    }

    console.log('✅ merchants table exists.');

    console.log('🔍 Checking for MERCHANT users without merchant records...');

    // First, let's check if merchants table exists and get its actual name
    const tableCheck2 = await dataSource.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      AND table_name LIKE '%merchant%'
    `);

    console.log('📋 Available merchant tables:', tableCheck2);

    if (tableCheck2.length === 0) {
      console.log('❌ No merchant table found!');
      console.log(
        '💡 Please run "npm run db:sync" first to create the merchants table.',
      );
      throw new Error('merchants table does not exist. Run schema sync first.');
    }

    const merchantsTableName = tableCheck2[0].table_name;
    console.log(`✅ Using merchant table: ${merchantsTableName}`);

    // Find MERCHANT users without merchant records
    const merchantUsersWithoutRecords = await dataSource.query(`
      SELECT u.id, u.email, u.firstName, u.lastName, u.phone, u.countryId, u.cityId, 
             u.currentLat, u.currentLng, u.location, u.isActive, u.verifiedAt, u.createdAt
      FROM users u
      LEFT JOIN ${merchantsTableName} m ON u.id = m.userId
      WHERE u.role = 'MERCHANT' AND m.userId IS NULL
    `);

    if (merchantUsersWithoutRecords.length > 0) {
      console.log(
        `❌ Found ${merchantUsersWithoutRecords.length} MERCHANT users without merchant records:`,
      );
      console.table(merchantUsersWithoutRecords);

      console.log('🏪 Creating merchant records for these users...');

      for (const user of merchantUsersWithoutRecords) {
        console.log(
          `   Creating merchant for user: ${user.email} (ID: ${user.id}, userId: ${user.id})`,
        );

        // Create merchant record using the user ID as merchant userId
        await dataSource.query(
          `
          INSERT INTO ${merchantsTableName} (userId, restaurantName, email, phone, countryId, cityId, 
                               isOpen, minimumOrderAmount, estimatedDeliveryMinutes, isActive, 
                               createdAt, updatedAt)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        `,
          [
            user.id, // userId in merchants table
            user.firstName
              ? `${user.firstName} ${user.lastName}'s Restaurant`
              : 'Restaurant', // restaurantName
            user.email, // email
            user.phone, // phone
            user.countryId, // countryId
            user.cityId, // cityId
            true, // isOpen
            0, // minimumOrderAmount
            30, // estimatedDeliveryMinutes
            user.isActive || true, // isActive
          ],
        );
      }

      console.log(
        `✅ Created ${merchantUsersWithoutRecords.length} merchant records.`,
      );
    } else {
      console.log('✅ No MERCHANT users without merchant records found.');
    }

    console.log('🎯 User-merchant constraint fix completed successfully!');
    await dataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error fixing user-merchant constraint:', error);
    await dataSource.destroy();
    process.exit(1);
  }
}

fixUserMerchantConstraint();

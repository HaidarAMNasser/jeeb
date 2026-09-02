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
  synchronize: false, // We'll handle migrations manually
  dropSchema: false, // We'll drop tables manually
});

async function resetSettings() {
  try {
    console.log('🔧 Connecting to database...');
    await dataSource.initialize();
    console.log('✅ Database connected.');

    console.log('🗑️ Dropping system_settings table...');
    await dataSource.query(`DROP TABLE IF EXISTS system_settings CASCADE`);
    console.log('✅ system_settings table dropped.');

    console.log('🔄 Recreating system_settings table...');
    await dataSource.query(`
      CREATE TABLE system_settings (
        id SERIAL PRIMARY KEY,
        key VARCHAR(100) NOT NULL UNIQUE,
        value JSONB NULL,
        description VARCHAR(255) NULL,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ system_settings table recreated.');

    console.log('📝 Creating unique index on key...');
    await dataSource.query(`
      CREATE UNIQUE INDEX idx_system_settings_key ON system_settings (key)
    `);
    console.log('✅ Index created on key column.');

    console.log('🔍 Creating check constraint for key...');
    await dataSource.query(`
      ALTER TABLE system_settings 
      ADD CONSTRAINT chk_system_settings_key_not_null 
      CHECK (key IS NOT NULL)
    `);
    console.log('✅ Check constraint added for key column.');

    console.log('💾 Resetting settings to default values...');
    const defaultSettings = [
      {
        key: 'driverRequestTimeoutSeconds',
        value: 180,
        description: 'Time in seconds to wait for drivers to accept order',
      },
      {
        key: 'driverRequestBatchSize',
        value: 3,
        description: 'Number of drivers to notify in each batch',
      },
      {
        key: 'initialSearchRadius',
        value: 5.0,
        description: 'Initial search radius in km',
      },
      {
        key: 'searchRadiusIncrement',
        value: 2.0,
        description: 'Radius increment for each batch',
      },
      {
        key: 'maxSearchRadius',
        value: 20.0,
        description: 'Maximum search radius in km',
      },
      {
        key: 'externalOrderMarkupRate',
        value: 0.0,
        description: 'Commission rate for external orders',
      },
      {
        key: 'defaultProductCommissionRate',
        value: 10.0,
        description: 'Default commission rate for products',
      },
      {
        key: 'productsAutoConfirmed',
        value: true,
        description: 'Auto-confirm products for customers',
      },
      {
        key: 'supportPhone',
        value: '+963912345678',
        description: 'Customer support phone',
      },
      {
        key: 'supportEmail',
        value: 'support@jeeb.com',
        description: 'Customer support email',
      },
      {
        key: 'whatsappNumber',
        value: '+963912345678',
        description: 'WhatsApp contact number',
      },
      {
        key: 'websiteUrl',
        value: 'https://jeeb.com',
        description: 'Company website URL',
      },
      {
        key: 'address',
        value: 'Damascus, Syria',
        description: 'Company address',
      },
      {
        key: 'termsAndConditions',
        value: '',
        description: 'Terms and Conditions text',
      },
      {
        key: 'privacyPolicy',
        value: '',
        description: 'Privacy Policy text',
      },
      {
        key: 'aboutUs',
        value: '',
        description: 'About Us text',
      },
    ];

    for (const setting of defaultSettings) {
      await dataSource.query(
        `
        INSERT INTO system_settings (key, value, description, is_active, created_at, updated_at)
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      `,
        [setting.key, JSON.stringify(setting.value), setting.description, true],
      );
    }
    console.log(`✅ Inserted ${defaultSettings.length} default settings.`);

    console.log('🎯 Settings reset completed successfully!');
    console.log('📊 Summary:');
    console.log(`   - Dropped and recreated system_settings table`);
    console.log(`   - Added ${defaultSettings.length} default settings`);
    console.log(`   - Applied unique constraint on key column`);
    console.log(`   - Added check constraint to prevent NULL values`);

    await dataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error resetting settings:', error);
    await dataSource.destroy();
    process.exit(1);
  }
}

resetSettings();

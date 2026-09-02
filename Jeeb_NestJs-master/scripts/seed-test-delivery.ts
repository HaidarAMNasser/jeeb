import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as bcrypt from 'bcrypt';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

export const TEST_DELIVERY = {
  email: 'delivery-test@jeeb.test',
  phone: '+963991000003',
  firstName: 'Test',
  lastName: 'Delivery',
  password: '123456',
};

function getDataSource() {
  return new DataSource({
    type: 'postgres',
    host: DB_HOST || 'localhost',
    port: Number(DB_PORT) || 5432,
    username: DB_USERNAME || 'postgres',
    password: DB_PASSWORD || 'postgres',
    database: DB_DATABASE || 'delivery_jeeb',
    synchronize: false,
  });
}

export async function seedTestDelivery(ds?: DataSource) {
  const dataSource = ds || getDataSource();
  const shouldDestroy = !ds;
  if (!dataSource.isInitialized) await dataSource.initialize();

  try {
    const hashed = await bcrypt.hash(TEST_DELIVERY.password, 10);

    let userId: number;
    const existing = await dataSource.query(`SELECT id FROM users WHERE email=$1`, [TEST_DELIVERY.email]);
    if (existing.length) {
      userId = existing[0].id;
      console.log(`⚠  Delivery ${TEST_DELIVERY.email} already exists id=${userId}`);
    } else {
      const rows = await dataSource.query(
        `INSERT INTO users (email, password, "firstName", "lastName", phone, role, "notificationChannel", "isOnline", "isActive", "verifiedAt", address, "countryId", "cityId", "currentLat", "currentLng", location, "createdAt", "updatedAt")
         VALUES ($1,$2,$3,$4,$5,'DELIVERY','FIREBASE',true,true,NOW(),'Damascus, Syria',1,1,33.5138,36.2765,'{"lat":33.5138,"lng":36.2765}',NOW(),NOW()) RETURNING id`,
        [TEST_DELIVERY.email, hashed, TEST_DELIVERY.firstName, TEST_DELIVERY.lastName, TEST_DELIVERY.phone],
      );
      userId = rows[0].id;
      console.log(`✅ Delivery created id=${userId} email=${TEST_DELIVERY.email}`);
    }

    const result = { userId, email: TEST_DELIVERY.email, phone: TEST_DELIVERY.phone };
    console.log('\n📋 DELIVERY:', JSON.stringify(result, null, 2));
    return result;
  } finally {
    if (shouldDestroy) await dataSource.destroy();
  }
}

if (require.main === module) {
  seedTestDelivery().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });
}

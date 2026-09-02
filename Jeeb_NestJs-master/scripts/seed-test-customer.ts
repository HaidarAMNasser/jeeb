import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as bcrypt from 'bcrypt';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

export const TEST_CUSTOMER = {
  email: 'customer-test@jeeb.test',
  phone: '+963991000001',
  firstName: 'Test',
  lastName: 'Customer',
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

export async function seedTestCustomer(ds?: DataSource) {
  const dataSource = ds || getDataSource();
  const shouldDestroy = !ds;
  if (!dataSource.isInitialized) await dataSource.initialize();

  try {
    const hashed = await bcrypt.hash(TEST_CUSTOMER.password, 10);

    let userId: number;
    const existing = await dataSource.query(`SELECT id FROM users WHERE email=$1`, [TEST_CUSTOMER.email]);
    if (existing.length) {
      userId = existing[0].id;
      console.log(`⚠  Customer ${TEST_CUSTOMER.email} already exists id=${userId} — skipped create`);
    } else {
      const rows = await dataSource.query(
        `INSERT INTO users (email, password, "firstName", "lastName", phone, role, "notificationChannel", "isOnline", "isActive", "verifiedAt", address, "countryId", "cityId", "createdAt", "updatedAt")
         VALUES ($1,$2,$3,$4,$5,'CUSTOMER','WHATSAPP',false,true,NOW(),'Damascus, Syria',1,1,NOW(),NOW()) RETURNING id`,
        [TEST_CUSTOMER.email, hashed, TEST_CUSTOMER.firstName, TEST_CUSTOMER.lastName, TEST_CUSTOMER.phone],
      );
      userId = rows[0].id;
      console.log(`✅ Customer created id=${userId} email=${TEST_CUSTOMER.email}`);
    }

    // review for an existing merchant/product — no orders here (linked in seed-test-links)
    const merchantRow = await dataSource.query(`SELECT id FROM users WHERE role='MERCHANT' AND "deletedAt" IS NULL LIMIT 1`);
    let reviewId: number | null = null;
    if (merchantRow.length) {
      const productRow = await dataSource.query(`SELECT id FROM products WHERE "merchantId"=$1 LIMIT 1`, [merchantRow[0].id]);
      const targetId = productRow.length ? productRow[0].id : merchantRow[0].id;
      const entityType = productRow.length ? 'PRODUCT' : 'MERCHANT';
      const existsRev = await dataSource.query(`SELECT id FROM reviews WHERE "reviewerId"=$1 AND "entityType"=$2 AND "entityId"=$3`, [userId, entityType, targetId]);
      if (existsRev.length) {
        reviewId = existsRev[0].id;
        console.log(`⚠  Review already exists id=${reviewId} (${entityType}:${targetId})`);
      } else {
        const r = await dataSource.query(`INSERT INTO reviews (rating, comment, "reviewerId", "entityType", "entityId") VALUES (5,'ممتاز للتجربة',$1,$2,$3) RETURNING id`, [userId, entityType, targetId]);
        reviewId = r[0].id;
        console.log(`✅ Review created id=${reviewId} ${entityType}:${targetId} rating=5`);
      }
    } else {
      console.log('⚠  No merchant found — review skipped');
    }

    const result = { userId, email: TEST_CUSTOMER.email, phone: TEST_CUSTOMER.phone, reviewId };
    console.log('\n📋 CUSTOMER:', JSON.stringify(result, null, 2));
    return result;
  } finally {
    if (shouldDestroy) await dataSource.destroy();
  }
}

if (require.main === module) {
  seedTestCustomer().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });
}

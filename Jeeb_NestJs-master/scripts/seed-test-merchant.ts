import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as bcrypt from 'bcrypt';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

export const TEST_MERCHANT = {
  email: 'merchant-test@jeeb.test',
  phone: '+963991000002',
  firstName: 'Test',
  lastName: 'Merchant',
  password: '123456',
  restaurantName: 'مطعم الاختبار للحذف',
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

export async function seedTestMerchant(ds?: DataSource) {
  const dataSource = ds || getDataSource();
  const shouldDestroy = !ds;
  if (!dataSource.isInitialized) await dataSource.initialize();

  try {
    const hashed = await bcrypt.hash(TEST_MERCHANT.password, 10);

    let userId: number;
    const existing = await dataSource.query(`SELECT id FROM users WHERE email=$1`, [TEST_MERCHANT.email]);
    if (existing.length) {
      userId = existing[0].id;
      console.log(`⚠  Merchant ${TEST_MERCHANT.email} already exists id=${userId}`);
    } else {
      const rows = await dataSource.query(
        `INSERT INTO users (email, password, "firstName", "lastName", phone, role, "notificationChannel", "isOnline", "isActive", "verifiedAt", address, "countryId", "cityId", "createdAt", "updatedAt")
         VALUES ($1,$2,$3,$4,$5,'MERCHANT','WHATSAPP',true,true,NOW(),'Damascus, Syria',1,1,NOW(),NOW()) RETURNING id`,
        [TEST_MERCHANT.email, hashed, TEST_MERCHANT.firstName, TEST_MERCHANT.lastName, TEST_MERCHANT.phone],
      );
      userId = rows[0].id;
      console.log(`✅ Merchant user created id=${userId}`);
      await dataSource.query(`INSERT INTO merchants ("userId","restaurantName","isOpen","type","createdAt","updatedAt") VALUES ($1,$2,true,'RESTAURANT',NOW(),NOW()) ON CONFLICT DO NOTHING`, [userId, TEST_MERCHANT.restaurantName]);
      console.log(`✅ Merchant profile created userId=${userId}`);
    }

    // ensure category
    let categoryId: number;
    const catRows = await dataSource.query(`SELECT id FROM categories LIMIT 1`);
    if (catRows.length) categoryId = catRows[0].id;
    else {
      const c = await dataSource.query(`INSERT INTO categories (name,"isActive","displayOrder","createdAt","updatedAt") VALUES ($1,true,0,NOW(),NOW()) RETURNING id`, [JSON.stringify({ ar: 'اختبار' })]);
      categoryId = c[0].id;
      console.log(`✅ Category created id=${categoryId}`);
    }

    let productId: number;
    const prodRows = await dataSource.query(`SELECT id FROM products WHERE "merchantId"=$1 LIMIT 1`, [userId]);
    if (prodRows.length) {
      productId = prodRows[0].id;
      console.log(`⚠  Product already exists id=${productId}`);
    } else {
      const p = await dataSource.query(
        `INSERT INTO products ("merchantId","categoryId", name, price, "hasStock","stockQuantity","isAvailable","createdAt","updatedAt") VALUES ($1,$2,$3,5000,true,100,true,NOW(),NOW()) RETURNING id`,
        [userId, categoryId, JSON.stringify({ ar: 'منتج اختبار للحذف' })],
      );
      productId = p[0].id;
      console.log(`✅ Product created id=${productId} merchantId=${userId} price=5000`);
    }

    const result = { userId, email: TEST_MERCHANT.email, phone: TEST_MERCHANT.phone, productId, categoryId };
    console.log('\n📋 MERCHANT:', JSON.stringify(result, null, 2));
    return result;
  } finally {
    if (shouldDestroy) await dataSource.destroy();
  }
}

if (require.main === module) {
  seedTestMerchant().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });
}

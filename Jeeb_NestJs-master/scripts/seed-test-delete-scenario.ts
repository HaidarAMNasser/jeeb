import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { seedTestCustomer, TEST_CUSTOMER } from './seed-test-customer';
import { seedTestMerchant, TEST_MERCHANT } from './seed-test-merchant';
import { seedTestDelivery, TEST_DELIVERY } from './seed-test-delivery';
import { seedTestLinks } from './seed-test-links';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

async function main() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: DB_HOST || 'localhost',
    port: Number(DB_PORT) || 5432,
    username: DB_USERNAME || 'postgres',
    password: DB_PASSWORD || 'postgres',
    database: DB_DATABASE || 'delivery_jeeb',
    synchronize: false,
  });
  await dataSource.initialize();
  console.log('DB connected\n=== Seed test delete scenario ===\n');

  const customer = await seedTestCustomer(dataSource);
  const merchant = await seedTestMerchant(dataSource);
  const delivery = await seedTestDelivery(dataSource);
  const links = await seedTestLinks(dataSource);

  const baseUrl = process.env.BASE_URL || 'http://localhost:3001';

  console.log('\n==================== SUMMARY ====================');
  console.log(JSON.stringify({ customer, merchant, delivery, links }, null, 2));
  console.log('\n--- Manual delete tests (replace <JWT>) ---');
  console.log(`# Customer self-delete (hard): curl -X DELETE ${baseUrl}/api/v1/auth/profile -H "Authorization: Bearer <CUSTOMER_JWT>"`);
  console.log(`#   user: ${TEST_CUSTOMER.email} / ${TEST_CUSTOMER.password} id=${customer.userId}`);
  console.log(`# Merchant self-delete:       curl -X DELETE ${baseUrl}/api/v1/auth/profile -H "Authorization: Bearer <MERCHANT_JWT>" # ${TEST_MERCHANT.email} id=${merchant.userId}`);
  console.log(`# Delivery self-delete:       curl -X DELETE ${baseUrl}/api/v1/auth/profile -H "Authorization: Bearer <DELIVERY_JWT>" # ${TEST_DELIVERY.email} id=${delivery.userId}`);
  console.log(`# Admin delete delivery:      curl -X DELETE ${baseUrl}/api/v1/users/deliveries/${delivery.userId} -H "Authorization: Bearer <ADMIN_JWT>"`);
  console.log(`# Admin delete merchant:      curl -X DELETE ${baseUrl}/api/v1/users/merchants/${merchant.userId} -H "Authorization: Bearer <ADMIN_JWT>"`);
  console.log('================================================\n');

  await dataSource.destroy();
}

main().catch((e) => { console.error(e); process.exit(1); });

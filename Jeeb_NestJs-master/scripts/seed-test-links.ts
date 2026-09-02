import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { TEST_CUSTOMER } from './seed-test-customer';
import { TEST_MERCHANT } from './seed-test-merchant';
import { TEST_DELIVERY } from './seed-test-delivery';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

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

export async function seedTestLinks(ds?: DataSource) {
  const dataSource = ds || getDataSource();
  const shouldDestroy = !ds;
  if (!dataSource.isInitialized) await dataSource.initialize();

  try {
    const cust = await dataSource.query(`SELECT id FROM users WHERE email=$1`, [TEST_CUSTOMER.email]);
    const merch = await dataSource.query(`SELECT id FROM users WHERE email=$1`, [TEST_MERCHANT.email]);
    const deliv = await dataSource.query(`SELECT id FROM users WHERE email=$1`, [TEST_DELIVERY.email]);
    if (!cust.length || !merch.length || !deliv.length) throw new Error('Missing test users — run seed-test-* first');

    const customerId = cust[0].id;
    const merchantId = merch[0].id;
    const deliveryId = deliv[0].id;

    const prodRow = await dataSource.query(`SELECT id, price FROM products WHERE "merchantId"=$1 LIMIT 1`, [merchantId]);
    if (!prodRow.length) throw new Error('No product for test merchant');
    const productId = prodRow[0].id;
    const price: number = prodRow[0].price;

    // create 3 orders with different statuses to test delete behavior
    // PENDING + CONFIRMED will be deleted with customer hard-delete, others stay with SET NULL
    const statuses = ['PENDING', 'CONFIRMED', 'COMPLETE'] as const;
    const orderIds: number[] = [];
    for (const status of statuses) {
      const r = await dataSource.query(
        `INSERT INTO orders ("customerId","ownerId","totalAmount","deliveryFee","discountAmount","currencyCode","exchangeRate","paymentMethod",status,"deliveryCoordinates","createdAt","updatedAt")
         VALUES ($1,$2,$3,3000,0,'SYP',1,'CASH',$4,'{"latitude":33.5138,"longitude":36.2765,"address":"Damascus"}',NOW(),NOW()) RETURNING id`,
        [customerId, merchantId, price, status],
      );
      const orderId = r[0].id;
      await dataSource.query(`INSERT INTO order_items ("orderId","productId","productName",quantity,"originalUnitPrice","unitPrice","totalPrice") VALUES ($1,$2,'منتج اختبار للحذف',1,$3,$3,$3)`, [orderId, productId, price]);
      orderIds.push(orderId);
      console.log(`✅ Order id=${orderId} status=${status} customer=${customerId} owner=${merchantId}`);
    }

    // link delivery to COMPLETE order via delivery_assignments (ACCEPTED + order COMPLETE = incomplete per profile.service check)
    const completeOrderId = orderIds[2];
    const existingAssign = await dataSource.query(`SELECT id FROM delivery_assignments WHERE "orderId"=$1 AND "deliveryId"=$2`, [completeOrderId, deliveryId]);
    let assignmentId: number;
    if (existingAssign.length) {
      assignmentId = existingAssign[0].id;
      console.log(`⚠  Assignment already exists id=${assignmentId}`);
    } else {
      const a = await dataSource.query(`INSERT INTO delivery_assignments ("orderId","deliveryId",status) VALUES ($1,$2,'ACCEPTED') RETURNING id`, [completeOrderId, deliveryId]);
      assignmentId = a[0].id;
      console.log(`✅ DeliveryAssignment id=${assignmentId} order=${completeOrderId} delivery=${deliveryId} status=ACCEPTED`);
    }

    // review for order by customer (if not exists)
    const revExists = await dataSource.query(`SELECT id FROM reviews WHERE "reviewerId"=$1 AND "entityType"='ORDER' AND "entityId"=$2`, [customerId, completeOrderId]);
    let reviewId: number | null = null;
    if (revExists.length) {
      reviewId = revExists[0].id;
      console.log(`⚠  Order review already exists id=${reviewId}`);
    } else {
      const rr = await dataSource.query(`INSERT INTO reviews (rating, comment, "reviewerId","entityType","entityId") VALUES (4,'تجربة ربط للاختبار',$1,'ORDER',$2) RETURNING id`, [customerId, completeOrderId]);
      reviewId = rr[0].id;
      console.log(`✅ Order review id=${reviewId} ORDER:${completeOrderId}`);
    }

    const result = { customerId, merchantId, deliveryId, productId, orderIds, assignmentId: assignmentId!, reviewId };
    console.log('\n📋 LINKS:', JSON.stringify(result, null, 2));
    return result;
  } finally {
    if (shouldDestroy) await dataSource.destroy();
  }
}

if (require.main === module) {
  seedTestLinks().then(() => process.exit(0)).catch((e) => { console.error(e); process.exit(1); });
}

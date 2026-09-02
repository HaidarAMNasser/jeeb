import 'reflect-metadata';
import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const args = process.argv.slice(2);
const orderIds = args[0]?.split(',').map((id) => parseInt(id.trim())) || [];
const dryRun = args.includes('--dry-run') || args.includes('-d');

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

  console.log(`\n🗑️  Deleting orders with IDs: [${orderIds.join(', ')}]`);
  console.log(`📋 Dry run mode: ${dryRun ? 'YES' : 'NO'}\n`);

  if (orderIds.length === 0) {
    console.log(
      '❌ No order IDs provided. Usage: ts-node delete-orders-by-ids.ts "40,41,42,43"',
    );
    await dataSource.destroy();
    return;
  }

  try {
    for (const orderId of orderIds) {
      console.log(`\n📦 Processing Order #${orderId}...`);

      // Check if order exists
      const orderCheck = await dataSource.query(
        `SELECT id, status FROM orders WHERE id = ${orderId}`,
      );

      if (orderCheck.length === 0) {
        console.log(`⚠️  Order #${orderId} not found, skipping...`);
        continue;
      }

      const currentStatus = orderCheck[0].status;
      console.log(`   Status: ${currentStatus}`);

      if (dryRun) {
        console.log(
          `   📝 Would delete order #${orderId} and its related data`,
        );
      } else {
        try {
          // Delete order items
          await dataSource.query(
            `DELETE FROM order_items WHERE "orderId" = ${orderId}`,
          );
          console.log(`   ✅ Deleted order_items`);

          // Delete delivery assignments
          await dataSource.query(
            `DELETE FROM delivery_assignments WHERE "orderId" = ${orderId}`,
          );
          console.log(`   ✅ Deleted delivery_assignments`);

          // Delete payment transactions
          await dataSource.query(
            `DELETE FROM payment_transactions WHERE "orderId" = ${orderId}`,
          );
          console.log(`   ✅ Deleted payment_transactions`);

          // Delete invoices
          await dataSource.query(
            `DELETE FROM invoices WHERE "orderId" = ${orderId}`,
          );
          console.log(`   ✅ Deleted invoices`);

          // Delete the order
          await dataSource.query(`DELETE FROM orders WHERE id = ${orderId}`);
          console.log(`   ✅ Deleted order #${orderId}`);
        } catch (error: any) {
          console.error(
            `   ❌ Failed to delete order #${orderId}:`,
            error.message,
          );
        }
      }
    }

    console.log(
      `\n✨ ${dryRun ? 'Would delete' : 'Deleted'} ${orderIds.length} orders`,
    );
  } catch (error: any) {
    console.error('Error:', error.message);
  } finally {
    await dataSource.destroy();
  }
}

main();

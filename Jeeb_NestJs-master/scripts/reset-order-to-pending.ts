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

  console.log(`\n📦 Resetting orders to PENDING: [${orderIds.join(', ')}]`);
  console.log(`📋 Dry run mode: ${dryRun ? 'YES' : 'NO'}\n`);

  if (orderIds.length === 0) {
    console.log(
      '❌ No order IDs provided. Usage: ts-node scripts/reset-order-to-pending.ts "40,41,42,43"',
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
      console.log(`   Current Status: ${currentStatus}`);

      if (dryRun) {
        console.log(`   📝 Would reset order #${orderId} status to PENDING`);
      } else {
        try {
          // Update order status to PENDING
          await dataSource.query(
            `UPDATE orders SET status = 'PENDING', "updatedAt" = NOW() WHERE id = ${orderId}`,
          );
          console.log(`   ✅ Order #${orderId} status reset to PENDING`);

          // Delete delivery assignments for this order
          await dataSource.query(
            `DELETE FROM delivery_assignments WHERE "orderId" = ${orderId}`,
          );
          console.log(
            `   ✅ Deleted delivery_assignments for order #${orderId}`,
          );

          // Delete order items to allow fresh selection
          await dataSource.query(
            `DELETE FROM order_items WHERE "orderId" = ${orderId}`,
          );
          console.log(`   ✅ Deleted order_items for order #${orderId}`);
        } catch (error: any) {
          console.error(
            `   ❌ Failed to reset order #${orderId}:`,
            error.message,
          );
        }
      }
    }

    console.log(
      `\n✨ ${dryRun ? 'Would reset' : 'Reset'} ${orderIds.length} orders to PENDING`,
    );
  } catch (error: any) {
    console.error('Error:', error.message);
  } finally {
    await dataSource.destroy();
  }
}

main();

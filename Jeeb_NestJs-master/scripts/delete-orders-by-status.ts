import 'reflect-metadata';
import { DataSource } from 'typeorm';

const args = process.argv.slice(2);
const status = args[0]?.toUpperCase() || 'SEARCHING';
const dryRun = args.includes('--dry-run') || args.includes('-d');

async function main() {
  const dataSource = new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    username: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || 'postgres',
    database: process.env.DB_DATABASE || 'delivery_jeeb',
    synchronize: false,
  });

  await dataSource.initialize();

  console.log(`\n🗑️  Deleting orders with status: ${status}`);
  console.log(`📋 Dry run mode: ${dryRun ? 'YES' : 'NO'}\n`);

  try {
    const orders = await dataSource.query(
      `SELECT id, status FROM orders WHERE LOWER(status) = LOWER('${status}')`,
    );

    console.log(`Found ${orders.length} orders with status ${status}\n`);

    if (orders.length === 0) {
      console.log('✅ No orders to delete');
      await dataSource.destroy();
      return;
    }

    const orderIds = orders.map((o: any) => o.id);

    if (dryRun) {
      console.log('📝 Orders that would be deleted:');
      orderIds.forEach((id: number) => console.log(`  - Order #${id}`));
    } else {
      for (const orderId of orderIds) {
        try {
          await dataSource.query(
            `DELETE FROM order_items WHERE "orderId" = ${orderId}`,
          );
          await dataSource.query(
            `DELETE FROM delivery_assignments WHERE "orderId" = ${orderId}`,
          );
          await dataSource.query(
            `DELETE FROM payment_transactions WHERE "orderId" = ${orderId}`,
          );
          await dataSource.query(
            `DELETE FROM invoices WHERE "orderId" = ${orderId}`,
          );
          await dataSource.query(`DELETE FROM orders WHERE id = ${orderId}`);
          console.log(`✅ Deleted order #${orderId}`);
        } catch (error: any) {
          console.error(
            `❌ Failed to delete order #${orderId}:`,
            error.message,
          );
        }
      }
    }

    console.log(
      `\n✨ ${dryRun ? 'Would delete' : 'Deleted'} ${orders.length} orders`,
    );
  } catch (error: any) {
    console.error('Error:', error.message);
  } finally {
    await dataSource.destroy();
  }
}

main();

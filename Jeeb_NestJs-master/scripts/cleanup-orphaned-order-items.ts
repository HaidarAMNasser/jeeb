import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

const dataSource = new DataSource({
  type: 'postgres',
  host: DB_HOST || 'localhost',
  port: Number(DB_PORT) || 5432,
  username: DB_USERNAME || 'postgres',
  password: DB_PASSWORD || 'postgres',
  database: DB_DATABASE || 'delivery_jeeb',
  synchronize: false,
});

async function run() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    console.log('🧹 Finding orphaned order_items by productId...');
    const orphanedByProduct = await dataSource.query(`
      SELECT oi.id, oi."productId", oi."productName", oi."orderId"
      FROM order_items oi
      LEFT JOIN products p ON oi."productId" = p.id
      WHERE oi."productId" IS NOT NULL AND p.id IS NULL
    `);
    console.log(
      `Found ${orphanedByProduct.length} orphaned order_items by productId`,
    );

    if (orphanedByProduct.length > 0) {
      const ids = orphanedByProduct.map((item: any) => item.id);
      await dataSource.query(`
        DELETE FROM order_items
        WHERE id IN (${ids.join(',')})
      `);
      console.log(`✅ Deleted ${ids.length} orphaned order_items by productId`);
    }

    console.log('🧹 Finding orphaned order_items by offerId...');
    const orphanedByOffer = await dataSource.query(`
      SELECT oi.id, oi."offerId", oi."productName", oi."orderId"
      FROM order_items oi
      LEFT JOIN offers o ON oi."offerId" = o.id
      WHERE oi."offerId" IS NOT NULL AND o.id IS NULL
    `);
    console.log(
      `Found ${orphanedByOffer.length} orphaned order_items by offerId`,
    );

    if (orphanedByOffer.length > 0) {
      const ids = orphanedByOffer.map((item: any) => item.id);
      await dataSource.query(`
        DELETE FROM order_items
        WHERE id IN (${ids.join(',')})
      `);
      console.log(`✅ Deleted ${ids.length} orphaned order_items by offerId`);
    }

    console.log('✨ Cleanup completed successfully!');
  } catch (error) {
    console.error('❌ Failed to cleanup:', error);
  } finally {
    await dataSource.destroy();
  }
}

run();

import { DataSource } from 'typeorm';

export async function cleanupOrphanedOrderItems(dataSource: DataSource) {
  console.log('🧹 Starting cleanup of orphaned order_items...');

  const orderItemRepo = dataSource.getRepository('order_items');
  const productRepo = dataSource.getRepository('products');
  const offerRepo = dataSource.getRepository('offers');

  // Find orphaned order_items by productId
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
    await orderItemRepo.delete(ids);
    console.log(`✅ Deleted ${ids.length} orphaned order_items by productId`);
  }

  // Find orphaned order_items by offerId
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
    await orderItemRepo.delete(ids);
    console.log(`✅ Deleted ${ids.length} orphaned order_items by offerId`);
  }

  console.log('✨ Cleanup completed!');
}

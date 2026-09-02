const { Client } = require('pg');

async function main() {
  const client = new Client({
    host: 'localhost',
    port: 5432,
    user: 'jeeb_user',
    password: 'StrongPassword123',
    database: 'jeeb_db',
  });

  await client.connect();

  const orders = await client.query(
    "SELECT id FROM orders WHERE status = 'PREPARING'",
  );
  console.log('Found ' + orders.rows.length + ' orders with PREPARING status');

  for (const order of orders.rows) {
    await client.query('DELETE FROM order_items WHERE "orderId" = ' + order.id);
    await client.query(
      'DELETE FROM delivery_assignments WHERE "orderId" = ' + order.id,
    );
    await client.query(
      'DELETE FROM payment_transactions WHERE "orderId" = ' + order.id,
    );
    await client.query('DELETE FROM invoices WHERE "orderId" = ' + order.id);
    await client.query('DELETE FROM orders WHERE id = ' + order.id);
    console.log('Deleted order #' + order.id);
  }

  console.log('Done!');
  await client.end();
}

main().catch(console.error);

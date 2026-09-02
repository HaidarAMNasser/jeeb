import 'reflect-metadata';
import { DataSource } from 'typeorm';

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
  console.log('✅ Connected to database');

  try {
    // Check if title column exists
    const columns = await dataSource.query(
      "SELECT column_name FROM information_schema.columns WHERE table_name = 'notification_logs'",
    );
    const columnNames = columns.map((c: any) => c.column_name);

    if (columnNames.includes('title')) {
      const result = await dataSource.query(
        "UPDATE notification_logs SET title = 'Notification' WHERE title IS NULL RETURNING id",
      );
      console.log(`✅ Updated ${result.length} rows with null title`);
    } else {
      console.log('ℹ️  Column "title" does not exist in database yet');
    }

    if (columnNames.includes('body')) {
      const bodyResult = await dataSource.query(
        "UPDATE notification_logs SET body = '' WHERE body IS NULL RETURNING id",
      );
      console.log(`✅ Updated ${bodyResult.length} rows with null body`);
    } else {
      console.log('ℹ️  Column "body" does not exist in database yet');
    }

    console.log('\n✅ Done!');
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await dataSource.destroy();
  }
}

main();

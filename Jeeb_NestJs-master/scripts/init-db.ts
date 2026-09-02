import { Client } from 'pg';
import * as dotenv from 'dotenv';
import * as path from 'path';

// Load environment variables from .env file
dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

async function createDatabase() {
  if (!DB_DATABASE) {
    console.error('DB_DATABASE environment variable is not defined.');
    process.exit(1);
  }

  const client = new Client({
    host: DB_HOST || 'localhost',
    port: Number(DB_PORT) || 5432,
    user: DB_USERNAME || 'postgres',
    password: DB_PASSWORD || 'postgres',
    database: 'postgres', // Connect to default 'postgres' database to create new one
  });

  try {
    console.log(`Connecting to postgres server at ${DB_HOST}:${DB_PORT}...`);
    await client.connect();

    // Check if database exists
    const checkRes = await client.query(
      `SELECT 1 FROM pg_database WHERE datname = $1`,
      [DB_DATABASE],
    );

    if (checkRes.rowCount === 0) {
      console.log(`Database "${DB_DATABASE}" does not exist. Creating...`);
      // Use double quotes for database name to handle special characters/case sensitivity
      await client.query(`CREATE DATABASE "${DB_DATABASE}"`);
      console.log(`Database "${DB_DATABASE}" created successfully.`);
    } else {
      console.log(
        `Database "${DB_DATABASE}" already exists. Skipping creation.`,
      );
    }
  } catch (err) {
    console.error('Error checking/creating database:', err);
    process.exit(1);
  } finally {
    await client.end();
  }
}

void createDatabase();

import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import * as path from 'path';
import * as admin from 'firebase-admin';

config();

const dataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_DATABASE || 'delivery_jeeb',
  entities: [path.join(__dirname, '../src/database/entities/**/*.entity.ts')],
  logging: true,
});

const projectId = process.env.FIREBASE_PROJECT_ID;
const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
const databaseURL =
  process.env.FIREBASE_DATABASE_URL ||
  'https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/';

async function syncDriversToFirebase() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    console.log('Initializing Firebase...');

    if (!projectId || !privateKey || !clientEmail) {
      console.error(
        '❌ Firebase credentials not found in environment variables.',
      );
      console.error(
        'Please ensure FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL are set.',
      );
      process.exit(1);
    }

    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          privateKey,
          clientEmail,
        }),
        databaseURL,
      });
    }

    const db = admin.database();
    console.log('Firebase initialized.');

    console.log('Fetching delivery driver with ID 57...');
    const drivers = await dataSource
      .createQueryBuilder()
      .select([
        'user.id',
        'user.currentLat',
        'user.currentLng',
        'user.isOnline',
      ])
      .from('users', 'user')
      .where('user.role = :role', { role: 'DELIVERY' })
      .andWhere('user.id = :id', { id: 57 })
      .andWhere('user.isActive = :isActive', { isActive: true })
      .andWhere('user.deletedAt IS NULL')
      .getMany();

    console.log(`Found ${drivers.length} active delivery driver(s).`);

    let created = 0;
    let skipped = 0;
    let errors = 0;

    for (const driver of drivers) {
      try {
        const driverRef = db.ref(`drivers/${driver.id}`);
        const snapshot = await driverRef.once('value');

        if (snapshot.exists()) {
          console.log(
            `⏭️  Driver ${driver.id} already has a document in Firebase. Skipping...`,
          );
          skipped++;
        } else {
          await driverRef.set({
            id: driver.id,
            currentLat: driver.currentLat || null,
            currentLng: driver.currentLng || null,
            isOnline: driver.isOnline || false,
            createdAt: admin.database.ServerValue.TIMESTAMP,
          });
          console.log(`✅ Created Firebase document for driver ${driver.id}`);
          created++;
        }
      } catch (error) {
        console.error(`❌ Error processing driver ${driver.id}:`, error);
        errors++;
      }
    }

    console.log('\n========== Summary ==========');
    console.log(`Total drivers found: ${drivers.length}`);
    console.log(`Documents created: ${created}`);
    console.log(`Documents already exist: ${skipped}`);
    console.log(`Errors: ${errors}`);
    console.log('==============================');

    await dataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

syncDriversToFirebase();

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
  database: process.env.DB_DATABASE || 'jeeb_db',
  entities: [path.join(__dirname, '../src/database/entities/**/*.entity.ts')],
  logging: false,
});

const projectId = process.env.FIREBASE_PROJECT_ID;
const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
const databaseURL =
  process.env.FIREBASE_DATABASE_URL ||
  'https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app/';

function generateRandomLatLng() {
  const lat = 32.5 + Math.random() * 4;
  const lng = 35.5 + Math.random() * 5;
  return { lat: parseFloat(lat.toFixed(6)), lng: parseFloat(lng.toFixed(6)) };
}

async function syncDriverToFirebase(driverId: number) {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    console.log('Initializing Firebase...');

    if (!projectId || !privateKey || !clientEmail) {
      console.error(
        '❌ Firebase credentials not found in environment variables.',
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

    console.log(`Fetching delivery driver with ID ${driverId}...`);
    const driver = await dataSource
      .createQueryBuilder()
      .select([
        'user.id',
        'user.currentLat',
        'user.currentLng',
        'user.isOnline',
      ])
      .from('users', 'user')
      .where('user.role = :role', { role: 'DELIVERY' })
      .andWhere('user.id = :id', { id: driverId })
      .getOne();

    if (!driver) {
      console.error(`❌ Driver with ID ${driverId} not found.`);
      await dataSource.destroy();
      process.exit(1);
    }

    console.log(`Found driver: ID=${driver.id}`);

    let currentLat = driver.currentLat;
    let currentLng = driver.currentLng;

    if (
      currentLat === null ||
      currentLat === undefined ||
      currentLng === null ||
      currentLng === undefined
    ) {
      const randomLocation = generateRandomLatLng();
      currentLat = randomLocation.lat;
      currentLng = randomLocation.lng;
      console.log(
        `⚠️  No location found for driver, generating random: ${currentLat}, ${currentLng}`,
      );

      await dataSource
        .createQueryBuilder()
        .update('users')
        .set({ currentLat, currentLng })
        .where('id = :id', { id: driverId })
        .execute();
      console.log(`✅ Updated driver location in database`);
    }

    try {
      const driverRef = db.ref(`drivers/${driver.id}`);
      const snapshot = await driverRef.once('value');

      if (snapshot.exists()) {
        console.log(
          `⏭️  Driver ${driver.id} already has a document in Firebase. Updating...`,
        );
        await driverRef.update({
          id: driver.id,
          currentLat,
          currentLng,
          isOnline: driver.isOnline || false,
          updatedAt: admin.database.ServerValue.TIMESTAMP,
        });
        console.log(`✅ Updated Firebase document for driver ${driver.id}`);
      } else {
        await driverRef.set({
          id: driver.id,
          currentLat,
          currentLng,
          isOnline: driver.isOnline || false,
          createdAt: admin.database.ServerValue.TIMESTAMP,
        });
        console.log(`✅ Created Firebase document for driver ${driver.id}`);
      }

      console.log('==============================');
      console.log(`Driver ID: ${driver.id}`);
      console.log(`Location: ${currentLat}, ${currentLng}`);
      console.log(`Status: ${driver.isOnline ? 'Online' : 'Offline'}`);
      console.log('==============================');
    } catch (error) {
      console.error(`❌ Error processing driver ${driver.id}:`, error);
    }

    await dataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

const driverId = parseInt(process.argv[2], 10);

if (isNaN(driverId)) {
  console.error('❌ Please provide a valid driver ID.');
  console.log('Usage: npx ts-node sync-driver-to-firebase.ts <driver_id>');
  console.log('Example: npx ts-node sync-driver-to-firebase.ts 57');
  process.exit(1);
}

syncDriverToFirebase(driverId);

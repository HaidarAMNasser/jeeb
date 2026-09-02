import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as path from 'path';
import { LocationTracker } from '../interfaces/location-tracker.interface';

interface FirebaseLocationData {
  lat: number;
  lng: number;
  timestamp?: number;
}

interface FirebaseServiceAccount {
  type: string;
  project_id: string;
  private_key_id: string;
  private_key: string;
  client_email: string;
  client_id: string;
  auth_uri: string;
  token_uri: string;
  auth_provider_x509_cert_url: string;
  client_x509_cert_url: string;
  universe_domain: string;
}

@Injectable()
export class FirebaseLocationStrategy implements LocationTracker {
  private readonly logger = new Logger(FirebaseLocationStrategy.name);
  private db: admin.database.Database;

  constructor(private configService: ConfigService) {
    this.initializeFirebase();
  }

  private initializeFirebase(): void {
    if (!admin.apps.length) {
      try {
        let serviceAccountPath = path.join(
          process.cwd(),
          'src',
          'config',
          'Firebase-service-account.json',
        );

        if (!fs.existsSync(serviceAccountPath)) {
          serviceAccountPath = path.join(
            __dirname,
            '..',
            '..',
            '..',
            '..',
            'config',
            'Firebase-service-account.json',
          );
        }

        if (!fs.existsSync(serviceAccountPath)) {
          serviceAccountPath = path.join(
            process.cwd(),
            'dist',
            'src',
            'config',
            'Firebase-service-account.json',
          );
        }

        if (!fs.existsSync(serviceAccountPath)) {
          serviceAccountPath =
            '/root/var/www/src_v1/Jeeb_NestJs/src/config/Firebase-service-account.json';
        }

        if (!fs.existsSync(serviceAccountPath)) {
          serviceAccountPath = path.join(
            __dirname,
            '..',
            '..',
            '..',
            '..',
            '..',
            'config',
            'Firebase-service-account.json',
          );
        }

        this.logger.debug(
          `Trying Firebase service account path: ${serviceAccountPath}`,
        );
        this.logger.debug(`File exists: ${fs.existsSync(serviceAccountPath)}`);

        let serviceAccount: FirebaseServiceAccount | null = null;
        let databaseURL: string | undefined;

        if (fs.existsSync(serviceAccountPath)) {
          try {
            const fileContent = fs.readFileSync(serviceAccountPath, 'utf8');
            serviceAccount = JSON.parse(fileContent);
            databaseURL = this.configService.get<string>(
              'FIREBASE_DATABASE_URL',
            );
            this.logger.log('Firebase service account loaded from file');
          } catch (parseError) {
            this.logger.error(
              'Failed to parse Firebase service account file',
              parseError,
            );
          }
        } else {
          this.logger.warn(
            `Firebase service account file not found. Tried paths: ${serviceAccountPath}`,
          );
        }

        if (serviceAccount) {
          const formattedPrivateKey = serviceAccount.private_key.replace(
            /\\n/g,
            '\n',
          );

          admin.initializeApp({
            credential: admin.credential.cert({
              projectId: serviceAccount.project_id,
              privateKey: formattedPrivateKey,
              clientEmail: serviceAccount.client_email,
            }),
            databaseURL,
          });
          this.logger.log(
            'Firebase Admin initialized with Service Account File',
          );
        } else {
          const projectId = this.configService.get<string>(
            'FIREBASE_PROJECT_ID',
          );
          const privateKey = this.configService
            .get<string>('FIREBASE_PRIVATE_KEY')
            ?.replace(/\\n/g, '\n');
          const clientEmail = this.configService.get<string>(
            'FIREBASE_CLIENT_EMAIL',
          );
          databaseURL = this.configService.get<string>('FIREBASE_DATABASE_URL');

          const isValidPrivateKey = privateKey?.includes(
            '-----BEGIN PRIVATE KEY-----',
          );

          if (projectId && privateKey && isValidPrivateKey && clientEmail) {
            admin.initializeApp({
              credential: admin.credential.cert({
                projectId,
                privateKey,
                clientEmail,
              }),
              databaseURL,
            });
            this.logger.log(
              'Firebase Admin initialized with Environment Variables',
            );
          } else {
            this.logger.warn(
              'Missing Firebase credentials. Tried: 1) Service Account File, 2) Environment Variables. Skipping Firebase init.',
            );
          }
        }
      } catch (error) {
        this.logger.error('Failed to initialize Firebase Admin', error);
      }
    }

    try {
      this.db = admin.database();
    } catch {
      this.logger.warn('Firebase Database not available (check configuration)');
    }
  }

  async updateLocation(
    driverId: number,
    lat: number,
    lng: number,
  ): Promise<void> {
    if (!this.db) {
      this.logger.warn(
        `Firebase DB not ready. Skipping update for driver ${driverId}`,
      );
      return;
    }

    try {
      const ref = this.db.ref(`drivers/${driverId}/location`);
      await ref.set({
        lat,
        lng,
        timestamp: admin.database.ServerValue.TIMESTAMP,
      });
      this.logger.debug(`Updated location for driver ${driverId} on Firebase`);
    } catch (error) {
      this.logger.error(
        `Failed to update location on Firebase for driver ${driverId}`,
        error,
      );
      throw error;
    }
  }

  async getDriverLocation(
    driverId: number,
  ): Promise<{ lat: number; lng: number } | null> {
    if (!this.db) return null;

    try {
      const ref = this.db.ref(`drivers/${driverId}/location`);
      const snapshot = await ref.once('value');
      const data = snapshot.val() as unknown;

      if (!this.isValidLocationData(data)) return null;

      return { lat: data.lat, lng: data.lng };
    } catch (error) {
      this.logger.error(
        `Failed to get location from Firebase for driver ${driverId}`,
        error,
      );
      return null;
    }
  }

  private isValidLocationData(data: unknown): data is FirebaseLocationData {
    if (!data || typeof data !== 'object') {
      return false;
    }

    const castedData = data as Record<string, unknown>;

    return (
      'lat' in castedData &&
      typeof castedData.lat === 'number' &&
      'lng' in castedData &&
      typeof castedData.lng === 'number'
    );
  }
}

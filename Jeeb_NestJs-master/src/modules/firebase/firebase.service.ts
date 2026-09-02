import {
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  Logger,
  OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as fs from 'fs';
import { UserRole } from '../../common/enums/user-role.enum';

const envPath = path.join(process.cwd(), '.env');
dotenv.config({ path: envPath, override: true });

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private db: admin.database.Database;
  private initialized = false;

  getDatabase(): admin.database.Database {
    return this.db;
  }

  constructor(private readonly configService: ConfigService) {}

  onModuleInit() {
    this.initializeFirebase();
  }

  private initializeFirebase(): void {
    if (admin.apps.length) {
      try {
        this.db = admin.database();
        this.initialized = true;
        this.logger.log(
          'Firebase Admin already initialized. Database reference linked.',
        );
        return;
      } catch (error) {
        this.logger.error(
          'Failed to get database reference from existing Firebase app',
          error,
        );
      }
    }

    try {
      const projectId = process.env.FIREBASE_PROJECT_ID;
      const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(
        /\\n/g,
        '\n',
      );
      const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
      const databaseURL = process.env.FIREBASE_DATABASE_URL;

      if (projectId && privateKey && clientEmail && databaseURL) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            privateKey,
            clientEmail,
          }),
          databaseURL,
        });
        this.db = admin.database();
        this.initialized = true;
        this.logger.log(
          'Firebase Admin initialized successfully with credentials.',
        );
      } else {
        this.logger.warn(
          'Firebase credentials missing. RTDB features will be disabled.',
        );
      }
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin', error);
    }
  }

  buildDeliveryFirebaseUid(userId: number): string {
    return `delivery_${userId}`;
  }

  async createCustomTokenForDelivery(user: {
    id: number;
    role?: UserRole;
  }): Promise<{ uid: string; customToken: string }> {
    if (user.role !== UserRole.DELIVERY) {
      throw new ForbiddenException(
        'Custom token is available for DELIVERY role only',
      );
    }

    if (!this.initialized || !admin.apps.length) {
      throw new InternalServerErrorException(
        'Firebase auth service is not initialized',
      );
    }

    const uid = this.buildDeliveryFirebaseUid(user.id);
    const customToken = await admin.auth().createCustomToken(uid, {
      role: UserRole.DELIVERY,
      deliveryId: user.id,
    });

    return { uid, customToken };
  }

  async upsertOrder(orderId: number, data: any): Promise<void> {
    if (!this.initialized) return;
    try {
      await this.db.ref(`orders/${orderId}`).update({
        id: orderId,
        ...data,
      });
      this.logger.debug(`RTDB: Upserted order ${orderId}`);
    } catch (error) {
      this.logger.error(`RTDB: Failed to upsert order ${orderId}`, error);
    }
  }

  async createOrderDocument(order: any): Promise<void> {
    if (!this.initialized) return;
    try {
      const restaurantLocation = order.owner?.location
        ? {
            lat: order.owner.location.lat,
            lng: order.owner.location.lng,
          }
        : null;

      const initialRouteHistory: any[] = [];

      const documentData = {
        id: order.id,
        orderId: order.id,
        status: order.status,
        customerId: order.customerId,
        ownerId: order.ownerId,
        deliveryId: order.deliveryAssignment?.deliveryId || null,
        deliveryUid: order.deliveryAssignment?.deliveryId
          ? this.buildDeliveryFirebaseUid(order.deliveryAssignment.deliveryId)
          : null,
        restaurantLocation,
        customerLocation: order.deliveryCoordinates
          ? {
              lat: order.deliveryCoordinates.latitude,
              lng: order.deliveryCoordinates.longitude,
            }
          : null,
        routeHistory: initialRouteHistory,
        speed: 0,
        createdAt: admin.database.ServerValue.TIMESTAMP,
        updatedAt: admin.database.ServerValue.TIMESTAMP,
      };

      await this.db.ref(`orders/${order.id}`).set(documentData);
      this.logger.log(`RTDB: Created order document ${order.id}`);
    } catch (error) {
      this.logger.error(`RTDB: Failed to create order ${order.id}`, error);
    }
  }

  async updateOrderDocument(orderId: number, status: string): Promise<void> {
    if (!this.initialized) return;
    try {
      await this.db.ref(`orders/${orderId}`).update({
        status: status,
        updatedAt: admin.database.ServerValue.TIMESTAMP,
      });
      this.logger.log(`RTDB: Updated order ${orderId} status to ${status}`);
    } catch (error) {
      this.logger.error(`RTDB: Failed to update order ${orderId}`, error);
    }
  }

  async removeOrder(orderId: number): Promise<void> {
    if (!this.initialized) return;
    try {
      await this.db.ref(`orders/${orderId}`).remove();
      this.logger.debug(`RTDB: Removed order ${orderId}`);
    } catch (error) {
      this.logger.error(`RTDB: Failed to remove order ${orderId}`, error);
    }
  }

  async deleteOrderDocument(orderId: number): Promise<void> {
    if (!this.initialized) return;
    try {
      await this.db.ref(`orders/${orderId}`).remove();
      this.logger.log(`RTDB: Deleted order document ${orderId}`);
    } catch (error) {
      this.logger.error(`RTDB: Failed to delete order ${orderId}`, error);
    }
  }

  async orderDocumentExists(orderId: number): Promise<boolean> {
    if (!this.initialized) return false;
    try {
      const snapshot = await this.db.ref(`orders/${orderId}`).once('value');
      return snapshot.exists();
    } catch (error) {
      this.logger.error(
        `RTDB: Failed to check order ${orderId} existence`,
        error,
      );
      return false;
    }
  }

  async updateOrderDriverLocation(
    orderId: number,
    location: { lat: number; lng: number; timestamp: number },
    speed: number,
  ): Promise<void> {
    if (!this.initialized) return;
    try {
      const orderRef = this.db.ref(`orders/${orderId}`);

      const snapshot = await orderRef.child('routeHistory').once('value');
      const currentHistory: any[] = snapshot.val() || [];

      const newPoint = {
        lat: location.lat,
        lng: location.lng,
        timestamp: location.timestamp,
      };
      const updatedHistory = [...currentHistory, newPoint];

      await orderRef.update({
        routeHistory: updatedHistory,
        speed: speed,
        updatedAt: admin.database.ServerValue.TIMESTAMP,
      });

      this.logger.log(`RTDB: Updated driver location for order ${orderId}`);
    } catch (error) {
      this.logger.error(
        `RTDB: Failed to update driver location for order ${orderId}`,
        error,
      );
    }
  }

  async setDeliveryId(orderId: number, deliveryId: number): Promise<void> {
    if (!this.initialized) return;
    try {
      await this.db.ref(`orders/${orderId}`).update({
        deliveryId: deliveryId,
        deliveryUid: this.buildDeliveryFirebaseUid(deliveryId),
        updatedAt: admin.database.ServerValue.TIMESTAMP,
      });
      this.logger.log(
        `RTDB: Set deliveryId ${deliveryId} for order ${orderId}`,
      );
    } catch (error) {
      this.logger.error(
        `RTDB: Failed to set deliveryId for order ${orderId}`,
        error,
      );
    }
  }

  async upsertDriver(driverId: number, data: any): Promise<void> {
    if (!this.initialized) return;
    try {
      await this.db.ref(`drivers/${driverId}`).update({
        id: driverId,
        ...data,
      });
      this.logger.debug(`RTDB: Upserted driver ${driverId}`);
    } catch (error) {
      this.logger.error(`RTDB: Failed to upsert driver ${driverId}`, error);
    }
  }

  async createDriverDocument(driver: any): Promise<void> {
    if (!this.initialized) return;
    try {
      await this.db.ref(`drivers/${driver.id}`).set({
        id: driver.id,
        currentLat: driver.currentLat || null,
        currentLng: driver.currentLng || null,
        isOnline: driver.isOnline || false,
        createdAt: admin.database.ServerValue.TIMESTAMP,
      });
      this.logger.log(`RTDB: Created driver document ${driver.id}`);
    } catch (error) {
      this.logger.error(`RTDB: Failed to create driver ${driver.id}`, error);
    }
  }

  async deleteDriverDocument(driverId: number): Promise<void> {
    if (!this.initialized) return;
    try {
      await this.db.ref(`drivers/${driverId}`).remove();
      this.logger.log(`RTDB: Deleted driver document ${driverId}`);
    } catch (error) {
      this.logger.error(`RTDB: Failed to delete driver ${driverId}`, error);
    }
  }

  async updateDriverLocation(
    driverId: number,
    lat: number,
    lng: number,
  ): Promise<void> {
    if (!this.initialized) return;
    try {
      await this.db.ref(`drivers/${driverId}`).update({
        currentLat: lat,
        currentLng: lng,
      });
      this.logger.debug(`RTDB: Updated location for driver ${driverId}`);
    } catch (error) {
      this.logger.error(
        `RTDB: Failed to update location for driver ${driverId} in RTDB`,
        error,
      );
    }
  }

  async updateDriverOnlineStatus(
    driverId: number,
    onLine: boolean,
  ): Promise<void> {
    if (!this.initialized) return;
    try {
      await this.db.ref(`drivers/${driverId}`).update({ onLine });
      this.logger.debug(
        `RTDB: Updated online status for driver ${driverId} to ${onLine}`,
      );
    } catch (error) {
      this.logger.error(
        `RTDB: Failed to update online status for driver ${driverId} in RTDB`,
        error,
      );
    }
  }

  async getAllDriverLocations(): Promise<
    Map<
      number,
      {
        currentLat: number;
        currentLng: number;
        isOnline: boolean;
      }
    >
  > {
    const driversMap = new Map<
      number,
      {
        currentLat: number;
        currentLng: number;
        isOnline: boolean;
      }
    >();

    if (!this.initialized) {
      this.logger.warn('Firebase not initialized, returning empty map');
      return driversMap;
    }

    try {
      const snapshot = await this.db.ref('drivers').get();

      if (snapshot.exists()) {
        snapshot.forEach((child) => {
          const driverId = Number(child.key);
          const data = child.val();

          if (data.currentLat && data.currentLng) {
            driversMap.set(driverId, {
              currentLat: data.currentLat,
              currentLng: data.currentLng,
              isOnline: data.isOnline === true,
            });
          }
        });
      }

      this.logger.debug(`RTDB: Fetched ${driversMap.size} driver locations`);
    } catch (error) {
      this.logger.error('RTDB: Failed to fetch driver locations', error);
    }

    return driversMap;
  }

  /**
   * Verify a Firebase ID token and return its decoded payload.
   * Used for Firebase Anonymous Authentication mapping.
   */
  async verifyIdToken(token: string): Promise<admin.auth.DecodedIdToken> {
    if (!this.initialized) {
      throw new InternalServerErrorException(
        'Firebase Admin is not initialized',
      );
    }
    try {
      return await admin.auth().verifyIdToken(token);
    } catch (error) {
      this.logger.error('Failed to verify Firebase ID token', error);
      throw new ForbiddenException('Invalid Firebase Token');
    }
  }
}

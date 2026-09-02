import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { FirebaseService } from '../../firebase/firebase.service';
import { DriverPresenceData } from '../interfaces/driver-presence.interface';
import { IDriverPresenceProvider } from '../interfaces/presence-provider.interface';
import { DriverPresenceSyncService } from './driver-presence-sync.service';
import { isPresenceStale } from '../constants/presence.constants';

@Injectable()
export class DriverPresenceListenerService
  implements IDriverPresenceProvider, OnModuleDestroy
{
  private readonly logger = new Logger(DriverPresenceListenerService.name);
  private readonly cache = new Map<number, DriverPresenceData>();
  private driversRef: any = null;
  private started = false;
  private staleTimerHandle: ReturnType<typeof setInterval> | null = null;
  private readonly staleCheckIntervalMs = 15_000;

  constructor(
    private readonly firebaseService: FirebaseService,
    private readonly syncService: DriverPresenceSyncService,
  ) {}

  onModuleDestroy() {
    if (this.driversRef && this.started) {
      this.driversRef.off();
    }
    if (this.staleTimerHandle) {
      clearInterval(this.staleTimerHandle);
      this.staleTimerHandle = null;
    }
    this.logger.log('RTDB listeners and stale timer removed');
  }

  startListening(): void {
    if (this.started) return;
    this.started = true;

    if (!this.driversRef) {
      const db = this.firebaseService.getDatabase();
      if (!db) {
        this.logger.warn('Firebase RTDB not available — listener not started');
        return;
      }
      this.driversRef = db.ref('drivers');
    }

    this.driversRef.on('child_added', (snapshot: any) => {
      this.updateCache(snapshot);
    });

    this.driversRef.on('child_changed', (snapshot: any) => {
      this.updateCache(snapshot);
    });

    this.driversRef.on('child_removed', (snapshot: any) => {
      const driverId = Number(snapshot.key);
      this.cache.delete(driverId);
    });

    this.staleTimerHandle = setInterval(() => this.checkStaleDrivers(), this.staleCheckIntervalMs);

    this.logger.log('RTDB driver presence listeners registered');
  }

  private checkStaleDrivers(): void {
    for (const [id, data] of this.cache) {
      if (data.isOnline && isPresenceStale(data.lastSeen)) {
        data.isOnline = false;
        this.syncService.enqueue(id, false);
      }
    }
  }

  private updateCache(snapshot: any): void {
    const driverId = Number(snapshot.key);
    const data = snapshot.val();
    if (!data || !driverId) return;

    if (!data.currentLat || !data.currentLng) return;

    const isOnline = data.isOnline === true;
    const lastSeen = data.lastSeen || Date.now();

    this.cache.set(driverId, {
      id: driverId,
      currentLat: data.currentLat,
      currentLng: data.currentLng,
      isOnline,
      lastSeen,
    });

    this.syncService.enqueue(driverId, isOnline);
  }

  getTrulyOnlineDrivers(): DriverPresenceData[] {
    const result: DriverPresenceData[] = [];
    for (const driver of this.cache.values()) {
      if (driver.isOnline && !isPresenceStale(driver.lastSeen)) {
        result.push(driver);
      }
    }
    return result;
  }

  isDriverOnline(driverId: number): boolean {
    const driver = this.cache.get(driverId);
    if (!driver) return false;
    return driver.isOnline && !isPresenceStale(driver.lastSeen);
  }

  getCacheSize(): number {
    return this.cache.size;
  }

  getRawCache(): Map<number, DriverPresenceData> {
    return this.cache;
  }
}

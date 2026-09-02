import { Injectable, Logger } from '@nestjs/common';
import { FirebaseService } from '../../firebase/firebase.service';
import { DriverPresenceData } from '../interfaces/driver-presence.interface';
import { isPresenceStale } from '../constants/presence.constants';

@Injectable()
export class DriverPresenceReconciliationService {
  private readonly logger = new Logger(DriverPresenceReconciliationService.name);

  constructor(private readonly firebaseService: FirebaseService) {}

  async runReconciliation(): Promise<{
    cache: Map<number, DriverPresenceData>;
    syncUpdates: Map<number, boolean>;
  }> {
    const cache = new Map<number, DriverPresenceData>();
    const syncUpdates = new Map<number, boolean>();

    const db = this.firebaseService.getDatabase();
    if (!db) {
      this.logger.warn('Firebase RTDB not available — skipping reconciliation');
      return { cache, syncUpdates };
    }

    try {
      const snapshot = await db.ref('drivers').get();

      if (!snapshot.exists()) {
        this.logger.log('No drivers found in RTDB during reconciliation');
        return { cache, syncUpdates };
      }

      snapshot.forEach((child: any) => {
        const driverId = Number(child.key);
        const data = child.val();

        if (!data || !data.currentLat || !data.currentLng) {
          syncUpdates.set(driverId, false);
          return;
        }

        const isOnline = data.isOnline === true;
        const lastSeen = data.lastSeen || Date.now();
        const actuallyOnline = isOnline && !isPresenceStale(lastSeen);

        cache.set(driverId, {
          id: driverId,
          currentLat: data.currentLat,
          currentLng: data.currentLng,
          isOnline: actuallyOnline,
          lastSeen,
        });

        if (isOnline !== actuallyOnline) {
          syncUpdates.set(driverId, false);
        } else {
          syncUpdates.set(driverId, isOnline);
        }
      });

      this.logger.log(
        `Reconciliation complete: ${cache.size} drivers in cache, ${syncUpdates.size} pending sync`,
      );
    } catch (error) {
      this.logger.error(
        `Reconciliation failed: ${error.message}`,
      );
    }

    return { cache, syncUpdates };
  }
}

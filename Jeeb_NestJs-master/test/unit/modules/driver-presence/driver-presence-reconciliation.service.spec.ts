import { Test, TestingModule } from '@nestjs/testing';
import { DriverPresenceReconciliationService } from '../../../../src/modules/driver-presence/services/driver-presence-reconciliation.service';
import { FirebaseService } from '../../../../src/modules/firebase/firebase.service';

describe('DriverPresenceReconciliationService', () => {
  let service: DriverPresenceReconciliationService;

  const makeSnapshot = (data: Record<string, any> | null) => ({
    exists: () => data !== null,
    forEach: (fn: any) => {
      if (!data) return;
      Object.entries(data).forEach(([key, val]) =>
        fn({ key, val: () => val }),
      );
    },
  });

  it('يعيد cache + syncUpdates فارغين إذا RTDB ل空的', async () => {
    const mockDb = { ref: jest.fn().mockReturnThis(), get: jest.fn().mockResolvedValue(makeSnapshot(null)) };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DriverPresenceReconciliationService,
        { provide: FirebaseService, useValue: { getDatabase: jest.fn().mockReturnValue(mockDb) } },
      ],
    }).compile();

    service = module.get(DriverPresenceReconciliationService);
    const result = await service.runReconciliation();
    expect(result.cache.size).toBe(0);
    expect(result.syncUpdates.size).toBe(0);
  });

  it('يعتبر driver online فقط إذا isOnline=true و lastSeen حديث', async () => {
    const data = {
      5: { currentLat: 33.5, currentLng: 36.3, isOnline: true, lastSeen: Date.now() },
      6: { currentLat: 34.5, currentLng: 37.3, isOnline: true, lastSeen: Date.now() - 60_000 },
      7: { currentLat: 35.5, currentLng: 38.3, isOnline: false, lastSeen: Date.now() },
    };
    const mockDb = { ref: jest.fn().mockReturnThis(), get: jest.fn().mockResolvedValue(makeSnapshot(data)) };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DriverPresenceReconciliationService,
        { provide: FirebaseService, useValue: { getDatabase: jest.fn().mockReturnValue(mockDb) } },
      ],
    }).compile();

    service = module.get(DriverPresenceReconciliationService);
    const result = await service.runReconciliation();

    // 5: online + fresh → online
    expect(result.cache.get(5)?.isOnline).toBe(true);
    expect(result.syncUpdates.get(5)).toBe(true);

    // 6: online but stale → should be false in sync
    expect(result.cache.get(6)?.isOnline).toBe(false);
    expect(result.syncUpdates.get(6)).toBe(false);

    // 7: offline → offline
    expect(result.cache.get(7)?.isOnline).toBe(false);
    expect(result.syncUpdates.get(7)).toBe(false);
  });

  it('يستبعد drivers بدون بيانات موقع', async () => {
    const data = {
      5: { isOnline: true, lastSeen: Date.now() },
    };
    const mockDb = { ref: jest.fn().mockReturnThis(), get: jest.fn().mockResolvedValue(makeSnapshot(data)) };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DriverPresenceReconciliationService,
        { provide: FirebaseService, useValue: { getDatabase: jest.fn().mockReturnValue(mockDb) } },
      ],
    }).compile();

    service = module.get(DriverPresenceReconciliationService);
    const result = await service.runReconciliation();

    expect(result.cache.has(5)).toBe(false);
    expect(result.syncUpdates.get(5)).toBe(false);
  });
});

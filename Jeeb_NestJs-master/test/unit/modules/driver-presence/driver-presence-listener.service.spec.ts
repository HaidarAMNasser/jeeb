import { Test, TestingModule } from '@nestjs/testing';
import { DriverPresenceListenerService } from '../../../../src/modules/driver-presence/services/driver-presence-listener.service';
import { DriverPresenceSyncService } from '../../../../src/modules/driver-presence/services/driver-presence-sync.service';
import { FirebaseService } from '../../../../src/modules/firebase/firebase.service';

describe('DriverPresenceListenerService', () => {
  let service: DriverPresenceListenerService;
  let mockDb: any;
  let mockRef: any;
  let mockSyncService: any;

  beforeEach(async () => {
    mockRef = { on: jest.fn(), off: jest.fn() };
    mockDb = { ref: jest.fn().mockReturnValue(mockRef) };
    mockSyncService = { enqueue: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DriverPresenceListenerService,
        {
          provide: FirebaseService,
          useValue: { getDatabase: jest.fn().mockReturnValue(mockDb) },
        },
        {
          provide: DriverPresenceSyncService,
          useValue: mockSyncService,
        },
      ],
    }).compile();

    service = module.get<DriverPresenceListenerService>(
      DriverPresenceListenerService,
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
    jest.useRealTimers();
  });

  it('يسجل listeners عند استدعاء startListening', () => {
    service.startListening();
    expect(mockRef.on).toHaveBeenCalledWith('child_added', expect.any(Function));
    expect(mockRef.on).toHaveBeenCalledWith('child_changed', expect.any(Function));
    expect(mockRef.on).toHaveBeenCalledWith('child_removed', expect.any(Function));
  });

  it('لا يسجل listeners مرتين', () => {
    service.startListening();
    service.startListening();
    expect(mockRef.on).toHaveBeenCalledTimes(3);
  });

  it('يزيل listeners عند onModuleDestroy', () => {
    service.startListening();
    service.onModuleDestroy();
    expect(mockRef.off).toHaveBeenCalled();
  });

  it('يضيف driver للكاش عند child_added مع بيانات كاملة', () => {
    service.startListening();
    const addHandler = mockRef.on.mock.calls.find(
      (c: any[]) => c[0] === 'child_added',
    )[1];
    addHandler({
      key: '5',
      val: () => ({
        currentLat: 33.5,
        currentLng: 36.3,
        isOnline: true,
        lastSeen: Date.now(),
      }),
    });
    expect(service.isDriverOnline(5)).toBe(true);
  });

  it('لا يضيف driver للكاش إذا كانت بيانات الموقع ناقصة', () => {
    service.startListening();
    const addHandler = mockRef.on.mock.calls.find(
      (c: any[]) => c[0] === 'child_added',
    )[1];
    addHandler({
      key: '5',
      val: () => ({ isOnline: true }),
    });
    expect(service.isDriverOnline(5)).toBe(false);
  });

  it('يزيل driver من الكاش عند child_removed', () => {
    service.startListening();
    const addHandler = mockRef.on.mock.calls.find(
      (c: any[]) => c[0] === 'child_added',
    )[1];
    addHandler({
      key: '5',
      val: () => ({
        currentLat: 33.5,
        currentLng: 36.3,
        isOnline: true,
        lastSeen: Date.now(),
      }),
    });
    expect(service.isDriverOnline(5)).toBe(true);

    const removeHandler = mockRef.on.mock.calls.find(
      (c: any[]) => c[0] === 'child_removed',
    )[1];
    removeHandler({ key: '5' });
    expect(service.isDriverOnline(5)).toBe(false);
  });

  it('يعتبر driver قديماً (stale) إذا lastSeen تجاوز threshold', () => {
    service.startListening();
    const addHandler = mockRef.on.mock.calls.find(
      (c: any[]) => c[0] === 'child_added',
    )[1];
    addHandler({
      key: '5',
      val: () => ({
        currentLat: 33.5,
        currentLng: 36.3,
        isOnline: true,
        lastSeen: Date.now() - 60_000,
      }),
    });
    expect(service.isDriverOnline(5)).toBe(false);
  });

  it('يُعلم syncService عن السائقين stale كل 15 ثانية', () => {
    jest.useFakeTimers();
    service.startListening();
    const addHandler = mockRef.on.mock.calls.find(
      (c: any[]) => c[0] === 'child_added',
    )[1];
    addHandler({
      key: '5',
      val: () => ({
        currentLat: 33.5,
        currentLng: 36.3,
        isOnline: true,
        lastSeen: Date.now() - 60_000,
      }),
    });
    addHandler({
      key: '6',
      val: () => ({
        currentLat: 34.5,
        currentLng: 37.3,
        isOnline: true,
        lastSeen: Date.now(),
      }),
    });
    jest.advanceTimersByTime(15_000);
    expect(mockSyncService.enqueue).toHaveBeenCalledWith(5, false);
    expect(mockSyncService.enqueue).not.toHaveBeenCalledWith(6, false);
    jest.useRealTimers();
  });

  it('getTrulyOnlineDrivers يعيد فقط drivers النشيطين', () => {
    service.startListening();
    const addHandler = mockRef.on.mock.calls.find(
      (c: any[]) => c[0] === 'child_added',
    )[1];
    addHandler({
      key: '5',
      val: () => ({
        currentLat: 33.5,
        currentLng: 36.3,
        isOnline: true,
        lastSeen: Date.now(),
      }),
    });
    addHandler({
      key: '6',
      val: () => ({
        currentLat: 34.5,
        currentLng: 37.3,
        isOnline: false,
        lastSeen: Date.now(),
      }),
    });
    const online = service.getTrulyOnlineDrivers();
    expect(online.length).toBe(1);
    expect(online[0].id).toBe(5);
  });
});

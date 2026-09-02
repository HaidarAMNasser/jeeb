import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import { DriverPresenceSyncService } from '../../../../src/modules/driver-presence/services/driver-presence-sync.service';
import { User } from '../../../../src/database/entities/user.entity';

describe('DriverPresenceSyncService', () => {
  let service: DriverPresenceSyncService;
  let userRepo: jest.Mocked<any>;
  let configService: jest.Mocked<ConfigService>;

  beforeEach(async () => {
    userRepo = { update: jest.fn().mockResolvedValue(undefined) };
    configService = { get: jest.fn().mockReturnValue(50) } as any;

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DriverPresenceSyncService,
        { provide: getRepositoryToken(User), useValue: userRepo },
        { provide: ConfigService, useValue: configService },
      ],
    }).compile();

    service = module.get<DriverPresenceSyncService>(
      DriverPresenceSyncService,
    );
  });

  afterEach(() => {
    jest.clearAllMocks();
    service.stop();
  });

  it('يجمع ويطبق تحديث isOnline للـ queue بعد flush', async () => {
    service.enqueue(5, true);
    service.enqueue(10, false);

    await (service as any).flush();

    expect(userRepo.update).toHaveBeenCalledWith(5, { isOnline: true });
    expect(userRepo.update).toHaveBeenCalledWith(10, { isOnline: false });
    expect(userRepo.update).toHaveBeenCalledTimes(2);
  });

  it('يفرغ الـ queue بعد flush ناجح', async () => {
    service.enqueue(5, true);
    await (service as any).flush();
    expect(service.getQueueSize()).toBe(0);
  });

  it('يعيد الفاشلين للـ queue عند فشل الكتابة', async () => {
    userRepo.update.mockRejectedValue(new Error('DB error'));

    service.enqueue(5, true);
    await (service as any).flush();

    expect(service.getQueueSize()).toBe(1);
  });

  it('ينفذ تحديث لعمود isOnline فقط', async () => {
    service.enqueue(5, true);
    await (service as any).flush();

    expect(userRepo.update).toHaveBeenCalledWith(
      5,
      expect.objectContaining({ isOnline: true }),
    );
  });

  it('لا ينفذ أي عملية عندما تكون الـ queue فارغة', async () => {
    await (service as any).flush();
    expect(userRepo.update).not.toHaveBeenCalled();
  });

  it('يجمّع عدة تحديثات لنفس الديلفري بقيمة واحدة (آخر قيمة تفوز)', () => {
    service.enqueue(5, true);
    service.enqueue(5, false);
    service.enqueue(5, true);
    expect(service.getQueueSize()).toBe(1);
  });

  it('يعطل الـ sync إذا كان عمود is_online غير موجود بالـ DB', async () => {
    userRepo.update.mockRejectedValue(
      new Error('column "is_online" does not exist'),
    );

    service.enqueue(5, true);
    await (service as any).flush();

    expect((service as any).disabled).toBe(true);
    service.enqueue(6, true);
    expect(service.getQueueSize()).toBe(0);
  });

  it('يقسم الـ updates إلى chunks عند العدد الكبير', async () => {
    for (let i = 0; i < 25; i++) {
      service.enqueue(i, true);
    }
    await (service as any).flush();

    expect(userRepo.update).toHaveBeenCalledTimes(25);
  });
});

import { Test, TestingModule } from '@nestjs/testing';
import { OtpAttemptService } from '../../../../src/common/services/otp-attempt.service';
import { REDIS_CLIENT } from '../../../../src/common/redis/redis.constants';

describe('OtpAttemptService', () => {
  let service: OtpAttemptService;
  let redis: jest.Mocked<any>;

  const identifier = '+963900000001';

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OtpAttemptService,
        {
          provide: REDIS_CLIENT,
          useValue: {
            incr: jest.fn(),
            expire: jest.fn(),
            setex: jest.fn(),
            del: jest.fn(),
            get: jest.fn(),
            ttl: jest.fn(),
            exists: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<OtpAttemptService>(OtpAttemptService);
    redis = module.get(REDIS_CLIENT);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('recordFailedAttempt', () => {
    it('يسجل أول محاولة فاشلة مع TTL', async () => {
      redis.incr.mockResolvedValue(1);
      redis.expire.mockResolvedValue(1);

      const result = await service.recordFailedAttempt(identifier);

      expect(result).toBe(1);
      expect(redis.incr).toHaveBeenCalledWith(`otp:attempt:${identifier}`);
      expect(redis.expire).toHaveBeenCalledWith(`otp:attempt:${identifier}`, 900);
    });

    it('يزيد العداد للمحاولات المتتالية', async () => {
      redis.incr.mockResolvedValue(3);

      const result = await service.recordFailedAttempt(identifier);

      expect(result).toBe(3);
    });

    it('ينشئ block بعد 5 محاولات فاشلة', async () => {
      redis.incr.mockResolvedValue(5);
      redis.setex.mockResolvedValue('OK');
      redis.del.mockResolvedValue(1);

      const result = await service.recordFailedAttempt(identifier);

      expect(result).toBe(5);
      expect(redis.setex).toHaveBeenCalledWith(
        `otp:block:${identifier}`,
        900,
        'true',
      );
      expect(redis.del).toHaveBeenCalledWith(`otp:attempt:${identifier}`);
    });

    it('لا ينشئ block قبل 5 محاولات', async () => {
      redis.incr.mockResolvedValue(4);

      const result = await service.recordFailedAttempt(identifier);

      expect(result).toBe(4);
      expect(redis.setex).not.toHaveBeenCalled();
    });
  });

  describe('recordSuccessfulAttempt', () => {
    it('يمسح مفاتيح attempt و block', async () => {
      redis.del.mockResolvedValue(1);

      await service.recordSuccessfulAttempt(identifier);

      expect(redis.del).toHaveBeenCalledWith(`otp:attempt:${identifier}`);
      expect(redis.del).toHaveBeenCalledWith(`otp:block:${identifier}`);
    });
  });

  describe('isBlocked', () => {
    it('يعيد true إذا block موجود', async () => {
      redis.get.mockResolvedValue('true');

      const result = await service.isBlocked(identifier);

      expect(result).toBe(true);
    });

    it('يعيد false إذا block غير موجود', async () => {
      redis.get.mockResolvedValue(null);

      const result = await service.isBlocked(identifier);

      expect(result).toBe(false);
    });
  });

  describe('getBlockInfo', () => {
    it('يعيد معلومات الحظر عند وجود block', async () => {
      redis.get.mockResolvedValue('true');
      redis.ttl.mockResolvedValue(500);

      const result = await service.getBlockInfo(identifier);

      expect(result).toEqual({
        attempts: 5,
        maxAttempts: 5,
        blockTtl: 500,
      });
    });

    it('يعيد معلومات المحاولات عند عدم وجود block', async () => {
      redis.get.mockResolvedValue(null);
      redis.get // second call for attemptKey
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce('3');

      const result = await service.getBlockInfo(identifier);

      expect(result).toEqual({
        attempts: 3,
        maxAttempts: 5,
        blockTtl: 0,
      });
    });

    it('يعيد null إذا لا محاولات ولا block', async () => {
      redis.get.mockResolvedValue(null);
      redis.get
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(null);

      const result = await service.getBlockInfo(identifier);

      expect(result).toBeNull();
    });
  });

  describe('getRemainingAttempts', () => {
    it('يعيد العدد المتبقي من المحاولات', async () => {
      redis.get.mockResolvedValue('3');

      const result = await service.getRemainingAttempts(identifier);

      expect(result).toBe(2);
    });

    it('يعيد 5 إذا لم توجد محاولات', async () => {
      redis.get.mockResolvedValue(null);

      const result = await service.getRemainingAttempts(identifier);

      expect(result).toBe(5);
    });

    it('يعيد 0 إذا تجاوز الحد', async () => {
      redis.get.mockResolvedValue('6');

      const result = await service.getRemainingAttempts(identifier);

      expect(result).toBe(0);
    });
  });

  describe('isResendAllowed', () => {
    it('يعيد true إذا cooldown غير موجود', async () => {
      redis.exists.mockResolvedValue(0);

      const result = await service.isResendAllowed(identifier);

      expect(result).toBe(true);
    });

    it('يعيد false إذا cooldown موجود', async () => {
      redis.exists.mockResolvedValue(1);

      const result = await service.isResendAllowed(identifier);

      expect(result).toBe(false);
    });
  });
});

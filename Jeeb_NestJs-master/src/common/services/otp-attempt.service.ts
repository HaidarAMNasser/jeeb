import { Injectable, Inject, Logger } from '@nestjs/common';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../common/redis/redis.constants';

export interface OtpBlockInfo {
  attempts: number;
  maxAttempts: number;
  blockTtl: number;
}

@Injectable()
export class OtpAttemptService {
  private readonly logger = new Logger(OtpAttemptService.name);

  private readonly MAX_ATTEMPTS = 5;
  private readonly ATTEMPT_WINDOW = 900;
  private readonly BLOCK_DURATION = 900;

  constructor(
    @Inject(REDIS_CLIENT) private redis: Redis,
  ) {}

  async recordFailedAttempt(identifier: string): Promise<number> {
    const key = `otp:attempt:${identifier}`;
    const attempts = await this.redis.incr(key);
    if (attempts === 1) {
      await this.redis.expire(key, this.ATTEMPT_WINDOW);
    }

    if (attempts >= this.MAX_ATTEMPTS) {
      const blockKey = `otp:block:${identifier}`;
      await this.redis.setex(blockKey, this.BLOCK_DURATION, 'true');
      await this.redis.del(key);
      this.logger.warn(`OTP brute force blocked for ${identifier}`);
    }

    return attempts;
  }

  async recordSuccessfulAttempt(identifier: string): Promise<void> {
    const key = `otp:attempt:${identifier}`;
    const blockKey = `otp:block:${identifier}`;
    await this.redis.del(key);
    await this.redis.del(blockKey);
  }

  async isBlocked(identifier: string): Promise<boolean> {
    const blockKey = `otp:block:${identifier}`;
    const blocked = await this.redis.get(blockKey);
    return blocked === 'true';
  }

  async getBlockInfo(identifier: string): Promise<OtpBlockInfo | null> {
    const blockKey = `otp:block:${identifier}`;
    const attemptKey = `otp:attempt:${identifier}`;

    const [blocked, attemptsStr] = await Promise.all([
      this.redis.get(blockKey),
      this.redis.get(attemptKey),
    ]);

    if (blocked === 'true') {
      const blockTtl = await this.redis.ttl(blockKey);
      return {
        attempts: this.MAX_ATTEMPTS,
        maxAttempts: this.MAX_ATTEMPTS,
        blockTtl: blockTtl > 0 ? blockTtl : 0,
      };
    }

    const attempts = parseInt(attemptsStr || '0');
    if (attempts > 0) {
      return {
        attempts,
        maxAttempts: this.MAX_ATTEMPTS,
        blockTtl: 0,
      };
    }

    return null;
  }

  async getRemainingAttempts(identifier: string): Promise<number> {
    const key = `otp:attempt:${identifier}`;
    const attempts = parseInt((await this.redis.get(key)) || '0');
    return Math.max(0, this.MAX_ATTEMPTS - attempts);
  }

  async isResendAllowed(identifier: string): Promise<boolean> {
    const cooldownKey = `cooldown:otp:${identifier}`;
    const exists = await this.redis.exists(cooldownKey);
    return exists === 0;
  }
}

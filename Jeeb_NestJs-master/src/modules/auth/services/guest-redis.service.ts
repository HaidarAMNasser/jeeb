import { Injectable, Logger, Inject } from '@nestjs/common';
import { createHash, randomUUID } from 'crypto';
import { REDIS_CLIENT } from '../../../common/redis/redis.constants';
import type Redis from 'ioredis';

const GUEST_TTL_SECONDS = 5 * 24 * 60 * 60; // 5 days
const GUEST_PREFIX = 'guest:';

@Injectable()
export class GuestRedisService {
  private readonly logger = new Logger(GuestRedisService.name);

  constructor(@Inject(REDIS_CLIENT) private readonly redis: Redis) {}

  private buildKey(ip: string, ua: string): string {
    const salt = process.env.GUEST_SALT || 'jeeb-guest-salt';
    const hash = createHash('sha256').update(`${ip}|${ua}|${salt}`).digest('hex').slice(0, 32);
    return `${GUEST_PREFIX}${hash}`;
  }

  async getOrCreate(ip: string, ua: string): Promise<{ guestId: string; key: string; isNew: boolean; data: any }> {
    const key = this.buildKey(ip || 'unknown', ua || 'unknown');
    const raw = await this.redis.get(key);

    if (raw) {
      await this.redis.expire(key, GUEST_TTL_SECONDS);
      const data = JSON.parse(raw);
      this.logger.debug(`Guest hit ${key}`);
      return { guestId: data.guestId, key, isNew: false, data };
    }

    const guestId = randomUUID();
    const data = {
      guestId,
      ip,
      ua,
      createdAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + GUEST_TTL_SECONDS * 1000).toISOString(),
    };
    await this.redis.set(key, JSON.stringify(data), 'EX', GUEST_TTL_SECONDS);
    this.logger.log(`Guest created ${key} -> ${guestId}`);
    return { guestId, key, isNew: true, data };
  }
}

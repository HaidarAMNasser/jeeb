import { Injectable, Inject, Logger } from '@nestjs/common';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../common/redis/redis.constants';
import { LoginAttemptService } from './login-attempt.service';

export interface BlockedIP {
  ip: string;
  blockedAt: Date;
  expiresIn: number;
}

@Injectable()
export class IPBlockService {
  private readonly logger = new Logger(IPBlockService.name);

  private readonly MAX_IP_FAILURES = 20;
  private readonly BLOCK_DURATION = 3600; // 1 hour in seconds

  private readonly WHITELIST = ['127.0.0.1', '::1', 'localhost'];

  constructor(
    @Inject(REDIS_CLIENT) private redis: Redis,
    private loginAttemptService: LoginAttemptService,
  ) {}

  async checkAndBlock(ip: string): Promise<boolean> {
    if (this.WHITELIST.includes(ip) || this.isPrivateIP(ip)) {
      return false;
    }

    const isBlocked = await this.isIPBlocked(ip);
    if (isBlocked) {
      this.logger.warn(`IP ${ip} is already blocked`);
      return true;
    }

    const failures = await this.redis.get(`login:ip:${ip}`);
    const failureCount = parseInt(failures || '0');

    if (failureCount >= this.MAX_IP_FAILURES) {
      await this.blockIP(ip);
      this.logger.warn(
        `IP ${ip} has been blocked due to ${failureCount} failed attempts`,
      );
      return true;
    }

    return false;
  }

  async isIPBlocked(ip: string): Promise<boolean> {
    const key = `blocked:ip:${ip}`;
    const blocked = await this.redis.get(key);
    return blocked === 'true';
  }

  async blockIP(
    ip: string,
    duration: number = this.BLOCK_DURATION,
  ): Promise<void> {
    const key = `blocked:ip:${ip}`;
    await this.redis.setex(key, duration, 'true');
    this.logger.log(`IP ${ip} blocked for ${duration} seconds`);
  }

  async unblockIP(ip: string): Promise<void> {
    const key = `blocked:ip:${ip}`;
    await this.redis.del(key);

    await this.redis.del(`login:ip:${ip}`);

    this.logger.log(`IP ${ip} has been unblocked`);
  }

  async getBlockedIPs(): Promise<BlockedIP[]> {
    const keys = await this.redis.keys('blocked:ip:*');
    const blockedIPs: BlockedIP[] = [];

    for (const key of keys) {
      const ip = key.replace('blocked:ip:', '');
      const ttl = await this.redis.ttl(key);

      if (ttl > 0) {
        blockedIPs.push({
          ip,
          blockedAt: new Date(Date.now() - (this.BLOCK_DURATION - ttl) * 1000),
          expiresIn: ttl,
        });
      }
    }

    return blockedIPs;
  }

  async getBlockedIPsCount(): Promise<number> {
    const keys = await this.redis.keys('blocked:ip:*');
    return keys.length;
  }

  async isIPBlockedByUser(userId: number): Promise<boolean> {
    return false;
  }

  private isPrivateIP(ip: string): boolean {
    const privateIPPatterns = [
      /^10\./,
      /^172\.(1[6-9]|2\d|3[01])\./,
      /^192\.168\./,
      /^127\./,
      /^::1$/,
      /^localhost$/i,
    ];

    return privateIPPatterns.some((pattern) => pattern.test(ip));
  }
}

import { Injectable, Inject, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../../common/redis/redis.constants';
import {
  LoginBlock,
  BlockType,
} from '../../database/entities/login-block.entity';

export interface BlockInfo {
  blockLevel: number;
  expiresAt: Date | null;
  isPermanent: boolean;
  reason: string;
}

@Injectable()
export class LoginAttemptService {
  private readonly logger = new Logger(LoginAttemptService.name);

  private readonly MAX_ATTEMPTS = 5;
  private readonly ATTEMPT_TTL = 900; // 15 minutes in seconds

  private readonly BLOCK_DURATIONS = {
    1: 15 * 60 * 1000, // 15 minutes
    2: 60 * 60 * 1000, // 1 hour
    3: 24 * 60 * 60 * 1000, // 1 day
    4: 7 * 24 * 60 * 60 * 1000, // 1 week
    5: 30 * 24 * 60 * 60 * 1000, // 1 month
    6: 365 * 24 * 60 * 60 * 1000, // 1 year
    7: 365 * 24 * 60 * 60 * 1000, // 1 year
  };

  private readonly BLOCK_DURATION_TEXTS = {
    1: '15 دقيقة',
    2: 'ساعة',
    3: 'يوم',
    4: 'أسبوع',
    5: 'شهر',
    6: 'سنة',
    7: 'سنة',
  };

  constructor(
    @Inject(REDIS_CLIENT) private redis: Redis,
    @InjectRepository(LoginBlock)
    private loginBlockRepo: Repository<LoginBlock>,
  ) {}

  async recordFailedAttempt(email: string, ip: string): Promise<number> {
    const normalizedEmail = email.toLowerCase();
    const emailKey = `login:failed:${normalizedEmail}`;
    const ipKey = `login:ip:${ip}`;

    // Record email attempts
    const emailAttempts = await this.redis.incr(emailKey);
    if (emailAttempts === 1) {
      await this.redis.expire(emailKey, this.ATTEMPT_TTL);
    }

    // Record IP attempts (always)
    const ipAttempts = await this.redis.incr(ipKey);
    if (ipAttempts === 1) {
      await this.redis.expire(ipKey, 300); // 5 minutes TTL
    }

    this.logger.debug(
      `Failed login attempt for ${normalizedEmail}: ${emailAttempts}/${this.MAX_ATTEMPTS} (IP: ${ip}, attempts: ${ipAttempts})`,
    );

    return emailAttempts;
  }

  async recordIPFailure(ip: string): Promise<number> {
    const key = `login:ip:${ip}`;
    const attempts = await this.redis.incr(key);

    if (attempts === 1) {
      await this.redis.expire(key, 300); // 5 minutes
    }

    return attempts;
  }

  async getIPAttempts(ip: string): Promise<number> {
    const key = `login:ip:${ip}`;
    return parseInt((await this.redis.get(key)) || '0');
  }

  async resetIPAttempts(ip: string): Promise<void> {
    const key = `login:ip:${ip}`;
    await this.redis.del(key);
    this.logger.debug(`Reset IP attempts for ${ip}`);
  }

  async isIPBlocked(ip: string): Promise<boolean> {
    const key = `login:ip:${ip}`;
    const attempts = parseInt((await this.redis.get(key)) || '0');
    return attempts >= 3;
  }

  async isAccountLocked(email: string): Promise<boolean> {
    const normalizedEmail = email.toLowerCase();
    const key = `login:failed:${normalizedEmail}`;
    const attempts = parseInt((await this.redis.get(key)) || '0');

    return attempts >= this.MAX_ATTEMPTS;
  }

  async getFailedAttempts(email: string): Promise<number> {
    const normalizedEmail = email.toLowerCase();
    const key = `login:failed:${normalizedEmail}`;
    return parseInt((await this.redis.get(key)) || '0');
  }

  async resetAttempts(email: string): Promise<void> {
    const normalizedEmail = email.toLowerCase();
    const key = `login:failed:${normalizedEmail}`;
    await this.redis.del(key);
    this.logger.debug(`Reset failed attempts for ${normalizedEmail}`);
  }

  async hasActiveBlock(email: string): Promise<BlockInfo | null> {
    const normalizedEmail = email.toLowerCase();

    const activeBlock = await this.loginBlockRepo.findOne({
      where: {
        email: normalizedEmail,
        isActive: true,
      },
      order: { blockedAt: 'DESC' },
    });

    if (!activeBlock) {
      return null;
    }

    if (activeBlock.expiresAt && new Date(activeBlock.expiresAt) < new Date()) {
      await this.deactivateBlock(activeBlock.id);
      return null;
    }

    return {
      blockLevel: activeBlock.blockLevel,
      expiresAt: activeBlock.expiresAt,
      isPermanent: activeBlock.isPermanent,
      reason: activeBlock.reason || '',
    };
  }

  async createBlock(
    email: string,
    userId: number | null,
    ip: string,
    attemptsCount: number,
  ): Promise<LoginBlock> {
    const normalizedEmail = email.toLowerCase();

    const lastBlock = await this.loginBlockRepo.findOne({
      where: { email: normalizedEmail },
      order: { blockLevel: 'DESC' },
    });

    const nextBlockLevel = lastBlock ? lastBlock.blockLevel + 1 : 1;
    const cappedLevel = Math.min(nextBlockLevel, 7);

    const isPermanent = cappedLevel >= 7;
    const duration = isPermanent
      ? null
      : this.BLOCK_DURATIONS[cappedLevel as keyof typeof this.BLOCK_DURATIONS];

    const block = this.loginBlockRepo.create({
      email: normalizedEmail,
      userId,
      blockLevel: cappedLevel,
      blockType: BlockType.LOGIN,
      ipAddress: ip,
      attemptsCount,
      reason: `Exceeded ${attemptsCount} failed login attempts`,
      blockedAt: new Date(),
      expiresAt: duration ? new Date(Date.now() + duration) : null,
      isActive: true,
      isPermanent,
    });

    const savedBlock = await this.loginBlockRepo.save(block);

    this.logger.warn(
      `Account blocked for ${normalizedEmail}: Level ${cappedLevel}, Permanent: ${isPermanent}`,
    );

    return savedBlock;
  }

  async deactivateBlock(blockId: number): Promise<void> {
    await this.loginBlockRepo.update(blockId, { isActive: false });
  }

  async unblockByEmail(
    email: string,
    adminId?: number,
    note?: string,
  ): Promise<void> {
    const normalizedEmail = email.toLowerCase();

    await this.loginBlockRepo.update(
      { email: normalizedEmail, isActive: true },
      {
        isActive: false,
        unblockedAt: new Date(),
        unblockedBy: adminId || null,
        adminNote: note || null,
      },
    );

    await this.resetAttempts(normalizedEmail);

    this.logger.log(`Account unblocked for ${normalizedEmail}`);
  }

  async getBlockHistory(
    email: string,
    options?: { limit?: number; offset?: number },
  ): Promise<LoginBlock[]> {
    return this.loginBlockRepo.find({
      where: { email: email.toLowerCase() },
      order: { blockedAt: 'DESC' },
      take: options?.limit || 10,
      skip: options?.offset || 0,
    });
  }

  async getActiveBlocks(options?: {
    page?: number;
    limit?: number;
  }): Promise<{ data: LoginBlock[]; total: number }> {
    const page = options?.page || 1;
    const limit = options?.limit || 20;
    const skip = (page - 1) * limit;

    const [data, total] = await this.loginBlockRepo.findAndCount({
      where: { isActive: true },
      order: { blockedAt: 'DESC' },
      take: limit,
      skip,
    });

    return { data, total };
  }

  async getTodayBlocksCount(): Promise<number> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    return this.loginBlockRepo.count({
      where: {
        blockedAt: today,
      },
    });
  }

  async getActiveBlocksCount(): Promise<number> {
    return this.loginBlockRepo.count({
      where: { isActive: true },
    });
  }

  getDurationText(blockLevel: number): string {
    return this.BLOCK_DURATION_TEXTS[blockLevel] || 'غير معروف';
  }
}

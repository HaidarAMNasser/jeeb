import {
  Injectable,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, MoreThan } from 'typeorm';
import { LoyaltyAccount } from '../../database/entities/loyalty-account.entity';
import { LoyaltyTransaction } from '../../database/entities/loyalty-transaction.entity';
import { LoyaltyTransactionType } from '../../common/enums/loyalty-type.enum';
import { SettingsService } from '../settings/settings.service';

interface LoyaltyConfig {
  threshold: number;
  pointsToEarn: number;
  redeemPoints: number;
  discountValue: number;
}

const EXPIRY_MONTHS = 6;

@Injectable()
export class LoyaltyService {
  constructor(
    @InjectRepository(LoyaltyAccount)
    private accountRepo: Repository<LoyaltyAccount>,
    @InjectRepository(LoyaltyTransaction)
    private transRepo: Repository<LoyaltyTransaction>,
    private readonly settingsService: SettingsService,
    private dataSource: DataSource,
  ) {}

  private async getLoyaltyConfig(): Promise<LoyaltyConfig> {
    try {
      const thresholdSetting = await this.settingsService.getSettingByKey(
        'global_loyalty_threshold',
      );
      const pointsSetting = await this.settingsService.getSettingByKey(
        'global_loyalty_points',
      );
      const redeemSetting = await this.settingsService.getSettingByKey(
        'global_loyalty_redeem_points',
      );
      const discountSetting = await this.settingsService.getSettingByKey(
        'global_loyalty_discount_value',
      );

      return {
        threshold: Number(thresholdSetting.value) || 5,
        pointsToEarn: Number(pointsSetting.value) || 100,
        redeemPoints: Number(redeemSetting.value) || 100,
        discountValue: Number(discountSetting.value) || 1000,
      };
    } catch (error) {
      return {
        threshold: 5,
        pointsToEarn: 100,
        redeemPoints: 100,
        discountValue: 1000,
      };
    }
  }

  private isPointsExpired(updatedAt: Date): boolean {
    const expiryDate = new Date(updatedAt);
    expiryDate.setMonth(expiryDate.getMonth() + EXPIRY_MONTHS);
    return new Date() > expiryDate;
  }

  async processOrderDelivery(userId: number, orderId: number) {
    const loyaltyConfig = await this.getLoyaltyConfig();

    return await this.dataSource.transaction(async (manager) => {
      let account = await manager.findOne(LoyaltyAccount, {
        where: { userId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!account) {
        account = manager.create(LoyaltyAccount, {
          userId,
          pointsBalance: 0,
        });
        account = await manager.save(account);
      }

      if (this.isPointsExpired(account.updatedAt)) {
        account.pointsBalance = 0;
        account = await manager.save(account);
      }

      const effectiveCount =
        (account.pointsBalance % loyaltyConfig.threshold) + 1;

      let pointsAwarded = 0;
      let transaction: LoyaltyTransaction | null = null;

      if (effectiveCount >= loyaltyConfig.threshold) {
        pointsAwarded = loyaltyConfig.pointsToEarn;

        account.pointsBalance += pointsAwarded;
        account = await manager.save(account);

        transaction = await manager.save(LoyaltyTransaction, {
          loyaltyAccountId: account.id,
          userId: userId,
          amount: pointsAwarded,
          type: LoyaltyTransactionType.EARN,
          orderId,
          balanceAfter: account.pointsBalance,
          description: `Admin Reward: Reached ${loyaltyConfig.threshold} orders milestone!`,
        });
      }

      return {
        pointsAwarded,
        currentBalance: account.pointsBalance,
        threshold: loyaltyConfig.threshold,
        transaction,
        progress: `${effectiveCount}/${loyaltyConfig.threshold}`,
      };
    });
  }

  async getUserProgress(userId: number) {
    const loyaltyConfig = await this.getLoyaltyConfig();

    const account = await this.accountRepo.findOne({
      where: { userId },
    });

    if (!account) {
      return {
        currentBalance: 0,
        threshold: loyaltyConfig.threshold,
        progress: `0/${loyaltyConfig.threshold}`,
        remaining: loyaltyConfig.threshold,
        isExpired: false,
      };
    }

    const isExpired = this.isPointsExpired(account.updatedAt);

    if (isExpired && account.pointsBalance > 0) {
      await this.accountRepo.update(account.id, { pointsBalance: 0 });
      account.pointsBalance = 0;
    }

    const effectiveCount =
      account.pointsBalance > 0
        ? (account.pointsBalance % loyaltyConfig.threshold) + 1
        : 1;

    return {
      currentBalance: account.pointsBalance,
      threshold: loyaltyConfig.threshold,
      progress: `${effectiveCount}/${loyaltyConfig.threshold}`,
      remaining: Math.max(0, loyaltyConfig.threshold - effectiveCount),
      isExpired: isExpired,
    };
  }

  async earnPoints(
    userId: number,
    amount: number,
    orderId?: number,
    note?: string,
  ) {
    return await this.dataSource.transaction(async (manager) => {
      let account = await manager.findOne(LoyaltyAccount, {
        where: { userId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!account) {
        account = manager.create(LoyaltyAccount, {
          userId,
          pointsBalance: 0,
        });
      }

      if (this.isPointsExpired(account.updatedAt)) {
        account.pointsBalance = 0;
      }

      account.pointsBalance += amount;
      account = await manager.save(account);

      return await manager.save(LoyaltyTransaction, {
        loyaltyAccountId: account.id,
        userId: userId,
        amount: amount,
        type: LoyaltyTransactionType.EARN,
        orderId,
        balanceAfter: account.pointsBalance,
        description: note || `Earned points from order ${orderId}`,
      });
    });
  }

  async spendPoints(
    userId: number,
    amount: number,
    orderId?: number,
    note?: string,
  ) {
    return await this.dataSource.transaction(async (manager) => {
      const account = await manager.findOne(LoyaltyAccount, {
        where: { userId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!account) {
        throw new NotFoundException('Loyalty account not found');
      }

      if (this.isPointsExpired(account.updatedAt)) {
        account.pointsBalance = 0;
        await manager.save(account);
        throw new BadRequestException(
          'Points have expired. Your balance is now zero.',
        );
      }

      if (account.pointsBalance < amount) {
        throw new BadRequestException('Insufficient points balance');
      }

      account.pointsBalance -= amount;
      await manager.save(account);

      return await manager.save(LoyaltyTransaction, {
        loyaltyAccountId: account.id,
        userId: userId,
        amount: -amount,
        type: LoyaltyTransactionType.SPEND,
        orderId,
        balanceAfter: account.pointsBalance,
        description: note || `Points deduction for order ${orderId}`,
      });
    });
  }

  async transferPoints(senderId: number, receiverId: number, amount: number) {
    return await this.dataSource.transaction(async (manager) => {
      const sender = await manager.findOne(LoyaltyAccount, {
        where: { userId: senderId },
        lock: { mode: 'pessimistic_write' },
      });
      const receiver = await manager.findOne(LoyaltyAccount, {
        where: { userId: receiverId },
        lock: { mode: 'pessimistic_write' },
      });

      if (!sender)
        throw new NotFoundException('Sender loyalty account not found');
      if (!receiver)
        throw new NotFoundException('Receiver loyalty account not found');

      if (this.isPointsExpired(sender.updatedAt)) {
        sender.pointsBalance = 0;
        await manager.save(sender);
        throw new BadRequestException('Sender points have expired');
      }

      if (sender.pointsBalance < amount) {
        throw new BadRequestException('Insufficient balance for transfer');
      }

      sender.pointsBalance -= amount;
      await manager.save(sender);
      await manager.save(LoyaltyTransaction, {
        loyaltyAccountId: sender.id,
        userId: senderId,
        amount: -amount,
        type: LoyaltyTransactionType.TRANSFER,
        relatedUserId: receiverId,
        balanceAfter: sender.pointsBalance,
        description: `Transferred points to user ${receiverId}`,
      });

      receiver.pointsBalance += amount;
      await manager.save(receiver);

      await manager.save(LoyaltyTransaction, {
        loyaltyAccountId: receiver.id,
        userId: receiverId,
        amount: amount,
        type: LoyaltyTransactionType.TRANSFER,
        relatedUserId: senderId,
        balanceAfter: receiver.pointsBalance,
        description: `Received points from user ${senderId}`,
      });
    });
  }

  async cleanExpiredPoints(): Promise<number> {
    const expiredAccounts = await this.accountRepo.find({
      where: {
        pointsBalance: MoreThan(0),
      },
    });

    let cleanedCount = 0;

    for (const account of expiredAccounts) {
      if (this.isPointsExpired(account.updatedAt)) {
        const expiredPoints = account.pointsBalance;

        account.pointsBalance = 0;
        await this.accountRepo.save(account);

        await this.transRepo.save({
          loyaltyAccountId: account.id,
          userId: account.userId,
          amount: -expiredPoints,
          type: LoyaltyTransactionType.SPEND,
          balanceAfter: 0,
          description: `Points expired: ${expiredPoints} points removed due to expiration`,
        });

        cleanedCount++;
      }
    }

    return cleanedCount;
  }
}

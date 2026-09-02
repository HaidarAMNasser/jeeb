import { Injectable } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan } from 'typeorm';
import { LoyaltyAccount } from '../../database/entities/loyalty-account.entity';
import { LoyaltyService } from './loyalty.service';

const EXPIRY_MONTHS = 6;

@Injectable()
export class LoyaltyCron {
  constructor(
    private loyaltyService: LoyaltyService,
    @InjectRepository(LoyaltyAccount)
    private accountRepo: Repository<LoyaltyAccount>,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async handleExpiration() {
    const expiredAccounts = await this.accountRepo.find({
      where: {
        pointsBalance: MoreThan(0),
      },
    });

    let cleanedCount = 0;

    for (const account of expiredAccounts) {
      const expiryDate = new Date(account.updatedAt);
      expiryDate.setMonth(expiryDate.getMonth() + EXPIRY_MONTHS);

      if (new Date() > expiryDate) {
        try {
          const expiredPoints = account.pointsBalance;

          account.pointsBalance = 0;
          await this.accountRepo.save(account);

          cleanedCount++;
        } catch (error) {}
      }
    }

    if (cleanedCount > 0) {
    }
  }
}

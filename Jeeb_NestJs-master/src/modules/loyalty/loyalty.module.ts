import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LoyaltyService } from './loyalty.service';
import { LoyaltyCron } from './loyalty-cron.service';
import { SettingsModule } from '../settings/settings.module';
import { LoyaltyAccount } from '../../database/entities/loyalty-account.entity';
import { LoyaltyTransaction } from '../../database/entities/loyalty-transaction.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([LoyaltyAccount, LoyaltyTransaction]),
    SettingsModule,
  ],
  providers: [LoyaltyService, LoyaltyCron],
  exports: [LoyaltyService],
})
export class LoyaltyModule {}

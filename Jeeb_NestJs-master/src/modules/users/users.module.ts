import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { User } from '../../database/entities/user.entity';
import { Area } from '../../database/entities/area.entity';
import { Image } from '../../database/entities/image.entity';
import { Order } from '../../database/entities/order.entity';
import { Favorite } from '../../database/entities/favorite.entity';
import { DeliveryAssignment } from '../../database/entities/delivery-assignment.entity';
import { Wallet } from '../../database/entities/wallet.entity';
import { WalletTransaction } from '../../database/entities/wallet-transaction.entity';
import { NotificationLog } from '../../database/entities/notification-log.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuthModule } from '../auth/auth.module';
import { MerchantsModule } from '../merchants/merchants.module';
import { StorageModule } from '../../common/storage/storage.module';
import { CommonModule } from '../../common/common.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Area,
      Image,
      Order,
      Favorite,
      DeliveryAssignment,
      Wallet,
      WalletTransaction,
      NotificationLog,
    ]),
    NotificationsModule,
    forwardRef(() => AuthModule),
    MerchantsModule,
    StorageModule,
    CommonModule,
  ],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}

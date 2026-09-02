import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bullmq';
import { Order } from '../../database/entities/order.entity';
import { OrderItem } from '../../database/entities/order-item.entity';
import { Product } from '../../database/entities/product.entity';
import { Offer } from '../../database/entities/offer.entity';
import { Image } from '../../database/entities/image.entity';
import { Invoice } from '../../database/entities/invoice.entity';
import { DeliveryAssignment } from '../../database/entities/delivery-assignment.entity';
import { PaymentTransaction } from '../../database/entities/payment-transaction.entity';
import { OrderPaymentReceipt } from '../../database/entities/order-payment-receipt.entity';
import { User } from '../../database/entities/user.entity';
import { NotificationLog } from '../../database/entities/notification-log.entity';
import { Area } from '../../database/entities/area.entity';
import { OrdersService } from './services/orders.service';
import { OrderManagementService } from './services/order-management.service';
import { OrderQueryService } from './services/order-query.service';
import { OrderActionsService } from './services/order-actions.service';
import { DeliveryAssignmentService } from './services/delivery-assignment.service';
import { DriverScoringService } from './services/driver-scoring.service';
import { OrdersController } from './orders.controller';
import { CouponsModule } from '../coupons/coupons.module';
import { OrderTimeoutProcessor } from './processors/order-timeout.processor';
import { DeliveryAssignmentProcessor } from './processors/delivery-assignment.processor';
import { DeliveryNotificationService } from './services/delivery-notification.service';
import { UsersModule } from '../users/users.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { AuthModule } from '../auth/auth.module';
import { OrderPipeline } from './pipeline/order-pipeline';
import { UpdateOrderPipeline } from './pipeline/update-order-pipeline';
import { ValidationStage } from './pipeline/stages/validation.stage';
import { AuthorizationStage } from './pipeline/stages/authorization.stage';
import { StatusTransitionStage } from './pipeline/stages/status-transition.stage';
import { StockManagementStage } from './pipeline/stages/stock-management.stage';
import { ItemManagementStage } from './pipeline/stages/item-management.stage';
import { StatusUpdateStage } from './pipeline/stages/status-update.stage';
import { NotificationStage } from './pipeline/stages/notification.stage';
import { OffersHelper } from './pipeline/helpers/offers.helper';
import { FirebaseDriverLocatorService } from './services/firebase-driver-locator.service';
import { PaymentStrategyFactory } from './strategies/payment-strategy.factory';
import { CashPaymentStrategy } from './strategies/cash-payment.strategy';
import { WalletPaymentStrategy } from './strategies/wallet-payment.strategy';
import { OnlinePaymentStrategy } from './strategies/online-payment.strategy';
import { UnassignDriverService } from './services/unassign-driver.service';
import { AutoSearchUnassignStrategy } from './strategies/auto-search-unassign.strategy';
import { ManualAssignUnassignStrategy } from './strategies/manual-assign-unassign.strategy';
import { UnassignStrategyFactory } from './strategies/unassign-strategy.factory';
import { OrderAccessValidator } from './validators/order-access.validator';
import { DistanceModule } from '../distance/distance.module';
import { FirebaseModule } from '../firebase/firebase.module';
import { LoyaltyModule } from '../loyalty/loyalty.module';
import { SettingsModule } from '../settings/settings.module';
import { StorageModule } from '../../common/storage/storage.module';
import { ImageProcessingModule } from '../../common/image-processing/image-processing.module';
import { AuditModule } from '../audit/audit.module';
import { OrderStatusScheduler } from './schedulers/order-status.scheduler';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Order,
      OrderItem,
      Product,
      Offer,
      Image,
      Invoice,
      DeliveryAssignment,
      PaymentTransaction,
      OrderPaymentReceipt,
      User,
      NotificationLog,
      Area,
    ]),
    BullModule.registerQueue({
      name: 'orders',
    }),
    CouponsModule,
    UsersModule,
    NotificationsModule,
    AuthModule,
    DistanceModule,
    FirebaseModule,
    LoyaltyModule,
    SettingsModule,
    StorageModule,
    ImageProcessingModule,
    AuditModule,
  ],
  controllers: [OrdersController],
  providers: [
    OrdersService,
    OrderManagementService,
    OrderQueryService,
    OrderActionsService,
    DeliveryAssignmentService,
    OrderTimeoutProcessor,
    DeliveryAssignmentProcessor,
    DeliveryNotificationService,
    FirebaseDriverLocatorService,
    DriverScoringService,
    OrderPipeline,
    UpdateOrderPipeline,
    ValidationStage,
    AuthorizationStage,
    StatusTransitionStage,
    StockManagementStage,
    ItemManagementStage,
    StatusUpdateStage,
    NotificationStage,
    OffersHelper,
    CashPaymentStrategy,
    WalletPaymentStrategy,
    OnlinePaymentStrategy,
    PaymentStrategyFactory,
    OrderAccessValidator,
    OrderStatusScheduler,
    AutoSearchUnassignStrategy,
    ManualAssignUnassignStrategy,
    UnassignStrategyFactory,
    UnassignDriverService,
  ],
  exports: [
    OrdersService,
    OrderPipeline,
    UpdateOrderPipeline,
    FirebaseDriverLocatorService,
    PaymentStrategyFactory,
    OrderQueryService,
    OrderActionsService,
  ],
})
export class OrdersModule {}

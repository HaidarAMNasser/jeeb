import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { WhatsappNotificationStrategy } from './strategies/whatsapp-notification.strategy';
import { EmailNotificationStrategy } from './strategies/email-notification.strategy';
import { FirebaseNotificationStrategy } from './strategies/firebase-notification.strategy';
import { SecurityNotificationService } from './security-notification.service';
import { GeoLocationService } from './geo-location.service';
import { NotificationLog } from '../../database/entities/notification-log.entity';
import { NotificationRecipient } from '../../database/entities/notification-recipient.entity';
import { User } from '../../database/entities/user.entity';
import { CommonModule } from '../../common/common.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([NotificationLog, NotificationRecipient, User]),
    ScheduleModule.forRoot(),
    CommonModule,
    forwardRef(() => AuthModule),
  ],
  controllers: [NotificationsController],
  providers: [
    NotificationsService,
    WhatsappNotificationStrategy,
    EmailNotificationStrategy,
    FirebaseNotificationStrategy,
    SecurityNotificationService,
    GeoLocationService,
  ],
  exports: [NotificationsService, SecurityNotificationService],
})
export class NotificationsModule {}

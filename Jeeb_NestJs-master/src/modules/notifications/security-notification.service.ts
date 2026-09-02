import { Injectable, Inject, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotificationsService } from './notifications.service';
import { GeoLocationService } from './geo-location.service';
import { User } from '../../database/entities/user.entity';
import { NotificationChannel } from '../../common/enums/notification-channel.enum';
import { NotificationType } from '../../common/enums/notification-type.enum';

@Injectable()
export class SecurityNotificationService {
  private readonly logger = new Logger(SecurityNotificationService.name);

  constructor(
    private notificationsService: NotificationsService,
    private geoLocationService: GeoLocationService,
    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}

  async sendFailedAttemptsWarning(
    userId: number,
    email: string,
    attempts: number,
  ): Promise<void> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      this.logger.warn(`User not found for ID: ${userId}`);
      return;
    }

    try {
      await this.notificationsService.sendToUser(
        user.id,
        NotificationType.ALERT,
        '⚠️ تنبيه أمني',
        `محاولة تسجيل دخول فاشلة ${attempts}/5. إذا كانت هذه ليست أنت، يُنصح بتغيير كلمة المرور.`,
        user.notificationChannel || NotificationChannel.WHATSAPP,
        {
          type: 'security_alert',
          action: 'failed_login_attempts',
          attempts: String(attempts),
          email,
        },
      );
      this.logger.log(`Failed attempts warning sent to user ${userId}`);
    } catch (error) {
      this.logger.error(
        `Failed to send warning to user ${userId}: ${error.message}`,
      );
    }
  }

  async sendAccountLockedNotification(
    userId: number,
    email: string,
    blockLevel: number,
    duration: string,
  ): Promise<void> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      this.logger.warn(`User not found for ID: ${userId}`);
      return;
    }

    let message: string;
    if (blockLevel === 5) {
      message = `تم حظر حسابك نهائياً بسبب محاولات تسجيل دخول متكررة. يرجى التواصل مع الدعم الفني لإعادة النظر في حالتك.`;
    } else {
      message = `تم قفل حسابك لمدة ${duration} بسبب محاولات تسجيل دخول فاشلة متكررة.`;
    }

    try {
      await this.notificationsService.sendToUser(
        user.id,
        NotificationType.ALERT,
        blockLevel === 5 ? '🚫 حسابك محظور نهائياً' : '🔒 حسابك مقفل',
        message,
        user.notificationChannel || NotificationChannel.WHATSAPP,
        {
          type: 'security_alert',
          action: 'account_locked',
          blockLevel: String(blockLevel),
          duration,
          email,
        },
      );
    } catch (error) {
      this.logger.error(
        `Failed to send locked notification to user ${userId}: ${error.message}`,
      );
    }
  }

  async sendAccountUnlockedNotification(userId: number): Promise<void> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      this.logger.warn(`User not found for ID: ${userId}`);
      return;
    }

    try {
      await this.notificationsService.sendToUser(
        user.id,
        NotificationType.ALERT,
        '✅ حسابك مفتح',
        'تم إعادة تفعيل حسابك بنجاح. يمكنك الآن تسجيل الدخول.',
        user.notificationChannel || NotificationChannel.WHATSAPP,
        {
          type: 'security_alert',
          action: 'account_unlocked',
        },
      );
      this.logger.log(`Account unlocked notification sent to user ${userId}`);
    } catch (error) {
      this.logger.error(
        `Failed to send unlocked notification to user ${userId}: ${error.message}`,
      );
    }
  }

  async sendNewDeviceLoginNotification(
    userId: number,
    ip: string,
  ): Promise<void> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      this.logger.warn(`User not found for ID: ${userId}`);
      return;
    }

    const location = await this.geoLocationService.getLocationFromIp(ip);

    try {
      await this.notificationsService.sendToUser(
        user.id,
        NotificationType.ALERT,
        '📱 تسجيل دخول جديد',
        `تم تسجيل دخول إلى حسابك من موقع جديد: ${location}. إذا لم تقم أنت بتسجيل الدخول، يرجى تغيير كلمة المرور فوراً.`,
        user.notificationChannel || NotificationChannel.WHATSAPP,
        {
          type: 'security_alert',
          action: 'new_device_login',
          ip,
          location,
        },
      );
    } catch (error) {
      this.logger.error(
        `Failed to send new device login notification to user ${userId}: ${error.message}`,
      );
    }
  }

  async sendIPBlockedNotification(ip: string): Promise<void> {
    this.logger.warn(
      `🚫 IP ${ip} has been blocked due to multiple failed attempts`,
    );
  }
}

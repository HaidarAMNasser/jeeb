import { Injectable, Inject, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Cron, CronExpression } from '@nestjs/schedule';
import Redis from 'ioredis';
import { CleanupService } from '../../common/services/cleanup.service';
import { NotificationStrategy } from './interfaces/notification-strategy.interface';
import { WhatsappNotificationStrategy } from './strategies/whatsapp-notification.strategy';
import { EmailNotificationStrategy } from './strategies/email-notification.strategy';
import { FirebaseNotificationStrategy } from './strategies/firebase-notification.strategy';
import { NotificationChannel } from '../../common/enums/notification-channel.enum';
import {
  NotificationLog,
  NotificationStatus,
} from '../../database/entities/notification-log.entity';
import { NotificationType } from '../../common/enums/notification-type.enum';
import { NotificationTopic } from '../../common/enums/notification-topic.enum';
import {
  NotificationRecipient,
  RecipientStatus,
} from '../../database/entities/notification-recipient.entity';
import { REDIS_CLIENT } from '../../common/redis/redis.constants';
import { User } from '../../database/entities/user.entity';
import { UserRole } from '../../common/enums/user-role.enum';

@Injectable()
export class NotificationsService {
  private strategies: Map<NotificationChannel, NotificationStrategy> =
    new Map();
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectRepository(NotificationLog)
    private readonly notificationLogRepo: Repository<NotificationLog>,
    @InjectRepository(NotificationRecipient)
    private readonly notificationRecipientRepo: Repository<NotificationRecipient>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly cleanupService: CleanupService,
    private readonly whatsappStrategy: WhatsappNotificationStrategy,
    private readonly emailStrategy: EmailNotificationStrategy,
    private readonly firebaseStrategy: FirebaseNotificationStrategy,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {
    this.strategies.set(NotificationChannel.WHATSAPP, this.whatsappStrategy);
    this.strategies.set(NotificationChannel.EMAIL, this.emailStrategy);
    this.strategies.set(NotificationChannel.FIREBASE, this.firebaseStrategy);
  }

  async sendWelcomeEmail(to: string, name: string): Promise<void> {
    const strategy = this.strategies.get(NotificationChannel.EMAIL);
    if (strategy) {
      await strategy.sendWelcomeMessage(to, name);
    }
  }
  async sendOtp(
    to: string,
    otp: string,
    channel: NotificationChannel = NotificationChannel.WHATSAPP,
    userId?: number,
  ): Promise<void> {
    const strategy = this.strategies.get(channel);
    if (!strategy) {
      this.logger.error(`Notification channel ${channel} not supported`);
      throw new Error(`Notification channel ${channel} not supported`);
    }

    try {
      // 1. Store in Redis with 5 minutes expiration (300 seconds)
      // Key format: otp:{recipient}
      this.logger.debug(`Storing OTP in Redis for ${to}`);
      try {
        await this.redis.set(`otp:${to}`, otp, 'EX', 300);
        this.logger.debug(`OTP stored in Redis for ${to}`);
      } catch (redisError) {
        const errorMessage =
          redisError instanceof Error ? redisError.message : String(redisError);
        const errorStack =
          redisError instanceof Error ? redisError.stack : undefined;
        this.logger.error(`Redis set failed: ${errorMessage}`, errorStack);
        throw new Error('OTP Service Unavailable (Cache Error)');
      }

      // 2. Send via strategy
      this.logger.debug(`Sending OTP via ${channel} to ${to}`);
      await strategy.sendOtp(to, otp);
      this.logger.debug(`OTP sent via ${channel} to ${to}`);

      // 3. Log the notification (DB is for audit/history now)
      this.logger.debug(`Logging notification to DB for ${to}`);
      const log = this.notificationLogRepo.create({
        userId,
        recipient: to,
        channel,
        type: NotificationType.OTP,
        otpCode: otp, // In production, hash this!
        content: `Your OTP is ${otp}`,
        status: NotificationStatus.SENT,
        expiresAt: new Date(Date.now() + 5 * 60 * 1000), // 5 minutes expiration
      });
      await this.notificationLogRepo.save(log);
    } catch (error) {
      this.logger.error(
        `Failed to send OTP to ${to}`,
        error instanceof Error ? error.stack : error,
      );
      // Log failure
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      const log = this.notificationLogRepo.create({
        userId,
        recipient: to,
        channel,
        type: NotificationType.OTP,
        status: NotificationStatus.FAILED,
        metadata: { error: errorMessage },
      });
      // Use try-catch for logging failure to avoid masking original error
      try {
        await this.notificationLogRepo.save(log);
      } catch (dbError) {
        this.logger.error(`Failed to save notification failure log`, dbError);
      }
      throw error;
    }
  }

  async verifyOtp(
    to: string,
    otp: string,
    type: NotificationType = NotificationType.OTP,
  ): Promise<boolean> {
    // 1. Check Redis first (Primary source of truth for active OTPs)
    const storedOtp = await this.redis.get(`otp:${to}`);

    if (storedOtp && storedOtp === otp) {
      // Valid OTP
      await this.redis.del(`otp:${to}`); // Consume the OTP

      // Mark DB log as used (Best effort, for audit)
      // We find the latest log that is not used
      const log = await this.notificationLogRepo.findOne({
        where: {
          recipient: to,
          type,
          isUsed: false,
        },
        order: { createdAt: 'DESC' },
      });

      if (log) {
        log.isUsed = true;
        log.usedAt = new Date();
        await this.notificationLogRepo.save(log);
      }

      return true;
    }

    return false;
  }

  async sendWelcomeMessage(
    to: string,
    name: string,
    channel: NotificationChannel = NotificationChannel.WHATSAPP,
  ): Promise<void> {
    const strategy = this.strategies.get(channel);
    if (!strategy) {
      this.logger.error(`Notification channel ${channel} not supported`);
      throw new Error(`Notification channel ${channel} not supported`);
    }
    await strategy.sendWelcomeMessage(to, name);

    // Log (optional for welcome messages, but good for tracking)
    await this.notificationLogRepo.save({
      recipient: to,
      channel,
      type: NotificationType.WELCOME,
      content: `Welcome ${name}`,
      status: NotificationStatus.SENT,
    });
  }

  // Cron job to clean up old logs every day at midnight
  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async handleCron() {
    this.logger.debug('Running cleanup of old notification logs...');

    // Delete OTPs older than 24 hours (1 day) using the generic CleanupService
    await this.cleanupService.cleanupOldRecords(
      this.notificationLogRepo,
      'createdAt',
      1,
      { type: NotificationType.OTP },
    );
  }

  async sendOrderNotificationToDriver(
    driverFcmToken: string,
    orderId: number,
    orderTotal: number,
    pickupAddress: string,
  ): Promise<void> {
    const title = '🚚 طلب توصيل جديد';
    const body = `طلب توصيل #${orderId} -距离 ${pickupAddress}`;

    try {
      await this.firebaseStrategy.sendNotification(
        driverFcmToken,
        title,
        body,
        {
          type: 'NEW_DELIVERY',
          orderId: orderId.toString(),
          orderTotal: orderTotal.toString(),
          pickupAddress,
        },
      );
      this.logger.log(`Order notification sent to driver for order ${orderId}`);
    } catch (error) {
      this.logger.error(
        `Failed to send order notification to driver: ${error}`,
      );
      throw error;
    }
  }

  async sendToUser(
    userId: number,
    type: NotificationType,
    title: string,
    body: string,
    channel: NotificationChannel = NotificationChannel.FIREBASE,
    metadata?: Record<string, any>,
  ): Promise<NotificationLog> {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException(`User with id ${userId} not found`);
    }

    let recipient = user.phone;
    if (channel === NotificationChannel.EMAIL) {
      recipient = user.email ?? user.phone;
    } else if (channel === NotificationChannel.FIREBASE) {
      recipient = user.firebaseToken || `user_${userId}`;
    }

    const notification = this.notificationLogRepo.create({
      userId,
      recipient,
      channel,
      type,
      title,
      body,
      status: NotificationStatus.PENDING,
      metadata,
    });

    const savedNotification = await this.notificationLogRepo.save(notification);

    await this.notificationRecipientRepo.save({
      notificationId: savedNotification.id,
      userId,
      status: RecipientStatus.PENDING,
    });

    try {
      const strategy = this.strategies.get(channel);
      if (strategy) {
        if (channel === NotificationChannel.FIREBASE && user.firebaseToken) {
          const stringMetadata = this.convertToStringMetadata(metadata);
          await this.firebaseStrategy.sendNotification(
            user.firebaseToken,
            title,
            body,
            stringMetadata,
          );
        } else if (channel === NotificationChannel.WHATSAPP) {
          await this.whatsappStrategy.sendOtp(recipient, body);
        } else if (channel === NotificationChannel.EMAIL) {
          await this.emailStrategy.sendWelcomeMessage(recipient, title);
        }
      }

      savedNotification.status = NotificationStatus.SENT;
      savedNotification.sentAt = new Date();
      await this.notificationLogRepo.save(savedNotification);
    } catch (error) {
      savedNotification.status = NotificationStatus.FAILED;
      savedNotification.metadata = {
        ...savedNotification.metadata,
        error: (error as Error).message,
      };
      await this.notificationLogRepo.save(savedNotification);
    }

    return savedNotification;
  }

  async sendToAll(
    topic: NotificationTopic | undefined,
    type: NotificationType,
    title: string,
    body: string,
    channel: NotificationChannel = NotificationChannel.FIREBASE,
    metadata?: Record<string, any>,
    scheduledAt?: Date,
  ): Promise<{
    notification: NotificationLog;
    totalTargeted: number;
    deliveredCount: number;
    undeliveredCount: number;
  }> {
    const role = topic ? this.getRoleFromTopic(topic) : undefined;
    const users = role
      ? await this.userRepo.find({ where: { role } })
      : await this.userRepo.find();

    const notification = this.notificationLogRepo.create({
      recipient: topic || 'ALL_CUSTOMERS',
      channel,
      type,
      title,
      body,
      topic,
      status: NotificationStatus.PENDING,
      metadata,
      scheduledAt: scheduledAt || undefined,
    });

    const savedNotification = await this.notificationLogRepo.save(notification);

    const recipients = users.map((user) => ({
      notificationId: savedNotification.id,
      userId: user.id,
      status: RecipientStatus.PENDING,
    }));

    await this.notificationRecipientRepo.save(recipients);

    let deliveredCount = 0;
    let undeliveredCount = 0;

    if (!scheduledAt) {
      const stringMetadata = this.convertToStringMetadata(metadata);

      if (channel === NotificationChannel.FIREBASE) {
        const tokenUsers = users
          .filter(u => u.firebaseToken)
          .map(u => ({ token: u.firebaseToken!, userId: u.id }));

        undeliveredCount += users.length - tokenUsers.length;

        const CHUNK_SIZE = 500;
        const allResults: Array<{ success: boolean; userId: number }> = [];

        for (let i = 0; i < tokenUsers.length; i += CHUNK_SIZE) {
          const chunk = tokenUsers.slice(i, i + CHUNK_SIZE);
          const batchResults = await this.firebaseStrategy.sendBatch(
            chunk.map(tu => ({ token: tu.token, title, body, data: stringMetadata })),
          );
          for (let j = 0; j < batchResults.length; j++) {
            allResults.push({ success: batchResults[j].success, userId: chunk[j].userId });
          }
        }

        const deliveredIds: number[] = [];
        for (const r of allResults) {
          if (r.success) {
            deliveredCount++;
            deliveredIds.push(r.userId);
          } else {
            undeliveredCount++;
          }
        }

        if (deliveredIds.length > 0) {
          await this.notificationRecipientRepo.update(
            { notificationId: savedNotification.id, userId: In(deliveredIds) },
            { status: RecipientStatus.RECEIVED, receivedAt: new Date() },
          );
        }
      } else {
        for (const user of users) {
          try {
            if (user.firebaseToken) {
              await this.firebaseStrategy.sendNotification(
                user.firebaseToken,
                title,
                body,
                stringMetadata,
              );
              deliveredCount++;
              await this.notificationRecipientRepo.update(
                { notificationId: savedNotification.id, userId: user.id },
                { status: RecipientStatus.RECEIVED, receivedAt: new Date() },
              );
            } else {
              undeliveredCount++;
            }
          } catch {
            undeliveredCount++;
          }
        }
      }

      savedNotification.status =
        deliveredCount > 0
          ? NotificationStatus.SENT
          : NotificationStatus.FAILED;
      savedNotification.sentAt = new Date();
      savedNotification.metadata = {
        ...savedNotification.metadata,
        totalTargeted: users.length,
        deliveredCount,
        undeliveredCount,
      };
      await this.notificationLogRepo.save(savedNotification);
    }

    return {
      notification: savedNotification,
      totalTargeted: users.length,
      deliveredCount,
      undeliveredCount,
    };
  }

  private getRoleFromTopic(topic: NotificationTopic): UserRole {
    switch (topic) {
      case NotificationTopic.ALL_DRIVERS:
        return UserRole.DELIVERY;
      case NotificationTopic.ALL_MERCHANTS:
        return UserRole.MERCHANT;
      case NotificationTopic.ALL_CUSTOMERS:
        return UserRole.CUSTOMER;
      case NotificationTopic.ALL_OFFICE_OWNERS:
        return UserRole.OFFICE_OWNER;
      case NotificationTopic.ALL_OFFERS:
        return UserRole.CUSTOMER;
      case NotificationTopic.ALL_COUPONS:
        return UserRole.CUSTOMER;
      default:
        return UserRole.CUSTOMER;
    }
  }

  async markAsRead(notificationIds: number[], userId: number): Promise<void> {
    await this.notificationRecipientRepo.update(
      {
        notificationId: { $in: notificationIds } as any,
        userId,
      },
      {
        readAt: new Date(),
        status: RecipientStatus.READ,
      },
    );
  }

  async getNotificationsForUser(
    userId: number,
    page: number = 1,
    limit: number = 20,
  ): Promise<{ data: any[]; total: number }> {
    const [recipients, total] =
      await this.notificationRecipientRepo.findAndCount({
        where: { userId },
        relations: ['notification'],
        order: { createdAt: 'DESC' },
        skip: (page - 1) * limit,
        take: limit,
      });

    const data = recipients.map((recipient) => ({
      id: recipient.notification.id,
      type: recipient.notification.type,
      title: recipient.notification.title,
      body: recipient.notification.body,
      topic: recipient.notification.topic,
      channel: recipient.notification.channel,
      status: recipient.notification.status,
      readAt: recipient.readAt,
      createdAt: recipient.notification.createdAt,
    }));

    return { data, total };
  }

  async getNotificationById(id: number, userId: number): Promise<any> {
    const recipient = await this.notificationRecipientRepo.findOne({
      where: { notificationId: id, userId },
      relations: ['notification'],
    });

    if (!recipient) {
      throw new NotFoundException('Notification not found');
    }

    return {
      id: recipient.notification.id,
      type: recipient.notification.type,
      title: recipient.notification.title,
      body: recipient.notification.body,
      topic: recipient.notification.topic,
      channel: recipient.notification.channel,
      status: recipient.notification.status,
      readAt: recipient.readAt,
      createdAt: recipient.notification.createdAt,
    };
  }

  private convertToStringMetadata(
    metadata?: Record<string, any>,
  ): Record<string, string> {
    if (!metadata) {
      return {};
    }
    const stringMetadata: Record<string, string> = {};
    for (const [key, value] of Object.entries(metadata)) {
      stringMetadata[key] = String(value);
    }
    return stringMetadata;
  }
}

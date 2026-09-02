import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { NotificationStrategy } from '../interfaces/notification-strategy.interface';

@Injectable()
export class FirebaseNotificationStrategy implements NotificationStrategy {
  private readonly logger = new Logger(FirebaseNotificationStrategy.name);
  private initialized = false;

  constructor(private configService: ConfigService) {
    this.initializeFirebase();
  }

  private initializeFirebase(): void {
    if (admin.apps.length || this.initialized) {
      this.initialized = true;
      return;
    }

    try {
      const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
      const privateKey = this.configService
        .get<string>('FIREBASE_PRIVATE_KEY')
        ?.replace(/\\n/g, '\n');
      const clientEmail = this.configService.get<string>(
        'FIREBASE_CLIENT_EMAIL',
      );
      const databaseURL = this.configService.get<string>(
        'FIREBASE_DATABASE_URL',
      );

      const isValidPrivateKey = privateKey?.includes(
        '-----BEGIN PRIVATE KEY-----',
      );

      if (projectId && privateKey && isValidPrivateKey && clientEmail) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            privateKey,
            clientEmail,
          }),
          databaseURL,
        });
        this.initialized = true;
        this.logger.log('Firebase Admin initialized for notifications');
      } else {
        this.logger.warn(
          'Firebase credentials not found. Firebase notifications disabled.',
        );
      }
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin', error);
    }
  }

  async sendOtp(to: string, otp: string): Promise<void> {
    if (!this.initialized) {
      this.logger.warn('Firebase not initialized. Skipping OTP notification.');
      return;
    }

    try {
      const message: admin.messaging.Message = {
        notification: {
          title: 'رمز التحقق',
          body: `رمز التحقق الخاص بك هو: ${otp}`,
        },
        data: {
          type: 'OTP',
          otp,
        },
        token: to,
      };

      await admin.messaging().send(message);
      this.logger.log(`Firebase OTP sent to token: ${to.substring(0, 20)}...`);
    } catch (error) {
      this.logger.error('Failed to send Firebase OTP', error);
      throw error;
    }
  }

  async sendWelcomeMessage(to: string, name: string): Promise<void> {
    if (!this.initialized) {
      this.logger.warn(
        'Firebase not initialized. Skipping welcome notification.',
      );
      return;
    }

    try {
      const message: admin.messaging.Message = {
        notification: {
          title: 'مرحباً بك في جيب',
          body: `مرحباً ${name}!很高兴为您提供服务`,
        },
        data: {
          type: 'WELCOME',
        },
        token: to,
      };

      await admin.messaging().send(message);
      this.logger.log(
        `Firebase welcome message sent to token: ${to.substring(0, 20)}...`,
      );
    } catch (error) {
      this.logger.error('Failed to send Firebase welcome message', error);
    }
  }

  async sendBatch(
    messages: Array<{ token: string; title: string; body: string; data?: Record<string, string> }>,
  ): Promise<Array<{ success: boolean; token: string }>> {
    if (!this.initialized) {
      this.logger.warn('Firebase not initialized. Skipping batch.');
      return messages.map(m => ({ success: false, token: m.token }));
    }

    try {
      const firebaseMessages: admin.messaging.Message[] = messages.map(m => ({
        notification: { title: m.title, body: m.body },
        data: m.data || {},
        token: m.token,
      }));

      const response = await admin.messaging().sendEach(firebaseMessages);
      return response.responses.map((r, i) => ({
        success: r.success,
        token: messages[i].token,
      }));
    } catch (error) {
      this.logger.error(`Firebase batch send failed: ${error instanceof Error ? error.message : error}`);
      return messages.map(m => ({ success: false, token: m.token }));
    }
  }

  async sendNotification(
    token: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (!this.initialized) {
      this.logger.warn('Firebase not initialized. Skipping notification.');
      return;
    }

    try {
      const message: admin.messaging.Message = {
        notification: { title, body },
        data: data || {},
        token,
      };

      await admin.messaging().send(message);
      this.logger.log(
        `✅ Firebase notification sent successfully to token: ${token.substring(0, 20)}... | Title: "${title}" | Body: "${body}"`,
      );
    } catch (error) {
      this.logger.error(
        `❌ Failed to send Firebase notification to token: ${token.substring(0, 20)}... | Title: "${title}" | Error: ${error instanceof Error ? error.message : error}`,
      );
      throw error;
    }
  }
}

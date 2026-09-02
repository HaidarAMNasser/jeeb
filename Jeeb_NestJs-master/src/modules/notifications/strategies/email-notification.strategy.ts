import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NotificationStrategy } from '../interfaces/notification-strategy.interface';
import * as nodemailer from 'nodemailer';

export interface EmailSendResult {
  success: boolean;
  message: string;
  messageId?: string;
  error?: string;
}

@Injectable()
export class EmailNotificationStrategy implements NotificationStrategy {
  private readonly logger = new Logger(EmailNotificationStrategy.name);
  private transporter: nodemailer.Transporter;
  private readonly emailFrom: string;

  constructor(private readonly configService: ConfigService) {
    this.emailFrom = this.configService.get<string>(
      'EMAIL_FROM',
      'noreply@jeeb.com',
    );

    const smtpHost = this.configService.get<string>('SMTP_HOST');
    const smtpPort =
      parseInt(this.configService.get<string>('SMTP_PORT') || '587', 10) || 587;
    const smtpSecure = this.configService.get<string>('SMTP_SECURE') === 'true';
    const smtpUser = this.configService.get<string>('SMTP_USER');
    const smtpPass = this.configService.get<string>('SMTP_PASS');

    this.transporter = nodemailer.createTransport({
      host: smtpHost,
      port: smtpPort,
      secure: smtpSecure, // true for 465, false for other ports
      auth: {
        user: smtpUser,
        pass: smtpPass,
      },
    });
  }

  async sendOtp(to: string, otp: string): Promise<void> {
    this.logger.log(`[Email] Sending OTP to ${to}: ${otp}`);

    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #333; text-align: center;">Jeeb Verification Code</h2>
        <p style="color: #666; font-size: 16px; text-align: center;">Please use the following code to verify your account:</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; text-align: center; margin: 20px 0;">
          <span style="font-size: 24px; font-weight: bold; letter-spacing: 5px; color: #000;">${otp}</span>
        </div>
        <p style="text-align: center; color: #999; font-size: 12px;">This code will expire in 5 minutes.</p>
        <div style="text-align: center; margin-top: 20px;">
          <button onclick="navigator.clipboard.writeText('${otp}')" style="background-color: #007bff; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer;">Copy Code</button>
        </div>
      </div>
    `;

    try {
      const info = await this.transporter.sendMail({
        from: this.emailFrom,
        to,
        subject: 'Jeeb Verification Code',
        text: `Your verification code is: ${otp}`,
        html: htmlContent,
      });

      this.logger.log(
        `[Email] Email sent successfully to ${to}, MessageId: ${info.messageId}`,
      );
      this.logger.debug(`[Email] SMTP response: ${JSON.stringify(info)}`);
    } catch (error) {
      this.logger.error(`[Email] Failed to send email to ${to}`, error);
      throw new Error(`Failed to send email: ${error.message}`);
    }
  }

  async sendWelcomeMessage(to: string, name: string): Promise<void> {
    this.logger.log(
      `[Email] Sending Welcome Message to ${to}: Welcome ${name}!`,
    );

    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #007bff; text-align: center;">Welcome to Jeeb, ${name}!</h2>
        <p style="color: #666; font-size: 16px; line-height: 1.5;">We are thrilled to have you on board. Your account has been successfully created by our administration team.</p>
        <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p style="margin: 0; color: #333;">You can now log in to the application and start exploring our services.</p>
        </div>
        <p style="color: #666; font-size: 14px;">If you have any questions, feel free to contact our support team.</p>
        <p style="text-align: center; margin-top: 30px; color: #999; font-size: 12px;">&copy; ${new Date().getFullYear()} Jeeb Delivery. All rights reserved.</p>
      </div>
    `;

    try {
      await this.transporter.sendMail({
        from: this.emailFrom,
        to,
        subject: 'Welcome to Jeeb!',
        text: `Welcome ${name}! We are glad to have you with us.`,
        html: htmlContent,
      });
    } catch (error) {
      this.logger.error(`Failed to send welcome email to ${to}`, error);
      throw new Error(`Failed to send welcome email: ${error.message}`);
    }
  }
}

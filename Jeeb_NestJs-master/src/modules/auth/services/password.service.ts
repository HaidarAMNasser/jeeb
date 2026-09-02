import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
  Inject,
} from '@nestjs/common';
import Redis from 'ioredis';
import * as bcrypt from 'bcrypt';
import { UsersService } from '../../users/users.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { REDIS_CLIENT } from '../../../common/redis/redis.constants';
import { ForgotPasswordDto } from '../dto/forgot-password.dto';
import { ResetPasswordDto } from '../dto/reset-password.dto';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { NotificationType } from '../../../common/enums/notification-type.enum';
import { createErrorResponse } from '../../../common/constants/error-codes';

@Injectable()
export class PasswordService {
  private readonly logger = new Logger(PasswordService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly notificationsService: NotificationsService,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  async forgotPassword(forgotPasswordDto: ForgotPasswordDto) {
    const identifier = forgotPasswordDto.email || forgotPasswordDto.phone;
    if (!identifier) {
      throw new BadRequestException(
        createErrorResponse('MISSING_REQUIRED_FIELD', 400),
      );
    }
    let user = await this.usersService.findOneByEmail(identifier);
    if (!user) {
      user = await this.usersService.findOneByPhone(identifier);
    }
    if (!user) {
      throw new NotFoundException(
        createErrorResponse('USER_NOT_FOUND', 404),
      );
    }

    const otp = this.generateOtp();
    const channel =
      user.notificationChannel === NotificationChannel.EMAIL
        ? NotificationChannel.EMAIL
        : NotificationChannel.WHATSAPP;
    const recipient =
      channel === NotificationChannel.EMAIL ? user.email! : user.phone;

    await this.notificationsService.sendOtp(
      recipient,
      otp,
      channel,
      user.id,
    );

    const channelLabel =
      channel === NotificationChannel.EMAIL ? 'email' : 'phone';

    return {
      message: `OTP sent successfully to your ${channelLabel}.`,
      data: {
        message: `OTP sent successfully to your ${channelLabel}.`,
      },
    };
  }

  async resendOtp(identifier: string) {
    let user = await this.usersService.findOneByEmail(identifier);
    if (!user) {
      user = await this.usersService.findOneByPhone(identifier);
    }
    if (!user) {
      throw new NotFoundException(
        createErrorResponse('USER_NOT_FOUND', 404),
      );
    }

    if (user.verifiedAt) {
      return { message: 'Account already verified' };
    }

    const cooldownKey = `cooldown:otp:${identifier}`;
    const timeLeft = await this.redis.ttl(cooldownKey);
    if (timeLeft > 0) {
      throw new BadRequestException(
        createErrorResponse('OTP_RATE_LIMIT_EXCEEDED', 400, undefined, {
          timeLeft,
        }),
      );
    }

    const otp = this.generateOtp();
    const channel =
      user.notificationChannel === NotificationChannel.EMAIL
        ? NotificationChannel.EMAIL
        : NotificationChannel.WHATSAPP;
    const recipient =
      channel === NotificationChannel.EMAIL ? user.email! : user.phone;

    await this.notificationsService.sendOtp(
      recipient,
      otp,
      channel,
      user.id,
    );
    await this.redis.set(cooldownKey, '1', 'EX', 60);

    const channelLabel =
      channel === NotificationChannel.EMAIL ? 'email' : 'phone';
    return {
      message: `OTP resent successfully to your ${channelLabel}.`,
      data: { message: `OTP resent successfully to your ${channelLabel}.` },
    };
  }

  async resetPassword(resetPasswordDto: ResetPasswordDto) {
    const user = await this.usersService.findOneByEmail(resetPasswordDto.email);
    if (!user) {
      throw new NotFoundException(
        createErrorResponse('USER_NOT_FOUND', 404),
      );
    }

    const recipient = user.email!;

    const isValid = await this.notificationsService.verifyOtp(
      recipient,
      resetPasswordDto.otp,
      NotificationType.OTP,
    );

    if (!isValid) {
      throw new BadRequestException(
        createErrorResponse('OTP_INVALID', 400),
      );
    }

    const hashedPassword = await bcrypt.hash(resetPasswordDto.password, 10);
    await this.usersService.update(user.id, { password: hashedPassword });

    return {
      message: 'Password reset successfully. You can now login.',
      data: {
        message: 'Password reset successfully. You can now login.',
      },
    };
  }

  private generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
}

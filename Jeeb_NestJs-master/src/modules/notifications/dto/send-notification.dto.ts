import {
  IsEnum,
  IsString,
  IsOptional,
  IsNumber,
  IsArray,
  IsDateString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { NotificationType } from '../../../common/enums/notification-type.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { NotificationTopic } from '../../../common/enums/notification-topic.enum';

export class SendToUserDto {
  @IsNumber()
  userId: number;

  @IsEnum(NotificationType)
  type: NotificationType;

  @IsString()
  title: string;

  @IsString()
  body: string;

  @IsEnum(NotificationChannel)
  @IsOptional()
  channel?: NotificationChannel;

  @IsOptional()
  @IsString()
  metadata?: Record<string, any>;
}

export class SendToAllDto {
  @IsEnum(NotificationTopic)
  @IsOptional()
  topic?: NotificationTopic;

  @IsEnum(NotificationType)
  type: NotificationType;

  @IsString()
  title: string;

  @IsString()
  body: string;

  @IsEnum(NotificationChannel)
  @IsOptional()
  channel?: NotificationChannel;

  @IsOptional()
  @IsString()
  metadata?: Record<string, any>;

  @IsOptional()
  @IsDateString()
  scheduledAt?: string;
}

export class SendToCustomersDto {
  @IsString()
  title: string;

  @IsString()
  body: string;
}

export class MarkNotificationsReadDto {
  @IsArray()
  @IsNumber({}, { each: true })
  notificationIds: number[];
}

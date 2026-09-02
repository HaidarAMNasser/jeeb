import {
  IsEmail,
  IsString,
  MinLength,
  IsOptional,
  IsNumber,
  IsISO8601,
} from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';

export class CreateOfficeOwnerDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsString()
  firstName: string;

  @IsString()
  lastName: string;

  @IsString()
  phone: string;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  countryId?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  cityId?: number;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  notificationChannel?: NotificationChannel;

  @IsOptional()
  @IsISO8601()
  @Transform(({ value }) => (value ? new Date(value) : undefined))
  @Type(() => Date)
  birthday?: Date;
}

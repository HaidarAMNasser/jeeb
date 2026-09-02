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

export class UpdateOfficeOwnerDto {
  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  @MinLength(6)
  password?: string;

  @IsOptional()
  @IsString()
  firstName?: string;

  @IsOptional()
  @IsString()
  lastName?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  countryId?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  cityId?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  areaId?: number;

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

import {
  IsEmail,
  IsString,
  MinLength,
  IsOptional,
  IsNumber,
  IsEnum,
  IsBoolean,
  IsObject,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';

const toNumber = (value: string | number | undefined): number | undefined => {
  if (typeof value === 'string') {
    const num = Number(value);
    return isNaN(num) ? undefined : num;
  }
  return value;
};

export class UpdateDeliveryDto {
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
  @Transform(({ value }) => toNumber(value))
  @IsNumber()
  countryId?: number;

  @IsOptional()
  @Transform(({ value }) => toNumber(value))
  @IsNumber()
  cityId?: number;

  @IsOptional()
  @Transform(({ value }) => toNumber(value))
  @IsNumber()
  areaId?: number;

  @IsOptional()
  @IsEnum(NotificationChannel)
  notificationChannel?: NotificationChannel;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      return value === 'true';
    }
    return value;
  })
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      return value === 'true';
    }
    return value;
  })
  @IsBoolean()
  isOnline?: boolean;

  @IsOptional()
  @Transform(({ value }) => toNumber(value))
  @IsNumber()
  currentLat?: number;

  @IsOptional()
  @Transform(({ value }) => toNumber(value))
  @IsNumber()
  currentLng?: number;

  @IsOptional()
  @IsObject()
  location?: { lat: number; lng: number };

  @IsOptional()
  birthday?: any;

  @IsOptional()
  @IsString()
  firebaseToken?: string;
}

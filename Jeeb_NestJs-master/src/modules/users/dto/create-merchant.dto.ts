import {
  IsEmail,
  IsNotEmpty,
  IsString,
  MinLength,
  IsOptional,
  IsNumber,
  IsEnum,
} from 'class-validator';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { Transform, Type } from 'class-transformer';

export class CreateMerchantDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsString()
  @IsNotEmpty()
  firstName: string;

  @IsString()
  @IsNotEmpty()
  lastName: string;

  @IsString()
  @IsNotEmpty()
  phone: string;

  @IsOptional()
  @Transform(({ value }) => {
    // Convert form-data strings to numbers
    if (typeof value === 'string') {
      const num = Number(value);
      return isNaN(num) ? undefined : num;
    }
    // If already a number or undefined, keep as is
    return value;
  })
  @IsNumber()
  countryId?: number;

  @IsOptional()
  @Transform(({ value }) => {
    // Convert form-data strings to numbers
    if (typeof value === 'string') {
      const num = Number(value);
      return isNaN(num) ? undefined : num;
    }
    // If already a number or undefined, keep as is
    return value;
  })
  @IsNumber()
  cityId?: number;

  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      const num = Number(value);
      return isNaN(num) ? undefined : num;
    }
    return value;
  })
  @IsNumber()
  areaId?: number;

  @IsOptional()
  @IsEnum(NotificationChannel)
  notificationChannel?: NotificationChannel;

  @IsOptional()
  @IsString()
  address?: string;
}

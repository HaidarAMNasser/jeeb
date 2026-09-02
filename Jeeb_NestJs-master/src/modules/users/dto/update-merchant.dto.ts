import {
  IsOptional,
  IsBoolean,
  IsString,
  IsNumber,
  IsEnum,
  IsEmail,
  MinLength,
  IsObject,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';

export class UpdateMerchantDto {
  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      const num = Number(value);
      return isNaN(num) ? undefined : num;
    }
    return value;
  })
  @IsNumber()
  currentLat?: number;

  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      const num = Number(value);
      return isNaN(num) ? undefined : num;
    }
    return value;
  })
  @IsNumber()
  currentLng?: number;
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
  @Transform((value) => {
    if (typeof value === 'string') {
      const num = Number(value);
      return isNaN(num) ? undefined : num;
    }
    return value;
  })
  @IsNumber()
  countryId?: number;

  @IsOptional()
  @Transform((value) => {
    if (typeof value === 'string') {
      const num = Number(value);
      return isNaN(num) ? undefined : num;
    }
    return value;
  })
  @IsNumber()
  cityId?: number;

  @IsOptional()
  @Transform((value) => {
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

  @IsOptional()
  @Transform(({ value }) => {
    if (!value) return undefined;

    if (typeof value === 'string') {
      try {
        const parsed = JSON.parse(value);
        if (
          parsed &&
          typeof parsed === 'object' &&
          'lat' in parsed &&
          'lng' in parsed
        ) {
          return {
            lat: parseFloat(parsed.lat),
            lng: parseFloat(parsed.lng),
          };
        }
      } catch (e) {
        // If parsing fails, throw a clear error about invalid JSON
        const { BadRequestException } = require('@nestjs/common');
        throw new BadRequestException(
          'location must be a valid JSON object string. Syntax error: ' +
            e.message,
        );
      }
      return undefined;
    }

    if (
      value &&
      typeof value === 'object' &&
      'lat' in value &&
      'lng' in value
    ) {
      return {
        lat: parseFloat(value.lat),
        lng: parseFloat(value.lng),
      };
    }

    return undefined;
  })
  @IsObject({ message: 'location must be a valid object with lat and lng' })
  location?: Record<string, any> | null;

  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      return value.toLowerCase() === 'true';
    }
    return value;
  })
  @IsBoolean()
  isActive?: any;

  @IsOptional()
  @IsString()
  restaurantName?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      return value.toLowerCase() === 'true';
    }
    return value;
  })
  @IsBoolean()
  isOpen?: any;

  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      return value.toLowerCase() === 'true';
    }
    return value;
  })
  @IsBoolean()
  hidePhoneNumber?: any;
}

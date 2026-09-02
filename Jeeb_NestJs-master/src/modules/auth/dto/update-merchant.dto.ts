import {
  IsString,
  MinLength,
  IsOptional,
  IsNumber,
  IsDate,
  IsBoolean,
  IsObject,
  IsEmail,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { BadRequestException } from '@nestjs/common';

export class UpdateMerchantDto {
  @IsString()
  @IsOptional()
  firstName?: string;

  @IsString()
  @IsOptional()
  lastName?: string;

  @IsString()
  @MinLength(6)
  @IsOptional()
  password?: string;

  @IsString()
  @IsOptional()
  phone?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  restaurantName?: string;

  @IsOptional()
  @IsNumber()
  countryId?: number;

  @IsOptional()
  @IsNumber()
  cityId?: number;

  @IsOptional()
  @IsNumber()
  areaId?: number;

  @IsOptional()
  @IsString()
  address?: string;

  @IsOptional()
  @Transform(({ value }) => (value ? new Date(value) : undefined))
  @IsDate()
  birthday?: Date;

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
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      try {
        const parsed = JSON.parse(value);
        if (typeof parsed === 'object' && parsed !== null) {
          return parsed;
        }
      } catch (e) {
        throw new BadRequestException(
          'location must be a valid JSON object string. Syntax error: ' +
            e.message,
        );
      }
      return undefined;
    }
    return value;
  })
  @IsObject()
  location?: { lat: number; lng: number };

  @IsOptional()
  @IsString()
  description?: string;
}

import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsString,
  IsOptional,
  IsNumber,
  IsDate,
  IsBoolean,
  IsObject,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';

export class CustomerCompleteRegistrationDto {
  @ApiPropertyOptional({
    description: 'البريد الإلكتروني (اختياري)',
    example: 'user@example.com',
    format: 'email',
  })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({
    description: 'معرف الدولة',
    example: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  countryId?: number;

  @ApiPropertyOptional({
    description: 'معرف المدينة',
    example: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  cityId?: number;

  @ApiPropertyOptional({
    description: 'العنوان',
    example: 'Damascus, Syria',
  })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({
    description: 'تاريخ الميلاد',
    example: '1990-01-01',
    format: 'date',
  })
  @IsOptional()
  @Transform(({ value }) => (value ? new Date(value) : undefined))
  @IsDate()
  birthday?: Date;

  @ApiPropertyOptional({
    description: 'الموقع الجغرافي',
    example: { lat: 33.5138, lng: 36.2765 },
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      try {
        const parsed = JSON.parse(value);
        return parsed;
      } catch {
        return value;
      }
    }
    return value;
  })
  @IsObject()
  location?: { lat: number; lng: number };

  @ApiPropertyOptional({
    description: 'حالة الاتصال',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  isOnline?: boolean;
}

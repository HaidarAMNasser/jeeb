import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsNotEmpty,
  IsString,
  MinLength,
  IsOptional,
  IsNumber,
  IsDate,
  IsObject,
  IsEnum,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { MerchantType } from '../../../common/enums/merchant-type.enum';

export class CreateMerchantDto {
  @ApiProperty({
    description: 'البريد الإلكتروني للتاجر (فريد)',
    example: 'merchant@example.com',
    format: 'email',
  })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({
    description: 'كلمة المرور (6 أحرف على الأقل)',
    example: 'password123',
    minLength: 6,
  })
  @IsString()
  @MinLength(6)
  @IsNotEmpty()
  password: string;

  @ApiProperty({
    description: 'الاسم الأول',
    example: 'Ahmed',
  })
  @IsString()
  @IsNotEmpty()
  firstName: string;

  @ApiProperty({
    description: 'اسم العائلة',
    example: 'Mohammed',
  })
  @IsString()
  @IsNotEmpty()
  lastName: string;

  @ApiProperty({
    description: 'رقم الهاتف مع كود الدولة (فريد)',
    example: '+966501234567',
  })
  @IsString()
  @IsNotEmpty()
  phone: string;

  @ApiPropertyOptional({
    description: 'اسم المطعم (لصاحب المطعم فقط)',
    example: 'مطعم الريان',
  })
  @IsOptional()
  @IsString()
  restaurantName?: string;

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
    description: 'معرف المنطقة',
    example: 1,
  })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  areaId?: number;

  @ApiPropertyOptional({
    description: 'العنوان',
    example: 'Riyadh, Saudi Arabia',
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
    description: 'الموقع الجغرافي (lat/lng)',
    example: '{"lat": 33.5138, "lng": 36.2765}',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      try {
        return JSON.parse(value);
      } catch (e) {
        return value;
      }
    }
    return value;
  })
  @IsObject()
  location?: { lat: number; lng: number };

  @ApiPropertyOptional({
    description: 'وصف المطعم',
    example: 'أشهى المأكولات الشرقية',
  })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: 'نوع التاجر',
    enum: MerchantType,
    example: MerchantType.RESTAURANT,
  })
  @IsOptional()
  @IsEnum(MerchantType)
  type?: MerchantType;

  // Role is automatically assigned as MERCHANT
  // No need to pass it in payload
}

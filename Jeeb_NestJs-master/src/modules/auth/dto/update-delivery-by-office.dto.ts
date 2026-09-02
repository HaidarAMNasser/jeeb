import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsString,
  MinLength,
  IsOptional,
  IsEnum,
  IsNumber,
} from 'class-validator';
import { Type } from 'class-transformer';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';

export class LocationDto {
  @ApiPropertyOptional({ description: 'خط العرض', example: 33.5138 })
  @IsNumber()
  lat?: number;

  @ApiPropertyOptional({ description: 'خط الطول', example: 36.2765 })
  @IsNumber()
  lng?: number;
}

export class UpdateDeliveryByOfficeDto {
  @ApiPropertyOptional({
    description: 'البريد الإلكتروني (فريد)',
    example: 'delivery1@example.com',
    format: 'email',
  })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({
    description: 'كلمة المرور (6 أحرف على الأقل)',
    example: 'newPassword123',
    minLength: 6,
  })
  @IsOptional()
  @IsString()
  @MinLength(6)
  password?: string;

  @ApiPropertyOptional({
    description: 'الاسم الأول',
    example: 'Ahmed Updated',
  })
  @IsOptional()
  @IsString()
  firstName?: string;

  @ApiPropertyOptional({
    description: 'اسم العائلة',
    example: 'Ali Updated',
  })
  @IsOptional()
  @IsString()
  lastName?: string;

  @ApiPropertyOptional({
    description: 'رقم الهاتف (فريد)',
    example: '+966509876543',
  })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({
    description: 'معرف الدولة',
    example: 1,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  countryId?: number;

  @ApiPropertyOptional({
    description: 'معرف المدينة',
    example: 1,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  cityId?: number;

  @ApiPropertyOptional({
    description: 'معرف المنطقة',
    example: 1,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  areaId?: number;

  @ApiPropertyOptional({
    description: 'العنوان',
    example: 'New Address',
  })
  @IsOptional()
  @IsString()
  address?: string;

  @ApiPropertyOptional({
    description: 'قناة الإشعارات',
    enum: NotificationChannel,
    example: NotificationChannel.WHATSAPP,
  })
  @IsOptional()
  @IsEnum(NotificationChannel)
  notificationChannel?: NotificationChannel;

  @ApiPropertyOptional({
    description: 'تاريخ الميلاد',
    example: '1990-05-15',
    nullable: true,
  })
  @IsOptional()
  birthday?: any;

  @ApiPropertyOptional({
    description: 'حالة التفعيل (للإدارة)',
    example: false,
  })
  @IsOptional()
  @IsString()
  isActive?: any;

  @ApiPropertyOptional({
    description: 'حالة الاتصال (متصل/غير متصل)',
    example: true,
  })
  @IsOptional()
  @IsString()
  isOnline?: any;

  @ApiPropertyOptional({
    description: 'الموقع الجغرافي',
    example: { lat: 33.5138, lng: 36.2765 },
  })
  @IsOptional()
  location?: LocationDto | string;
}

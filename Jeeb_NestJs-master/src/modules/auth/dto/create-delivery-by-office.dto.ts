import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
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

export class CreateDeliveryByOfficeDto {
  @ApiProperty({
    description: 'البريد الإلكتروني (فريد)',
    example: 'delivery1@example.com',
    format: 'email',
  })
  @IsEmail()
  email: string;

  @ApiProperty({
    description: 'كلمة المرور (6 أحرف على الأقل)',
    example: 'strongPassword123',
    minLength: 6,
  })
  @IsString()
  @MinLength(6)
  password: string;

  @ApiProperty({
    description: 'الاسم الأول',
    example: 'Ahmed',
  })
  @IsString()
  firstName: string;

  @ApiProperty({
    description: 'اسم العائلة',
    example: 'Ali',
  })
  @IsString()
  lastName: string;

  @ApiProperty({
    description: 'رقم الهاتف (فريد)',
    example: '+966501234567',
  })
  @IsString()
  phone: string;

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
    description: 'العنوان',
    example: 'Riyadh, Saudi Arabia',
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
    format: 'date',
  })
  @IsOptional()
  @IsString()
  birthday?: string;

  @ApiPropertyOptional({
    description: 'معرف صاحب المكتب (اختياري - يمكن إنشاء ديلفري بدون تعيين)',
    example: 5,
  })
  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  officeOwnerId?: number;

  @ApiPropertyOptional({
    description: 'الموقع الجغرافي',
    example: { lat: 33.5138, lng: 36.2765 },
  })
  @IsOptional()
  location?: LocationDto | string;
}

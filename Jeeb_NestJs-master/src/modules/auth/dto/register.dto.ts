import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEmail,
  IsNotEmpty,
  IsString,
  MinLength,
  IsOptional,
  IsNumber,
  IsEnum,
  IsDate,
  IsBoolean,
  IsObject,
  Matches,
  ValidateIf,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { normalizePhone } from '../../../common/utils/phone.util';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { UserRole } from '../../../common/enums/user-role.enum';
import { MerchantType } from '../../../common/enums/merchant-type.enum';

export class RegisterDto {
  @ApiProperty({
    description: 'البريد الإلكتروني',
    example: 'user@example.com',
    format: 'email',
  })
  @IsEmail()
  email: string;

  @ApiProperty({
    description: 'كلمة المرور',
    example: 'password123',
    minLength: 6,
  })
  @IsString()
  @MinLength(6)
  password: string;

  @ApiProperty({
    description: 'الاسم الأول',
    example: 'John',
  })
  @IsString()
  @IsNotEmpty()
  firstName: string;

  @ApiProperty({
    description: 'اسم العائلة',
    example: 'Doe',
  })
  @IsString()
  @IsNotEmpty()
  lastName: string;

  @ApiProperty({
    description: 'رقم الهاتف',
    example: '+963912345678',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^(\+?[1-9]\d{6,14}|0\d{7,13})$/, {
    message: 'phone must be a valid phone number (e.g. +963912345678 or 0912345678)',
  })
  @Transform(({ value }) => normalizePhone(value))
  phone: string;

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
    description: 'قناة الإشعارات',
    enum: NotificationChannel,
    example: NotificationChannel.SMS,
  })
  @IsOptional()
  @IsEnum(NotificationChannel)
  notificationChannel?: NotificationChannel;

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
    description: 'دور المستخدم',
    enum: UserRole,
    example: UserRole.CUSTOMER,
  })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;

  @ApiPropertyOptional({
    description: 'حالة الاتصال',
    example: true,
  })
  @IsOptional()
  @IsBoolean()
  isOnline?: boolean;

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
    description: 'اسم المطعم (فقط للتاجر)',
    example: 'مطعم البرغر اللذيذ',
  })
  @ValidateIf((o) => o.role === UserRole.MERCHANT)
  @IsOptional()
  @IsString()
  restaurantName?: string;

  @ApiPropertyOptional({
    description: 'وصف المطعم (فقط للتاجر)',
    example: 'أشهى المأكولات الشرقية',
  })
  @ValidateIf((o) => o.role === UserRole.MERCHANT)
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({
    description: 'حالة فتح المحل (فقط للتاجر) - true مفتوح، false مغلق',
    example: true,
  })
  @ValidateIf((o) => o.role === UserRole.MERCHANT)
  @IsOptional()
  @Transform(({ value }) => {
    if (value === 'true' || value === true) return true;
    if (value === 'false' || value === false) return false;
    return undefined;
  })
  @IsBoolean()
  isOpen?: boolean;

  @ApiPropertyOptional({
    description: 'نوع التاجر (فقط للتاجر)',
    enum: MerchantType,
    example: MerchantType.RESTAURANT,
  })
  @ValidateIf((o) => o.role === UserRole.MERCHANT)
  @IsOptional()
  @IsEnum(MerchantType)
  type?: MerchantType;
}

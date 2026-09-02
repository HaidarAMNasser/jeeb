import { IsEmail, IsNotEmpty, IsOptional, IsString, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { normalizePhone } from '../../../common/utils/phone.util';

export class ResendOtpDto {
  @ApiPropertyOptional({
    description: 'البريد الإلكتروني',
    example: 'user@example.com',
    format: 'email',
  })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({
    description: 'رقم الهاتف',
    example: '+963900000001',
  })
  @IsOptional()
  @IsString()
  @Matches(/^(\+?[1-9]\d{6,14}|0\d{7,13})$/, {
    message: 'phone must be a valid phone number (e.g. +963912345678 or 0912345678)',
  })
  @Transform(({ value }) => (value ? normalizePhone(value) : value))
  phone?: string;
}

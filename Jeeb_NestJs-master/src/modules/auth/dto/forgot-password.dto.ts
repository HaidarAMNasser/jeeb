import { IsEmail, IsNotEmpty, IsOptional, IsString, Matches, ValidateIf } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { normalizePhone } from '../../../common/utils/phone.util';

export class ForgotPasswordDto {
  @ApiPropertyOptional({
    description: 'البريد الإلكتروني (يجب تقديم email أو phone)',
    example: 'user@example.com',
  })
  @ValidateIf((o: ForgotPasswordDto) => !o.phone)
  @IsEmail()
  @IsNotEmpty()
  email?: string;

  @ApiPropertyOptional({
    description: 'رقم الهاتف (يجب تقديم email أو phone)',
    example: '+963900000001',
  })
  @ValidateIf((o: ForgotPasswordDto) => !o.email)
  @IsString()
  @IsNotEmpty()
  @Matches(/^(\+?[1-9]\d{6,14}|0\d{7,13})$/, {
    message: 'phone must be a valid phone number (e.g. +963912345678 or 0912345678)',
  })
  @Transform(({ value }) => (value ? normalizePhone(value) : value))
  phone?: string;
}

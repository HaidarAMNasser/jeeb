import { ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  ValidateIf,
  Matches,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { normalizePhone } from '../../../common/utils/phone.util';

export class LoginDto {
  @ApiProperty({
    description: 'البريد الإلكتروني (يجب تقديم email أو phone)',
    example: 'user@example.com',
    required: false,
  })
  @ValidateIf((o: LoginDto) => !o.phone)
  @IsEmail({}, { message: 'يجب أن يكون البريد الإلكتروني صالحاً' })
  email?: string;

  @ApiProperty({
    description: 'رقم الهاتف (يجب تقديم email أو phone)',
    example: '966501234567',
    required: false,
  })
  @ValidateIf((o: LoginDto) => !o.email)
  @IsString()
  @Matches(/^(\+?[1-9]\d{6,14}|0\d{7,13})$/, {
    message: 'phone must be a valid phone number (e.g. +963912345678 or 0912345678)',
  })
  @Transform(({ value }) => (value ? normalizePhone(value) : value))
  phone?: string;

  @ApiProperty({
    description: 'كلمة المرور',
    example: 'password123',
    minLength: 6,
  })
  @IsString()
  @IsNotEmpty()
  password: string;

  @ApiProperty({
    description: 'Firebase Token للتحديث',
    example: 'firebase_token_here',
    required: false,
  })
  @IsOptional()
  @IsString()
  firebaseToken?: string;
}

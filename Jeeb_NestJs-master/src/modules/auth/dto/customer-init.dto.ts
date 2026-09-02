import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Matches, MinLength } from 'class-validator';
import { Transform } from 'class-transformer';
import { normalizePhone } from '../../../common/utils/phone.util';

export class CustomerInitDto {
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
    description: 'كلمة المرور',
    example: 'password123',
    minLength: 6,
  })
  @IsString()
  @MinLength(6)
  password: string;
}

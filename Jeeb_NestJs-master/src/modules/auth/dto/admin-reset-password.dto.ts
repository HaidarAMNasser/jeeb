import { IsString, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AdminResetPasswordDto {
  @ApiProperty({
    description: 'كلمة المرور الجديدة',
    example: 'newStrongPassword123',
    minLength: 6,
  })
  @IsString()
  @MinLength(6)
  password: string;
}

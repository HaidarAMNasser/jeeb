import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class GuestLoginDto {
  @ApiProperty({
    example: 'eyJhbGciOiJSUzI1...',
    description: 'Firebase Anonymous Authentication Token (ignored — kept for backward compatibility)',
    required: false,
  })
  @IsOptional()
  @IsString()
  firebaseToken?: string;
}

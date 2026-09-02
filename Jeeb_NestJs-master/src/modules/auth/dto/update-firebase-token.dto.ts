import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsOptional, ValidateIf } from 'class-validator';

export class UpdateFirebaseTokenDto {
  @ApiProperty({
    description: 'FCM device token used for push notifications',
    example: 'fcm_device_token_here',
    required: false,
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'firebaseToken cannot be empty' })
  @ValidateIf((o) => !o.token)
  firebaseToken?: string;

  @ApiProperty({
    description: 'Alternative FCM device token',
    example: 'fcm_device_token_here',
    required: false,
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'token cannot be empty' })
  @ValidateIf((o) => !o.firebaseToken)
  token?: string;
}

import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsNotEmpty, IsOptional } from 'class-validator';

export class UpdateDriverLocationDto {
  @ApiProperty({ example: 123, description: 'Order ID' })
  @IsNumber()
  @IsNotEmpty()
  orderId: number;

  @ApiProperty({
    example: 33.5138,
    description: 'Driver latitude',
  })
  @IsNumber()
  @IsNotEmpty()
  lat: number;

  @ApiProperty({
    example: 36.2765,
    description: 'Driver longitude',
  })
  @IsNumber()
  @IsNotEmpty()
  lng: number;

  @ApiProperty({
    example: 1700000000000,
    description: 'Timestamp of location update',
  })
  @IsNumber()
  @IsNotEmpty()
  timestamp: number;

  @ApiProperty({
    example: 30,
    description: 'Speed in km/h',
  })
  @IsNumber()
  @IsOptional()
  speed?: number;
}

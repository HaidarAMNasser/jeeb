import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreateAreaDto {
  @ApiProperty({
    description: 'Area name',
    example: 'Downtown',
  })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({
    description: 'Area delivery price',
    example: 5000,
    minimum: 0,
  })
  @IsNumber()
  @Min(0)
  price: number;

  @ApiPropertyOptional({
    description: 'Area description',
    example: 'Central business district delivery zone',
  })
  @IsOptional()
  @IsString()
  description?: string;
}

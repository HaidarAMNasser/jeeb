import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsOptional,
  IsPositive,
  IsString,
  IsDateString,
  IsInt,
  Min,
} from 'class-validator';
import { Transform } from 'class-transformer';

function transformToNumber({ value }: { value: any }): number | undefined {
  if (value === '' || value === null || value === undefined) return undefined;
  if (typeof value === 'number') return value;
  const num = Number(value);
  return isNaN(num) ? undefined : num;
}

export class MerchantStatsQueryDto {
  @ApiPropertyOptional({ description: 'رقم الصفحة', example: 1 })
  @IsOptional()
  @Transform(transformToNumber)
  @IsPositive()
  page: number = 1;

  @ApiPropertyOptional({ description: 'عدد العناصر في الصفحة', example: 10 })
  @IsOptional()
  @Transform(transformToNumber)
  @IsPositive()
  limit: number = 10;

  @ApiPropertyOptional({
    description: 'بحث (اسم المطعم، الاسم الأول، اسم العائلة)',
    example: 'burger',
  })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({
    description: 'بداية التاريخ (ISO 8601)',
    example: '2026-01-01',
  })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({
    description: 'نهاية التاريخ (ISO 8601)',
    example: '2026-06-08',
  })
  @IsOptional()
  @IsDateString()
  to?: string;

  @ApiPropertyOptional({ description: 'معرف التاجر (userId)', example: 27 })
  @IsOptional()
  @Transform(transformToNumber)
  @IsInt()
  @Min(1)
  merchantId?: number;
}

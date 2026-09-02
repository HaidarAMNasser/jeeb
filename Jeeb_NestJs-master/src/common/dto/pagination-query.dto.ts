import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsPositive } from 'class-validator';
import { Transform } from 'class-transformer';

function transformToNumber({ value }: any): number | undefined {
  if (value === '' || value === null || value === undefined) return undefined;
  if (typeof value === 'number') return value;
  const num = Number(value);
  return isNaN(num) ? undefined : num;
}

function transformToString({ value }: any): string | undefined {
  if (value === '' || value === null || value === undefined) return undefined;
  if (typeof value === 'string') return value;
  return String(value);
}

export class PaginationQueryDto {
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

  @ApiPropertyOptional({ description: 'بحث', example: '' })
  @IsOptional()
  search?: string;

  @ApiPropertyOptional({ description: 'معرف التصنيف', example: 1 })
  @IsOptional()
  @Transform(transformToNumber)
  @IsPositive()
  categoryId?: number;
}

import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, Min } from 'class-validator';
import { Transform } from 'class-transformer';
import { PaginationQueryDto } from '../../../common/dto/pagination-query.dto';

function transformToNumber({ value }: { value: unknown }): number | undefined {
  if (value === '' || value === null || value === undefined) return undefined;
  if (typeof value === 'number') return value;
  const num = Number(value);
  return isNaN(num) ? undefined : num;
}

export class GetAreasQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    description: 'Minimum price filter',
    example: 1000,
  })
  @IsOptional()
  @Transform(transformToNumber)
  @Min(0)
  min_price?: number;

  @ApiPropertyOptional({
    description: 'Maximum price filter',
    example: 10000,
  })
  @IsOptional()
  @Transform(transformToNumber)
  @Min(0)
  max_price?: number;
}

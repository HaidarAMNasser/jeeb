import { IsOptional, Min, IsNumber } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationQueryDto } from '../../../common/dto/pagination-query.dto';

function transformToNumber({ value }: any): number | undefined {
  if (value === '' || value === null || value === undefined) return undefined;
  if (typeof value === 'number') return value;
  const num = Number(value);
  return isNaN(num) ? undefined : num;
}

export class GetProductsQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({
    description: 'الحد الأدنى للسعر',
    example: 10,
  })
  @IsOptional()
  @Transform(transformToNumber)
  @Min(0)
  minPrice?: number;

  @ApiPropertyOptional({
    description: 'الحد الأعلى للسعر',
    example: 100,
  })
  @IsOptional()
  @Transform(transformToNumber)
  @Min(0)
  maxPrice?: number;

  @ApiPropertyOptional({
    description: 'الحد الأدنى للتقييم',
    example: 3,
  })
  @IsOptional()
  @Transform(transformToNumber)
  @Min(1)
  minRating?: number;

  @ApiPropertyOptional({
    description: 'فلتر حسب معرف التاجر (متاح لجميع المستخدمين)',
    example: 1,
  })
  @IsOptional()
  @Transform(transformToNumber)
  @IsNumber()
  merchantId?: number;
}

import { IsOptional, IsString } from 'class-validator';
import { Transform } from 'class-transformer';
import { PaginationQueryDto } from '../../../common/dto/pagination-query.dto';

export class GetCategoriesQueryDto extends PaginationQueryDto {
  @IsOptional()
  @Transform(({ value }) => {
    if (value === 'true' || value === true) return 'true';
    if (value === 'false' || value === false) return 'false';
    return undefined;
  })
  @IsString()
  isActive?: string; // 'true' or 'false'
}

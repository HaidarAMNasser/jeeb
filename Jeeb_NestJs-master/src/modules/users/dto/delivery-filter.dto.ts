import { IsOptional, IsNumber } from 'class-validator';
import { PaginationQueryDto } from '../../../common/dto/pagination-query.dto';

export class DeliveryFilterDto extends PaginationQueryDto {
  @IsOptional()
  @IsNumber()
  countryId?: number;

  @IsOptional()
  @IsNumber()
  cityId?: number;
}

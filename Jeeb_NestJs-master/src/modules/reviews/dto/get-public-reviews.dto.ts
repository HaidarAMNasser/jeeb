import { IsEnum, IsInt, IsNotEmpty } from 'class-validator';
import { Type } from 'class-transformer';
import { ReviewTargetType } from '../../../common/enums/review-target-type.enum';
import { PaginationQueryDto } from '../../../common/dto/pagination-query.dto';

export class GetPublicReviewsDto extends PaginationQueryDto {
  @IsEnum(ReviewTargetType)
  @IsNotEmpty()
  type: ReviewTargetType;

  @IsInt()
  @Type(() => Number)
  @IsNotEmpty()
  id: number;
}

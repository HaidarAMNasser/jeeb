import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { ReviewEntityType } from '../../../common/enums/review-entity-type.enum';

export class CreateReviewDto {
  // @ApiProperty({ description: 'Type of entity being reviewed', enum: ReviewEntityType })
  @IsEnum(ReviewEntityType)
  @IsNotEmpty()
  entityType: ReviewEntityType;

  // @ApiProperty({ description: 'ID of the entity (Order or Product)', example: 1 })
  @IsInt({ message: 'Entity ID must be an integer' })
  @IsNotEmpty()
  entityId: number;

  // @ApiProperty({ description: 'Rating score from 1 to 5', example: 5, minimum: 1, maximum: 5 })
  @IsInt({ message: 'Rating must be an integer number' })
  @Min(1, { message: 'Rating must not be less than 1' })
  @Max(5, { message: 'Rating must not be greater than 5' })
  @IsNotEmpty()
  rating: number;

  // @ApiPropertyOptional({ description: 'Optional comment about the experience', example: 'The delivery was very fast and the food was hot.' })
  @IsString()
  @IsOptional()
  @MaxLength(500, { message: 'Comment is too long (max 500 characters)' })
  comment?: string;
}

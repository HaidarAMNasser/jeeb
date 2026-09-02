import { Transform, plainToInstance } from 'class-transformer';
import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsArray,
  ArrayMinSize,
  IsDateString,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { DiscountType } from '../../../common/enums';
import { OfferProductDto } from './offer-product.dto';

export class CreateOfferDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsEnum(DiscountType)
  @IsNotEmpty()
  discountType: DiscountType;

  @Transform(({ value }) => {
    if (typeof value === 'string') return parseFloat(value);
    return value;
  })
  @IsNumber()
  @IsNotEmpty()
  @Min(0)
  discountValue: number;

  @IsDateString()
  @IsOptional()
  startDate?: string;

  @IsDateString()
  @IsOptional()
  endDate?: string;

  @Transform(({ value }) => {
    if (value === 'true') return true;
    if (value === 'false') return false;
    return value;
  })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @Transform(({ value, obj }) => {
    if (value && Array.isArray(value) && value.length > 0) {
      obj.products = value.map((id: number) => ({
        productId: id,
        quantity: 1,
        isActive: true,
      }));
    }
    return value;
  })
  @IsOptional()
  productIds?: number[];

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OfferProductDto)
  @ArrayMinSize(1)
  products?: OfferProductDto[];
}

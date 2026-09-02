import { PartialType } from '@nestjs/mapped-types';
import { CreateOfferDto } from './create-offer.dto';
import {
  IsArray,
  IsNumber,
  IsOptional,
  ValidateNested,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';

export class ProductQuantityDto {
  @IsNumber()
  productId: number;

  @IsNumber()
  @IsOptional()
  quantity?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}

export class UpdateOfferDto extends PartialType(CreateOfferDto) {
  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => ProductQuantityDto)
  products?: ProductQuantityDto[];

  @IsArray()
  @IsOptional()
  @IsNumber({}, { each: true })
  removeProductIds?: number[];
}

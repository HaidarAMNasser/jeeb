import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  ValidateNested,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CartItemDto {
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  productId: number;

  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  quantity: number;
}

export class CartOfferDto {
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  offerId: number;

  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  quantity: number;
}

export class CreateCartDto {
  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => CartItemDto)
  items?: CartItemDto[];

  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => CartOfferDto)
  offers?: CartOfferDto[];
}

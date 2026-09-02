import {
  IsArray,
  IsNumber,
  IsOptional,
  ValidateNested,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CartItemDto {
  @IsNumber()
  @IsOptional()
  @Min(1)
  productId: number;

  @IsNumber()
  @IsOptional()
  @Min(1)
  quantity: number;
}

export class CartOfferDto {
  @IsNumber()
  @IsOptional()
  @Min(1)
  offerId: number;

  @IsNumber()
  @IsOptional()
  @Min(1)
  quantity: number;
}

export class CartItemInputDto {
  @IsNumber()
  @IsOptional()
  @Min(1)
  productId: number;

  @IsNumber()
  @IsOptional()
  @Min(1)
  quantity: number;
}

export class CartOfferInputDto {
  @IsNumber()
  @IsOptional()
  @Min(1)
  offerId: number;

  @IsNumber()
  @IsOptional()
  @Min(1)
  quantity: number;
}

export class AddToCartDto {
  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => CartItemInputDto)
  items?: CartItemInputDto[];

  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => CartOfferInputDto)
  offers?: CartOfferInputDto[];
}

export class UpdateCartDto {
  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => CartItemInputDto)
  items?: CartItemInputDto[];

  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => CartOfferInputDto)
  offers?: CartOfferInputDto[];
}

export class RemoveFromCartDto {
  @IsArray()
  @IsOptional()
  @IsNumber({}, { each: true })
  items?: number[];

  @IsArray()
  @IsOptional()
  @IsNumber({}, { each: true })
  offers?: number[];
}

export class UpdateCartActionsDto {
  @ValidateNested()
  @IsOptional()
  @Type(() => AddToCartDto)
  add?: AddToCartDto;

  @ValidateNested()
  @IsOptional()
  @Type(() => UpdateCartDto)
  update?: UpdateCartDto;

  @ValidateNested()
  @IsOptional()
  @Type(() => RemoveFromCartDto)
  remove?: RemoveFromCartDto;
}

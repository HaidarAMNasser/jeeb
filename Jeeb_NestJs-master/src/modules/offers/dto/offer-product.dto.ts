import { IsInt, IsNotEmpty, IsOptional, IsBoolean, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class OfferProductDto {
  @IsInt()
  @IsNotEmpty()
  productId: number;

  @IsInt()
  @IsOptional()
  @Min(1)
  @Type(() => Number)
  quantity?: number = 1;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean = true;
}

export class AddProductsToOfferDto {
  @IsNotEmpty()
  products: OfferProductDto[];
}

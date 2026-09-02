import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  ValidateNested,
  IsNumber,
  Min,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateOrderItemByProductDto {
  @ApiProperty({ description: 'معرف المنتج', example: 1 })
  @IsNumber()
  productId: number;

  @ApiProperty({ description: 'الكمية', example: 3 })
  @IsNumber()
  @Min(0)
  quantity: number;
}

export class UpdateOrderItemByIdDto {
  @ApiProperty({ description: 'معرف العنصر', example: 1 })
  @IsNumber()
  id: number;

  @ApiProperty({ description: 'الكمية', example: 2 })
  @IsNumber()
  @Min(0)
  quantity: number;
}

export class UpdateOfferByOfferIdDto {
  @ApiProperty({ description: 'معرف العرض', example: 1 })
  @IsNumber()
  offerId: number;

  @ApiProperty({ description: 'الكمية', example: 1 })
  @IsNumber()
  @Min(0)
  quantity: number;
}

export class UpdateOfferByIdDto {
  @ApiProperty({ description: 'معرف عنصر العرض', example: 1 })
  @IsNumber()
  id: number;

  @ApiProperty({ description: 'الكمية', example: 2 })
  @IsNumber()
  @Min(0)
  quantity: number;
}

export class UpdateOrderDto {
  @ApiPropertyOptional({
    description: 'تحديث المنتجات بواسطة productId',
    type: UpdateOrderItemByProductDto,
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdateOrderItemByProductDto)
  itemsByProductId?: UpdateOrderItemByProductDto[];

  @ApiPropertyOptional({
    description: 'تحديث المنتجات بواسطة id',
    type: UpdateOrderItemByIdDto,
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdateOrderItemByIdDto)
  itemsById?: UpdateOrderItemByIdDto[];

  @ApiPropertyOptional({
    description: 'تحديث العروض بواسطة offerId',
    type: UpdateOfferByOfferIdDto,
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdateOfferByOfferIdDto)
  offersByOfferId?: UpdateOfferByOfferIdDto[];

  @ApiPropertyOptional({
    description: 'تحديث العروض بواسطة id',
    type: UpdateOfferByIdDto,
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdateOfferByIdDto)
  offersById?: UpdateOfferByIdDto[];

  @ApiPropertyOptional({
    description: 'معرفات المنتجات المحذوفة',
    example: [1, 2],
  })
  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  deletedProducts?: number[];

  @ApiPropertyOptional({
    description: 'معرفات العروض المحذوفة',
    example: [3],
  })
  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  deletedOffers?: number[];

  @ApiPropertyOptional({ description: 'اسم الزبون', example: 'أحمد محمد' })
  @IsString()
  @IsOptional()
  @MaxLength(100)
  customerName?: string;

  @ApiPropertyOptional({ description: 'رقم الهاتف', example: '+963912345678' })
  @IsString()
  @IsOptional()
  @MaxLength(20)
  phone?: string;
}

export class UpdateOrderItemsDto {
  @ApiPropertyOptional({
    description: 'المنتجات المطلوب تحديثها',
    type: UpdateOrderItemByProductDto,
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdateOrderItemByProductDto)
  items?: UpdateOrderItemByProductDto[];

  @ApiPropertyOptional({
    description: 'المنتجات المطلوب تحديثها بواسطة id',
    type: UpdateOrderItemByIdDto,
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdateOrderItemByIdDto)
  itemsById?: UpdateOrderItemByIdDto[];

  @ApiPropertyOptional({
    description: 'العروض المطلوب تحديثها',
    type: UpdateOfferByOfferIdDto,
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdateOfferByOfferIdDto)
  offers?: UpdateOfferByOfferIdDto[];

  @ApiPropertyOptional({
    description: 'العروض المطلوب تحديثها بواسطة id',
    type: UpdateOfferByIdDto,
    isArray: true,
  })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdateOfferByIdDto)
  offersById?: UpdateOfferByIdDto[];

  @ApiPropertyOptional({
    description: 'معرفات المنتجات المحذوفة',
    example: [1, 2],
  })
  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  deletedProducts?: number[];

  @ApiPropertyOptional({
    description: 'معرفات العروض المحذوفة',
    example: [3],
  })
  @IsOptional()
  @IsArray()
  @IsNumber({}, { each: true })
  deletedOffers?: number[];
}

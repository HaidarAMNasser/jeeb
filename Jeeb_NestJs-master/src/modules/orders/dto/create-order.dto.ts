import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsEnum,
  ValidateNested,
  IsLatitude,
  IsLongitude,
  Min,
  MaxLength,
  IsBoolean,
} from 'class-validator';
import { Type } from 'class-transformer';
import { PaymentMethod } from '../../../common/enums/payment.enum';

class OrderItemDto {
  @ApiProperty({ description: 'معرف المنتج', example: 1 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  productId: number;

  @ApiProperty({ description: 'الكمية', example: 2 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  quantity: number;
}

class DeliveryCoordinatesDto {
  @ApiProperty({ description: 'خط العرض', example: 33.5138 })
  @IsLatitude()
  latitude: number;

  @ApiProperty({ description: 'خط الطول', example: 36.2767 })
  @IsLongitude()
  longitude: number;

  @ApiPropertyOptional({ description: 'العنوان', example: 'شارع الملك فيصل' })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  address?: string;

  @ApiPropertyOptional({ description: 'معلم قريب', example: 'بجانب المستشفى' })
  @IsString()
  @IsOptional()
  @MaxLength(200)
  landmark?: string;

  @ApiPropertyOptional({
    description: 'تعليمات خاصة',
    example: 'اتصل قبل الوصول',
  })
  @IsString()
  @IsOptional()
  @MaxLength(1000)
  specialInstructions?: string;
}

export class SimpleOfferItemDto {
  @ApiProperty({ description: 'معرف العرض', example: 1 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  offerId: number;

  @ApiProperty({ description: 'الكمية', example: 1 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  quantity: number;
}

export class CreateOrderDto {
  @ApiProperty({ description: 'معرف التاجر', example: 1 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  ownerId: number;

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

  @ApiPropertyOptional({
    description: 'المنتجات المطلوبة',
    type: OrderItemDto,
    isArray: true,
  })
  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items?: OrderItemDto[];

  @ApiPropertyOptional({
    description: 'العروض المطلوبة',
    type: SimpleOfferItemDto,
    isArray: true,
  })
  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => SimpleOfferItemDto)
  offers?: SimpleOfferItemDto[];

  @ApiProperty({
    description: 'إحداثيات التوصيل',
    type: DeliveryCoordinatesDto,
  })
  @ValidateNested()
  @Type(() => DeliveryCoordinatesDto)
  deliveryCoordinates: DeliveryCoordinatesDto;

  @ApiPropertyOptional({ description: 'مبلغ الإكرامية', example: 5000 })
  @IsNumber()
  @IsOptional()
  @Min(0)
  tipAmount?: number;

  @ApiPropertyOptional({ description: 'معرف المدينة', example: 1 })
  @IsNumber()
  @IsOptional()
  @Min(1)
  cityId?: number;

  @ApiProperty({ description: 'معرف المنطقة', example: 1 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  areaId: number;

  @ApiProperty({
    description: 'طريقة الدفع',
    enum: PaymentMethod,
    example: PaymentMethod.CASH,
  })
  @IsEnum(PaymentMethod)
  @IsNotEmpty()
  paymentMethod: PaymentMethod;
}

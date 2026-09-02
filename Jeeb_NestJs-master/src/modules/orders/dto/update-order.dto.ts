import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { OrderStatus } from '../../../common/enums/order-status.enum';

export class FinalLocationDto {
  @ApiProperty({ description: 'خط العرض', example: 33.5138 })
  @IsNumber()
  lat: number;

  @ApiProperty({ description: 'خط الطول', example: 36.2767 })
  @IsNumber()
  lng: number;
}

export class UpdateOrderStatusDto {
  @ApiPropertyOptional({
    description: 'الحالة الجديدة',
    enum: OrderStatus,
  })
  @IsEnum(OrderStatus)
  @IsOptional()
  status?: OrderStatus;

  @ApiPropertyOptional({
    description: 'سبب التغيير',
    example: 'تأخير من الزبون',
  })
  @IsString()
  @IsOptional()
  reason?: string;

  @ApiPropertyOptional({
    description: 'الموقع النهائي للتوصيل',
    type: FinalLocationDto,
  })
  @ValidateNested()
  @Type(() => FinalLocationDto)
  @IsOptional()
  finalLocation?: FinalLocationDto;

  @ApiPropertyOptional({ description: 'وقت التحضير (بالدقائق)', example: 20 })
  @IsNumber()
  @IsOptional()
  mealPreparationTime?: number;

  @ApiPropertyOptional({ description: 'وقت التوصيل (بالدقائق)', example: 30 })
  @IsNumber()
  @IsOptional()
  deliveryTime?: number;
}

export class CancelOrderDto {
  @ApiPropertyOptional({
    description: 'سبب الإلغاء',
    example: 'الزبون ألغى الطلب',
  })
  @IsString()
  @IsOptional()
  reason?: string;
}

export class UpdateDeliveryCoordinatesDto {
  @ApiProperty({ description: 'خط العرض', example: 33.5138 })
  @IsNumber()
  latitude: number;

  @ApiProperty({ description: 'خط الطول', example: 36.2767 })
  @IsNumber()
  longitude: number;

  @ApiPropertyOptional({ description: 'العنوان', example: 'شارع الثورة' })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiPropertyOptional({ description: 'معلم قريب', example: 'قرب المول' })
  @IsString()
  @IsOptional()
  landmark?: string;

  @ApiPropertyOptional({
    description: 'تعليمات خاصة',
    example: 'اتصل قبل الوصول',
  })
  @IsString()
  @IsOptional()
  specialInstructions?: string;
}

export class UpdateOrderTipDto {
  @ApiProperty({ description: 'مبلغ الإكرامية', example: 5000 })
  @IsNumber()
  @Min(0)
  tipAmount: number;
}

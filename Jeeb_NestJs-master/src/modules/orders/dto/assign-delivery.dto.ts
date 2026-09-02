import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNumber,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
  MaxLength,
} from 'class-validator';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';

export class AssignDeliveryDto {
  @ApiProperty({ description: 'معرف الطلب', example: 1 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  orderId: number;

  @ApiProperty({ description: 'معرف المندوب', example: 5 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  deliveryId: number;
}

export class AcceptDeliveryDto {
  @ApiProperty({ description: 'معرف الطلب', example: 1 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  orderId: number;

  @ApiProperty({ description: 'معرف المندوب', example: 5 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  deliveryId: number;

  @ApiPropertyOptional({ description: 'وقت التوصيل (بالدقائق)', example: 25 })
  @IsNumber()
  @IsOptional()
  @Min(1)
  deliveryTime?: number;
}

export class RejectDeliveryDto {
  @ApiProperty({ description: 'معرف الطلب', example: 1 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  orderId: number;

  @ApiProperty({ description: 'معرف المندوب', example: 5 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  deliveryId: number;

  @ApiPropertyOptional({ description: 'سبب الرفض', example: 'الطلب بعيد جداً' })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  reason?: string;
}

export class UpdateDeliveryStatusDto {
  @ApiProperty({ description: 'معرف التعيين', example: 1 })
  @IsNumber()
  @IsNotEmpty()
  @Min(1)
  assignmentId: number;

  @ApiProperty({
    description: 'حالة التوصيل',
    enum: DeliveryStatus,
  })
  @IsNotEmpty()
  status: DeliveryStatus;

  @ApiPropertyOptional({ description: 'ملاحظات', example: 'تم التوصيل بنجاح' })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  reason?: string;
}

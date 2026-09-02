import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsOptional,
  IsNumber,
  IsDateString,
  IsPositive,
  IsString,
  ValidateIf,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { PaginationQueryDto } from '../../../common/dto/pagination-query.dto';
import { OrderStatus } from '../../../common/enums/order-status.enum';

const STATUS_MAP: Record<string, OrderStatus> = {
  confirm: OrderStatus.CONFIRMED,
  confirmed: OrderStatus.CONFIRMED,
  ready: OrderStatus.READY_FOR_PICKUP,
  search: OrderStatus.SEARCHING,
  picked: OrderStatus.PICKED_UP,
  cancel: OrderStatus.CANCELLED,
  reject: OrderStatus.REJECTED,
  assign: OrderStatus.ASSIGNED,
  deliver: OrderStatus.DELIVERED,
  prepare: OrderStatus.PREPARING,
  preparing: OrderStatus.PREPARING,
};

function normalizeStatus(value: string): OrderStatus {
  const normalized = value.toLowerCase().trim();
  return STATUS_MAP[normalized] || (value.toUpperCase() as OrderStatus);
}

function isValidOrderStatus(status: string): boolean {
  const normalized = status.toUpperCase().trim();
  return Object.values(OrderStatus).includes(normalized as OrderStatus);
}

function transformStatusValue(
  value: any,
): OrderStatus | OrderStatus[] | undefined {
  if (!value) return undefined;

  let str: string;
  if (Array.isArray(value)) {
    const arr = value.filter((v) => v !== undefined && v !== null && v !== '');
    if (arr.length === 0) return undefined;
    str = arr.join(',');
  } else {
    str = String(value).trim();
  }

  if (str.includes(',')) {
    const statuses = str.split(',').map((s) => s.trim());
    const invalid = statuses.filter((s) => !isValidOrderStatus(s));
    if (invalid.length > 0) {
      return undefined;
    }
    return statuses.map((s) => normalizeStatus(s));
  }

  if (!isValidOrderStatus(str)) {
    return undefined;
  }
  return normalizeStatus(str);
}

export class OrdersQueryDto extends PaginationQueryDto {
  @ApiPropertyOptional({ description: 'رقم الصفحة', example: 1 })
  @IsOptional()
  @Transform(({ value }: any) => {
    if (value === '' || value === null || value === undefined) return undefined;
    if (typeof value === 'number') return value;
    const num = Number(value);
    return isNaN(num) ? undefined : num;
  })
  @IsPositive()
  page: number = 1;

  @ApiPropertyOptional({ description: 'عدد العناصر في الصفحة', example: 10 })
  @IsOptional()
  @Transform(({ value }: any) => {
    if (value === '' || value === null || value === undefined) return undefined;
    if (typeof value === 'number') return value;
    const num = Number(value);
    return isNaN(num) ? undefined : num;
  })
  @IsPositive()
  limit: number = 10;

  @ApiPropertyOptional({ description: 'بحث', example: '' })
  @IsOptional()
  @IsString()
  search?: string = undefined;

  @ApiPropertyOptional({ description: 'معرف التصنيف', example: 1 })
  @IsOptional()
  @Transform(({ value }: any) => {
    if (value === '' || value === null || value === undefined) return undefined;
    if (typeof value === 'number') return value;
    const num = Number(value);
    return isNaN(num) ? undefined : num;
  })
  @IsPositive()
  categoryId?: number = undefined;

  @ApiPropertyOptional({
    description: 'حالة الطلب (مفردة)',
    example: 'PENDING',
  })
  @IsOptional()
  @ValidateIf((o) => !o.statuses)
  @Transform(({ value }) => transformStatusValue(value))
  status?: OrderStatus | OrderStatus[];

  @ApiPropertyOptional({
    description: 'حالات الطلب (متعددة مفصولة بفواصل)',
    example: 'PENDING,CONFIRMED',
  })
  @IsOptional()
  @Transform(({ value }) => {
    if (!value) return undefined;
    return transformStatusValue(value);
  })
  statuses?: OrderStatus | OrderStatus[];

  @ApiPropertyOptional({ description: 'معرف التاجر', example: 1 })
  @IsOptional()
  @Transform(({ value }) => (value ? Number(value) : undefined))
  @IsNumber()
  merchantId?: number;

  @ApiPropertyOptional({
    description: 'تاريخ البداية',
    example: '2026-01-01',
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    description: 'تاريخ النهاية',
    example: '2026-12-31',
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}

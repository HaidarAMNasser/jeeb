import { Transform } from 'class-transformer';
import { IsNumber, IsNotEmpty, Min } from 'class-validator';

export class SetCommissionDto {
  @Transform(({ value }) => {
    if (typeof value === 'string') return parseFloat(value);
    return value;
  })
  @IsNumber()
  @IsNotEmpty()
  @Min(0)
  commissionRate: number;
}

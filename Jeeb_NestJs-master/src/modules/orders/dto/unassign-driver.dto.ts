import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsInt, IsNotEmpty, Min, ValidateIf } from 'class-validator';

export enum UnassignAction {
  AUTO_SEARCH = 'auto_search',
  MANUAL_ASSIGN = 'manual_assign',
}

export class UnassignDriverDto {
  @ApiProperty({ enum: UnassignAction, description: 'auto_search or manual_assign' })
  @IsEnum(UnassignAction)
  @IsNotEmpty()
  action: UnassignAction;

  @ApiPropertyOptional({ description: 'New driver ID (required if manual_assign)', example: 78 })
  @ValidateIf(o => o.action === UnassignAction.MANUAL_ASSIGN)
  @IsInt()
  @Min(1)
  @IsNotEmpty()
  newDeliveryId?: number;
}

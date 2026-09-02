import { IsArray, IsOptional, IsBoolean, IsEnum } from 'class-validator';
import { PermissionAction } from '../../../database/entities/role-permission.entity';

export class UpdateRolePermissionDto {
  @IsOptional()
  @IsArray()
  @IsEnum(PermissionAction, { each: true })
  actions?: PermissionAction[];

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

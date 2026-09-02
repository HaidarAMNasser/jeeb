import { IsNumber, IsEnum, IsArray } from 'class-validator';
import {
  PermissionResource,
  PermissionAction,
} from '../../../database/entities/role-permission.entity';

export class CreateRolePermissionDto {
  @IsNumber()
  userId: number;

  @IsEnum(PermissionResource)
  resource: PermissionResource;

  @IsArray()
  @IsEnum(PermissionAction, { each: true })
  actions: PermissionAction[];
}

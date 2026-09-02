import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  RolePermission,
  PermissionResource,
  PermissionAction,
} from '../../database/entities/role-permission.entity';
import { CreateRolePermissionDto } from './dto/create-role-permission.dto';
import { UpdateRolePermissionDto } from './dto/update-role-permission.dto';
import { UserRole } from '../../common/enums';

@Injectable()
export class RolePermissionsService {
  private readonly logger = new Logger(RolePermissionsService.name);

  constructor(
    @InjectRepository(RolePermission)
    private readonly rolePermissionRepository: Repository<RolePermission>,
  ) {}

  async create(createDto: CreateRolePermissionDto): Promise<RolePermission> {
    this.logger.log(
      `Creating role permission for user ${createDto.userId} on ${createDto.resource}`,
    );

    const existing = await this.rolePermissionRepository.findOne({
      where: { userId: createDto.userId, resource: createDto.resource },
    });

    if (existing) {
      existing.actions = createDto.actions.join(',');
      return this.rolePermissionRepository.save(existing);
    }

    const permission = this.rolePermissionRepository.create({
      userId: createDto.userId,
      resource: createDto.resource,
      actions: createDto.actions.join(','),
      isActive: true,
    });

    return this.rolePermissionRepository.save(permission);
  }

  async findAllByUser(userId: number): Promise<RolePermission[]> {
    return this.rolePermissionRepository.find({
      where: { userId },
      order: { resource: 'ASC' },
    });
  }

  async findOne(id: number): Promise<RolePermission> {
    const permission = await this.rolePermissionRepository.findOne({
      where: { id },
    });
    if (!permission) {
      throw new NotFoundException(`Role permission with ID ${id} not found`);
    }
    return permission;
  }

  async findByUserAndResource(
    userId: number,
    resource: PermissionResource,
  ): Promise<RolePermission | null> {
    return this.rolePermissionRepository.findOne({
      where: { userId, resource },
    });
  }

  async update(
    id: number,
    updateDto: UpdateRolePermissionDto,
  ): Promise<RolePermission> {
    const permission = await this.findOne(id);

    if (updateDto.actions) {
      permission.actions = updateDto.actions.join(',');
    }
    if (updateDto.isActive !== undefined) {
      permission.isActive = updateDto.isActive;
    }

    return this.rolePermissionRepository.save(permission);
  }

  async remove(id: number): Promise<void> {
    const permission = await this.findOne(id);
    await this.rolePermissionRepository.remove(permission);
  }

  async hasPermission(
    userId: number,
    resource: PermissionResource,
    action: PermissionAction,
  ): Promise<boolean> {
    const permission = await this.findByUserAndResource(userId, resource);

    if (!permission || !permission.isActive) {
      return false;
    }

    const actions = permission.actions.split(',');
    return actions.includes(action);
  }

  async getUserPermissions(
    userId: number,
  ): Promise<{ resource: string; actions: string[] }[]> {
    const permissions = await this.findAllByUser(userId);
    return permissions.map((p) => ({
      resource: p.resource,
      actions: p.actions.split(','),
    }));
  }

  async createDefaultPermissions(
    userId: number,
    role: UserRole,
  ): Promise<void> {
    const defaultPermissions = this.getDefaultPermissionsByRole(role);

    for (const perm of defaultPermissions) {
      await this.create({
        userId,
        resource: perm.resource,
        actions: perm.actions,
      });
    }

    this.logger.log(
      `Created default permissions for user ${userId} with role ${role}`,
    );
  }

  private getDefaultPermissionsByRole(
    role: UserRole,
  ): { resource: PermissionResource; actions: PermissionAction[] }[] {
    switch (role) {
      case UserRole.ADMIN:
        return [
          {
            resource: PermissionResource.USERS,
            actions: [
              PermissionAction.CREATE,
              PermissionAction.READ,
              PermissionAction.UPDATE,
              PermissionAction.DELETE,
              PermissionAction.MANAGE,
            ],
          },
          {
            resource: PermissionResource.MERCHANTS,
            actions: [
              PermissionAction.CREATE,
              PermissionAction.READ,
              PermissionAction.UPDATE,
              PermissionAction.DELETE,
              PermissionAction.MANAGE,
            ],
          },
          {
            resource: PermissionResource.CUSTOMERS,
            actions: [
              PermissionAction.CREATE,
              PermissionAction.READ,
              PermissionAction.UPDATE,
              PermissionAction.DELETE,
              PermissionAction.MANAGE,
            ],
          },
          {
            resource: PermissionResource.DELIVERY,
            actions: [
              PermissionAction.CREATE,
              PermissionAction.READ,
              PermissionAction.UPDATE,
              PermissionAction.DELETE,
              PermissionAction.MANAGE,
            ],
          },
          {
            resource: PermissionResource.PRODUCTS,
            actions: [
              PermissionAction.CREATE,
              PermissionAction.READ,
              PermissionAction.UPDATE,
              PermissionAction.DELETE,
              PermissionAction.MANAGE,
            ],
          },
          {
            resource: PermissionResource.ORDERS,
            actions: [
              PermissionAction.CREATE,
              PermissionAction.READ,
              PermissionAction.UPDATE,
              PermissionAction.DELETE,
              PermissionAction.MANAGE,
            ],
          },
          {
            resource: PermissionResource.CATEGORIES,
            actions: [
              PermissionAction.CREATE,
              PermissionAction.READ,
              PermissionAction.UPDATE,
              PermissionAction.DELETE,
              PermissionAction.MANAGE,
            ],
          },
          {
            resource: PermissionResource.COUPONS,
            actions: [
              PermissionAction.CREATE,
              PermissionAction.READ,
              PermissionAction.UPDATE,
              PermissionAction.DELETE,
              PermissionAction.MANAGE,
            ],
          },
          {
            resource: PermissionResource.REPORTS,
            actions: [PermissionAction.READ, PermissionAction.MANAGE],
          },
          {
            resource: PermissionResource.SETTINGS,
            actions: [
              PermissionAction.READ,
              PermissionAction.UPDATE,
              PermissionAction.MANAGE,
            ],
          },
        ];
      case UserRole.MERCHANT:
        return [
          {
            resource: PermissionResource.PRODUCTS,
            actions: [
              PermissionAction.CREATE,
              PermissionAction.READ,
              PermissionAction.UPDATE,
              PermissionAction.DELETE,
            ],
          },
          {
            resource: PermissionResource.ORDERS,
            actions: [PermissionAction.READ, PermissionAction.UPDATE],
          },
          {
            resource: PermissionResource.REVIEWS,
            actions: [PermissionAction.READ],
          },
          {
            resource: PermissionResource.REPORTS,
            actions: [PermissionAction.READ],
          },
        ];
      case UserRole.DELIVERY:
        return [
          {
            resource: PermissionResource.DELIVERY,
            actions: [PermissionAction.READ, PermissionAction.UPDATE],
          },
          {
            resource: PermissionResource.ORDERS,
            actions: [PermissionAction.READ, PermissionAction.UPDATE],
          },
        ];
      case UserRole.CUSTOMER:
        return [
          {
            resource: PermissionResource.ORDERS,
            actions: [PermissionAction.CREATE, PermissionAction.READ],
          },
          {
            resource: PermissionResource.REVIEWS,
            actions: [PermissionAction.CREATE, PermissionAction.READ],
          },
          {
            resource: PermissionResource.WALLET,
            actions: [PermissionAction.READ, PermissionAction.UPDATE],
          },
        ];
      default:
        return [];
    }
  }
}

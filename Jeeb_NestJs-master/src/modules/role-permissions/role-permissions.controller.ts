import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  ParseIntPipe,
  Logger,
} from '@nestjs/common';
import { RolePermissionsService } from './role-permissions.service';
import { CreateRolePermissionDto } from './dto/create-role-permission.dto';
import { UpdateRolePermissionDto } from './dto/update-role-permission.dto';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums';
import {
  PermissionResource,
  PermissionAction,
} from '../../database/entities/role-permission.entity';

@Controller('role-permissions')
@Roles(UserRole.ADMIN)
export class RolePermissionsController {
  private readonly logger = new Logger(RolePermissionsController.name);

  constructor(
    private readonly rolePermissionsService: RolePermissionsService,
  ) {}

  @Post()
  create(@Body() createDto: CreateRolePermissionDto) {
    this.logger.log(`Creating role permission: ${JSON.stringify(createDto)}`);
    return this.rolePermissionsService.create(createDto);
  }

  @Get('user/:userId')
  findAllByUser(@Param('userId', ParseIntPipe) userId: number) {
    return this.rolePermissionsService.findAllByUser(userId);
  }

  @Get('user/:userId/check')
  async checkPermissions(
    @Param('userId', ParseIntPipe) userId: number,
    @Body() body: { resource: PermissionResource; action: PermissionAction },
  ) {
    const hasPermission = await this.rolePermissionsService.hasPermission(
      userId,
      body.resource,
      body.action,
    );
    return { hasPermission };
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.rolePermissionsService.findOne(id);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateDto: UpdateRolePermissionDto,
  ) {
    return this.rolePermissionsService.update(id, updateDto);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.rolePermissionsService.remove(id);
  }

  @Post('user/:userId/defaults')
  async createDefaultPermissions(
    @Param('userId', ParseIntPipe) userId: number,
    @Body() body: { role: UserRole },
  ) {
    await this.rolePermissionsService.createDefaultPermissions(
      userId,
      body.role,
    );
    return { message: 'Default permissions created successfully' };
  }

  @Get('user/:userId/permissions')
  getUserPermissions(@Param('userId', ParseIntPipe) userId: number) {
    return this.rolePermissionsService.getUserPermissions(userId);
  }
}

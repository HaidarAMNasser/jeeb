import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { AuthService } from './auth.service';
import { CreateUserDto } from './dto/create-user.dto';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiBody,
} from '@nestjs/swagger';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { ADMIN_AUTH_ROUTES } from '../../common/constants/api-routes.constants';

@ApiTags('Auth Admin')
@ApiBearerAuth('JWT-auth')
@Controller(ADMIN_AUTH_ROUTES.BASE)
@UseGuards(AuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AuthAdminController {
  constructor(private readonly authService: AuthService) {}

  @ApiOperation({
    summary: 'إنشاء مستخدم جديد (Admin/Merchant)',
    description: 'إنشاء حساب إداري أو تاجر من قبل المدير',
  })
  @ApiBody({ type: CreateUserDto })
  @ApiResponse({ status: 201, description: 'User created successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden - Admin only' })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  @Post(ADMIN_AUTH_ROUTES.CREATE_USER)
  async createUser(@Body() createUserDto: CreateUserDto) {
    return this.authService.createAdminOrMerchant(createUserDto);
  }
}

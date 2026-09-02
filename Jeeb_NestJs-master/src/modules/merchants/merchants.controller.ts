import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  ParseIntPipe,
  Logger,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { MerchantsService } from './merchants.service';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole, MerchantType } from '../../common/enums';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@Controller('merchants')
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class MerchantsController {
  private readonly logger = new Logger(MerchantsController.name);

  constructor(private readonly merchantsService: MerchantsService) {}

  @Get()
  async findAll(
    @Query()
    query: {
      page?: number;
      limit?: number;
      search?: string;
      isOpen?: boolean;
      isActive?: boolean;
      type?: MerchantType;
    },
    @CurrentUser() user?: any,
  ) {
    const result = await this.merchantsService.findAllMerchants(query, user);

    return result;
  }

  @Get('profile')
  @Roles(UserRole.MERCHANT)
  getMyProfile(@CurrentUser() user: any) {
    this.logger.log('='.repeat(50));
    this.logger.log(
      '👤 [CONTROLLER] GET /merchants/profile - Merchant profile request',
    );
    this.logger.log(`🆔 [CONTROLLER] User ID from token: ${user?.id}`);
    return this.merchantsService.findByUserId(user?.id);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    this.logger.log(
      `🔍 [CONTROLLER] GET /merchants/${id} - Fetching merchant by id`,
    );
    return this.merchantsService.findById(id);
  }

  @Get('user/:userId')
  findByUser(@Param('userId', ParseIntPipe) userId: number) {
    this.logger.log(
      `🔍 [CONTROLLER] GET /merchants/user/${userId} - Fetching merchant by userId`,
    );
    return this.merchantsService.findByUserId(userId);
  }

  @Post()
  @Roles(UserRole.ADMIN)
  create(
    @Body()
    body: {
      userId: number;
      restaurantName?: string;
      description?: string;
    },
  ) {
    this.logger.log('='.repeat(50));
    this.logger.log(
      '➕ [CONTROLLER] POST /merchants - Creating merchant profile',
    );
    this.logger.log(`📋 [CONTROLLER] Body: ${JSON.stringify(body)}`);
    return this.merchantsService.createMerchantProfile(body.userId, body);
  }

  @Patch('user/:userId')
  @Roles(UserRole.ADMIN, UserRole.MERCHANT)
  update(
    @Param('userId', ParseIntPipe) userId: number,
    @Body() body: any,
    @CurrentUser() user: any,
  ) {
    this.logger.log('='.repeat(50));
    this.logger.log(
      `✏️ [CONTROLLER] PATCH /merchants/user/${userId} - Updating merchant`,
    );
    this.logger.log(
      `👤 [CONTROLLER] Requester: userId=${user?.id}, role=${user?.role}`,
    );
    this.logger.log(
      `📋 [CONTROLLER] RAW Body: ${JSON.stringify(body, null, 2)}`,
    );
    this.logger.log(
      `📋 [CONTROLLER] Body keys: ${Object.keys(body).join(', ')}`,
    );

    const processedBody: any = {};

    if (body.restaurantName !== undefined)
      processedBody.restaurantName = body.restaurantName;
    if (body.description !== undefined)
      processedBody.description = body.description;

    // Helper to handle both boolean and string "true"/"false" from form-data
    const parseBoolean = (val: any) => {
      if (typeof val === 'boolean') return val;
      if (val === 'true') return true;
      if (val === 'false') return false;
      return undefined;
    };

    if (body.isOpen !== undefined)
      processedBody.isOpen = parseBoolean(body.isOpen);
    if (body.isActive !== undefined)
      processedBody.isActive = parseBoolean(body.isActive);
    if (body.hidePhoneNumber !== undefined)
      processedBody.hidePhoneNumber = parseBoolean(body.hidePhoneNumber);
    if (body.type !== undefined) processedBody.type = body.type;

    return this.merchantsService.updateMerchant(
      userId,
      processedBody,
      user.role,
    );
  }

  @Patch('user/:userId/toggle-open')
  @Roles(UserRole.ADMIN, UserRole.MERCHANT)
  toggleOpen(
    @Param('userId', ParseIntPipe) userId: number,
    @CurrentUser() user: any,
  ) {
    this.logger.log('='.repeat(50));
    this.logger.log(
      `🔄 [CONTROLLER] PATCH /merchants/user/${userId}/toggle-open`,
    );
    this.logger.log(
      `👤 [CONTROLLER] Requester: userId=${user?.id}, role=${user?.role}`,
    );
    return this.merchantsService.toggleOpenStatus(userId);
  }

  @Delete('user/:userId')
  @Roles(UserRole.ADMIN)
  delete(
    @Param('userId', ParseIntPipe) userId: number,
    @CurrentUser() user: any,
  ) {
    this.logger.log('='.repeat(50));
    this.logger.warn(
      `🗑️ [CONTROLLER] DELETE /merchants/user/${userId} - Deleting merchant`,
    );
    this.logger.warn(
      `👤 [CONTROLLER] Requester: userId=${user?.id}, role=${user?.role}`,
    );
    return this.merchantsService.deleteMerchant(userId);
  }
}

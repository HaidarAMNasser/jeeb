import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Query,
  UseGuards,
  ParseIntPipe,
  Logger,
  UsePipes,
  UseInterceptors,
  UploadedFile,
  ValidationPipe,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UsersService } from './users.service';
import { MerchantsService } from '../merchants/merchants.service';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { CreateMerchantDto } from './dto/create-merchant.dto';
import { CreateDeliveryDto } from './dto/create-delivery.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';
import { UpdateMerchantDto } from './dto/update-merchant.dto';
import { UpdateDeliveryDto } from './dto/update-delivery.dto';
import { CustomerFilterDto } from './dto/customer-filter.dto';
import { MerchantFilterDto } from './dto/merchant-filter.dto';
import { DeliveryFilterDto } from './dto/delivery-filter.dto';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enums/user-role.enum';
import { USERS_ROUTES } from '../../common/constants/api-routes.constants';
import { StorageService } from '../../common/storage/storage.service';
import {
  ApiFindAllCustomersEndpoint,
  ApiFindOneCustomerEndpoint,
  ApiCreateCustomerEndpoint,
  ApiUpdateCustomerEndpoint,
  ApiRemoveCustomerEndpoint,
  ApiFindAllMerchantsEndpoint,
  ApiFindOneMerchantEndpoint,
  ApiCreateMerchantEndpoint,
  ApiUpdateMerchantEndpoint,
  ApiRemoveMerchantEndpoint,
  ApiFindAllDeliveriesEndpoint,
  ApiFindOneDeliveryEndpoint,
  ApiCreateDeliveryEndpoint,
  ApiUpdateDeliveryEndpoint,
  ApiRemoveDeliveryEndpoint,
  ApiToggleMerchantOpenEndpoint,
} from './users-controller.swagger';

@Controller(USERS_ROUTES.BASE)
@UseGuards(AuthGuard, RolesGuard)
@UsePipes(
  new ValidationPipe({
    transform: true,
    whitelist: true,
    transformOptions: {
      enableImplicitConversion: true,
    },
  }),
)
export class UsersController {
  private readonly logger = new Logger(UsersController.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly merchantsService: MerchantsService,
    private readonly storageService: StorageService,
  ) {}

  // --- Customers ---

  @ApiFindAllCustomersEndpoint()
  @Get(USERS_ROUTES.CUSTOMERS)
  @Roles(UserRole.ADMIN)
  async findAllCustomers(@Query() query: CustomerFilterDto) {
    const result = await this.usersService.findAllCustomers(query);

    return result;
  }

  @ApiFindOneCustomerEndpoint()
  @Get(USERS_ROUTES.CUSTOMER_BY_ID)
  @Roles(UserRole.ADMIN)
  findOneCustomer(@Param('id', ParseIntPipe) id: number) {
    return this.usersService.findOneByIdWithRelations(id);
  }

  @ApiCreateCustomerEndpoint()
  @Post(USERS_ROUTES.CUSTOMERS)
  @Roles(UserRole.ADMIN)
  createCustomer(@Body() createCustomerDto: CreateCustomerDto) {
    return this.usersService.createCustomer(createCustomerDto);
  }

  @ApiUpdateCustomerEndpoint()
  @Patch(USERS_ROUTES.CUSTOMER_BY_ID)
  @Roles(UserRole.ADMIN)
  updateCustomer(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateCustomerDto: UpdateCustomerDto,
  ) {
    return this.usersService.updateCustomer(id, updateCustomerDto);
  }

  @ApiRemoveCustomerEndpoint()
  @Delete(USERS_ROUTES.CUSTOMER_BY_ID)
  @Roles(UserRole.ADMIN)
  removeCustomer(@Param('id', ParseIntPipe) id: number) {
    return this.usersService.softDelete(id);
  }

  // --- Merchants ---

  @ApiFindAllMerchantsEndpoint()
  @Get(USERS_ROUTES.MERCHANTS)
  @Roles(UserRole.ADMIN)
  async findAllMerchants(@Query() query: MerchantFilterDto) {
    const result = await this.usersService.findAllMerchants(query);

    return result;
  }

  @ApiFindOneMerchantEndpoint()
  @Get(USERS_ROUTES.MERCHANT_BY_ID)
  @Roles(UserRole.ADMIN)
  async findOneMerchant(@Param('id', ParseIntPipe) id: number) {
    this.logger.log(`🔍 [CONTROLLER] Fetching merchant by userId: ${id}`);

    const merchantResponse = await this.merchantsService.findByUserId(id);

    if (!merchantResponse || !merchantResponse.user) {
      this.logger.warn(
        `⚠️ [CONTROLLER] Merchant not found via merchantsService, falling back to user service`,
      );
      const userData = await this.usersService.findOneByIdWithRelations(id);
      return this.resolveMerchantResponseUrls(userData);
    }

    return this.resolveMerchantResponseUrls(merchantResponse);
  }

  private resolveMerchantResponseUrls(response: any) {
    if (response?.user?.images && response.user.images.length > 0) {
      for (const img of response.user.images) {
        img.url = this.storageService.resolveUrl(img.url) || img.url;
        img.mobileUrl = this.storageService.resolveUrl(img.mobileUrl);
        img.thumbnailUrl = this.storageService.resolveUrl(img.thumbnailUrl);
      }
    }
    if (response?.images && response.images.length > 0) {
      for (const img of response.images) {
        img.url = this.storageService.resolveUrl(img.url) || img.url;
        img.mobileUrl = this.storageService.resolveUrl(img.mobileUrl);
        img.thumbnailUrl = this.storageService.resolveUrl(img.thumbnailUrl);
      }
    }
    return response;
  }

  @ApiCreateMerchantEndpoint()
  @Post(USERS_ROUTES.MERCHANTS)
  @Roles(UserRole.ADMIN)
  createMerchant(@Body() createMerchantDto: CreateMerchantDto) {
    this.logger.log('📥 [CREATE MERCHANT] Request received:');
    this.logger.log('   Body:', JSON.stringify(createMerchantDto, null, 2));
    this.logger.log('  countryId type:', typeof createMerchantDto.countryId);
    this.logger.log('   cityId type:', typeof createMerchantDto.cityId);

    return this.usersService.createMerchant(createMerchantDto);
  }

  @ApiUpdateMerchantEndpoint()
  @Patch(USERS_ROUTES.MERCHANT_BY_ID)
  @Roles(UserRole.ADMIN)
  @UseInterceptors(FileInterceptor('image'))
  updateMerchant(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateMerchantDto: UpdateMerchantDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.usersService.updateMerchant(id, updateMerchantDto, file);
  }

  @ApiRemoveMerchantEndpoint()
  @Delete(USERS_ROUTES.MERCHANT_BY_ID)
  @Roles(UserRole.ADMIN)
  async removeMerchant(@Param('id', ParseIntPipe) id: number) {
    this.logger.log('='.repeat(50));
    this.logger.warn(
      `🗑️ [CONTROLLER] DELETE /users/merchants/${id} - Deleting merchant`,
    );
    this.logger.log(`👤 [CONTROLLER] User ID to delete: ${id}`);

    try {
      await this.merchantsService.deleteMerchant(id);
    } catch (error) {
      this.logger.warn(
        `⚠️ [CONTROLLER] Merchant profile not found, continuing with user delete`,
      );
    }

    await this.usersService.hardDelete(id);
    this.logger.log('='.repeat(50));
    return { message: 'Merchant and user deleted successfully' };
  }

  // --- Deliveries (Drivers) ---

  @ApiFindAllDeliveriesEndpoint()
  @Get(USERS_ROUTES.DELIVERIES)
  @Roles(UserRole.ADMIN)
  async findAllDeliveries(@Query() query: DeliveryFilterDto) {
    const result = await this.usersService.findAllDeliveries(query);

    return result;
  }

  @ApiFindOneDeliveryEndpoint()
  @Get(USERS_ROUTES.DELIVERY_BY_ID)
  @Roles(UserRole.ADMIN)
  findOneDelivery(@Param('id', ParseIntPipe) id: number) {
    return this.usersService.findOneByIdWithRelations(id);
  }

  @ApiCreateDeliveryEndpoint()
  @Post(USERS_ROUTES.DELIVERIES)
  @Roles(UserRole.ADMIN)
  createDelivery(@Body() createDeliveryDto: CreateDeliveryDto) {
    return this.usersService.createDelivery(createDeliveryDto);
  }

  @ApiUpdateDeliveryEndpoint()
  @Patch(USERS_ROUTES.DELIVERY_BY_ID)
  @Roles(UserRole.ADMIN)
  updateDelivery(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateDeliveryDto: UpdateDeliveryDto,
  ) {
    return this.usersService.updateDelivery(id, updateDeliveryDto);
  }

  @ApiRemoveDeliveryEndpoint()
  @Delete(USERS_ROUTES.DELIVERY_BY_ID)
  @Roles(UserRole.ADMIN)
  async removeDelivery(@Param('id', ParseIntPipe) id: number) {
    this.logger.log('='.repeat(50));
    this.logger.warn(
      `🗑️ [CONTROLLER] DELETE /users/deliveries/${id} - Deleting delivery user`,
    );
    this.logger.log(`👤 [CONTROLLER] User ID to delete: ${id}`);

    await this.usersService.hardDelete(id);
    this.logger.log('='.repeat(50));
    return { message: 'Delivery user deleted successfully' };
  }

  // --- Merchant Status (isOpen) ---
  @ApiToggleMerchantOpenEndpoint()
  @Patch(':id/toggle-open')
  @Roles(UserRole.ADMIN, UserRole.MERCHANT)
  toggleMerchantOpen(@Param('id', ParseIntPipe) id: number) {
    return this.usersService.toggleMerchantOpen(id);
  }
}

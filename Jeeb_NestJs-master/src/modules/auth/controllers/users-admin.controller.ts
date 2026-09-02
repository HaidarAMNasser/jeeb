import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  ParseIntPipe,
  HttpStatus,
  HttpCode,
  UseInterceptors,
  UploadedFile,
  ParseFilePipeBuilder,
  Req,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
  ApiParam,
  ApiQuery,
  ApiResponse,
} from '@nestjs/swagger';
import { UsersAdminService } from '../services/users-admin.service';
import { CreateUserDto } from '../dto/create-user.dto';
import { UpdateUserAdminDto } from '../dto/update-user-admin.dto';
import { FilterUserDto } from '../dto/filter-user.dto';
import { CreateOfficeOwnerDto } from '../dto/create-office-owner.dto';
import { UpdateOfficeOwnerDto } from '../dto/update-office-owner.dto';
import { CreateDeliveryByOfficeDto } from '../dto/create-delivery-by-office.dto';
import { UpdateDeliveryByOfficeDto } from '../dto/update-delivery-by-office.dto';
import { AdminResetPasswordDto } from '../dto/admin-reset-password.dto';
import { AuthGuard } from '../../../common/guards/auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { UserRole } from '../../../common/enums/user-role.enum';
import { USERS_ROUTES } from '../../../common/constants/api-routes.constants';

@Controller(USERS_ROUTES.BASE)
@ApiTags('Users Admin')
@ApiBearerAuth('JWT-auth')
@UseGuards(AuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class UsersAdminController {
  constructor(private readonly usersAdminService: UsersAdminService) {}

  /**
   * Create a new user (ADMIN only)
   * POST /users
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FileInterceptor('image'))
  async create(
    @Body() createUserDto: CreateUserDto,
    @UploadedFile(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({
          fileType: /^image\/(jpeg|png|gif|webp)$/i,
        })
        .addMaxSizeValidator({
          maxSize: 5 * 1024 * 1024, // 5MB
        })
        .build({
          errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
          fileIsRequired: false,
        }),
    )
    file: Express.Multer.File,
  ) {
    const user = await this.usersAdminService.create(createUserDto, file);
    return {
      statusCode: HttpStatus.CREATED,
      message: 'User created successfully',
      data: user,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}`,
    };
  }

  /**
   * Get all users with filtering and pagination
   * GET /users?page=1&limit=10&search=john&countryId=1&role=CUSTOMER
   * Note: If no role is specified, defaults to CUSTOMER users only
   */
  @Get()
  @ApiOperation({
    summary: 'Get all users with filtering',
    description:
      'Returns all users with filtering by search, country, city, role, verification status, and online status. If no role is specified, defaults to CUSTOMER users only.',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    example: 1,
    description: 'Page number',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    example: 10,
    description: 'Items per page',
  })
  @ApiQuery({
    name: 'search',
    required: false,
    type: String,
    example: 'john',
    description: 'Search by name, email or phone',
  })
  @ApiQuery({
    name: 'countryId',
    required: false,
    type: Number,
    example: 1,
    description: 'Filter by country ID',
  })
  @ApiQuery({
    name: 'cityId',
    required: false,
    type: Number,
    example: 1,
    description: 'Filter by city ID',
  })
  @ApiQuery({
    name: 'role',
    required: false,
    enum: UserRole,
    example: UserRole.CUSTOMER,
    description: 'Filter by user role',
  })
  @ApiQuery({
    name: 'isVerified',
    required: false,
    type: Boolean,
    example: true,
    description: 'Filter by verification status',
  })
  @ApiQuery({
    name: 'isOnline',
    required: false,
    type: Boolean,
    example: true,
    description: 'Filter by online status',
  })
  @ApiResponse({
    status: 200,
    description: 'List of users with pagination',
  })
  async findAll(@Query() filterDto: FilterUserDto) {
    // Default to CUSTOMER role if no role is specified
    const updatedFilterDto = {
      ...filterDto,
      role: filterDto.role || UserRole.CUSTOMER,
    };

    const result = await this.usersAdminService.findAll(updatedFilterDto);
    return {
      statusCode: HttpStatus.OK,
      message: 'Operation successful',
      data: result.data,
      pagination: result.pagination,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}`,
    };
  }

  /**
   * Get all customers (ADMIN only)
   * GET /users/customers?page=1&limit=10&search=john&countryId=1&cityId=1
   */
  @Get(`${USERS_ROUTES.CUSTOMERS}`)
  @ApiOperation({
    summary: 'Get all customers (ADMIN)',
    description:
      'Returns all customers with filtering by search, country, city, verification status, and online status',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    example: 1,
    description: 'Page number',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    example: 10,
    description: 'Items per page',
  })
  @ApiQuery({
    name: 'search',
    required: false,
    type: String,
    example: 'john',
    description: 'Search by name, email or phone',
  })
  @ApiQuery({
    name: 'countryId',
    required: false,
    type: Number,
    example: 1,
    description: 'Filter by country ID',
  })
  @ApiQuery({
    name: 'cityId',
    required: false,
    type: Number,
    example: 1,
    description: 'Filter by city ID',
  })
  @ApiQuery({
    name: 'isVerified',
    required: false,
    type: Boolean,
    example: true,
    description: 'Filter by verification status',
  })
  @ApiQuery({
    name: 'isOnline',
    required: false,
    type: Boolean,
    example: true,
    description: 'Filter by online status',
  })
  @ApiResponse({
    status: 200,
    description: 'List of customers with pagination',
  })
  async findAllCustomers(@Query() filterDto: FilterUserDto) {
    // Force role to CUSTOMER for this endpoint
    const updatedFilterDto = {
      ...filterDto,
      role: UserRole.CUSTOMER,
    };

    const result = await this.usersAdminService.findAll(updatedFilterDto);
    return {
      statusCode: HttpStatus.OK,
      message: 'Customers retrieved successfully',
      data: result.data,
      pagination: result.pagination,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}?role=CUSTOMER`,
    };
  }

  /**
   * Get customers with singular endpoint (ADMIN only)
   * GET /users/customer?page=1&limit=10&search=john&countryId=1&cityId=1
   */
  @Get(`${USERS_ROUTES.CUSTOMER}`)
  @ApiOperation({
    summary: 'Get customers (ADMIN)',
    description:
      'Returns customers with filtering by search, country, city, verification status, and online status',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    example: 1,
    description: 'Page number',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    example: 10,
    description: 'Items per page',
  })
  @ApiQuery({
    name: 'search',
    required: false,
    type: String,
    example: 'john',
    description: 'Search by name, email or phone',
  })
  @ApiQuery({
    name: 'countryId',
    required: false,
    type: Number,
    example: 1,
    description: 'Filter by country ID',
  })
  @ApiQuery({
    name: 'cityId',
    required: false,
    type: Number,
    example: 1,
    description: 'Filter by city ID',
  })
  @ApiQuery({
    name: 'isVerified',
    required: false,
    type: Boolean,
    example: true,
    description: 'Filter by verification status',
  })
  @ApiQuery({
    name: 'isOnline',
    required: false,
    type: Boolean,
    example: true,
    description: 'Filter by online status',
  })
  @ApiResponse({
    status: 200,
    description: 'List of customers with pagination',
  })
  async findCustomers(@Query() filterDto: FilterUserDto) {
    // Force role to CUSTOMER for this endpoint
    const updatedFilterDto = {
      ...filterDto,
      role: UserRole.CUSTOMER,
    };

    const result = await this.usersAdminService.findAll(updatedFilterDto);
    return {
      statusCode: HttpStatus.OK,
      message: 'Customers retrieved successfully',
      data: result.data,
      pagination: result.pagination,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.CUSTOMER}`,
    };
  }

  /**
   * Get all delivery drivers (ADMIN only - sees all deliveries)
   * GET /users/deliveries?page=1&limit=10&search=john&countryId=1&cityId=1&isOnline=true&officeOwnerId=5
   */
  @Get(`${USERS_ROUTES.DELIVERIES}`)
  @ApiOperation({
    summary: 'Get all delivery drivers (ADMIN)',
    description:
      'ADMIN only - Returns all delivery drivers in the system with filtering by country, city, office owner, and online status',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    example: 1,
    description: 'Page number',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    example: 10,
    description: 'Items per page',
  })
  @ApiQuery({
    name: 'search',
    required: false,
    type: String,
    example: 'ahmed',
    description: 'Search by name',
  })
  @ApiQuery({
    name: 'countryId',
    required: false,
    type: Number,
    example: 1,
    description: 'Filter by country ID',
  })
  @ApiQuery({
    name: 'cityId',
    required: false,
    type: Number,
    example: 1,
    description: 'Filter by city ID',
  })
  @ApiQuery({
    name: 'isOnline',
    required: false,
    type: Boolean,
    example: true,
    description: 'Filter by online status',
  })
  @ApiQuery({
    name: 'officeOwnerId',
    required: false,
    type: Number,
    example: 5,
    description: 'Filter by office owner ID',
  })
  @ApiResponse({
    status: 200,
    description: 'List of all delivery drivers with pagination',
  })
  @ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' })
  async findAllDeliveries(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
    @Query('countryId') countryId?: string,
    @Query('cityId') cityId?: string,
    @Query('isOnline') isOnline?: string,
    @Query('officeOwnerId') officeOwnerId?: string,
  ) {
    // Print URL and parameters for debugging
    const url = `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.DELIVERIES}`;
    const params = {
      page: page ? parseInt(page, 10) : 1,
      limit: limit ? parseInt(limit, 10) : 10,
      search,
      countryId: countryId ? parseInt(countryId, 10) : undefined,
      cityId: cityId ? parseInt(cityId, 10) : undefined,
      isOnline: isOnline !== undefined ? isOnline === 'true' : undefined,
      officeOwnerId: officeOwnerId ? parseInt(officeOwnerId, 10) : undefined,
    };

    const result = await this.usersAdminService.findAllDeliveries(
      params.page,
      params.limit,
      params.search,
      params.countryId,
      params.cityId,
      params.isOnline,
      params.officeOwnerId,
    );

    const response = {
      statusCode: HttpStatus.OK,
      message: 'Operation successful',
      data: result.data,
      pagination: result.pagination,
      timestamp: new Date().toISOString(),
      path: url,
    };

    return response;
  }

  /**
   * Get one delivery driver by ID (ADMIN only)
   * GET /users/deliveries/:id
   */
  @Get(`${USERS_ROUTES.DELIVERIES}/:id`)
  @ApiOperation({
    summary: 'Get one delivery driver (ADMIN)',
    description: 'ADMIN only - Returns details of any delivery driver by ID',
  })
  @ApiParam({
    name: 'id',
    type: Number,
    example: 15,
    description: 'Delivery driver ID',
  })
  @ApiResponse({ status: 200, description: 'Delivery driver details' })
  @ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' })
  @ApiResponse({ status: 404, description: 'Delivery driver not found' })
  async findOneDelivery(@Param('id', ParseIntPipe) id: number) {
    const delivery = await this.usersAdminService.findOneDelivery(id);
    return {
      statusCode: HttpStatus.OK,
      message: 'Operation successful',
      data: delivery,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.DELIVERIES}/${id}`,
    };
  }

  /**
   * Create a new delivery driver (ADMIN only)
   * POST /users/deliveries
   */
  @Post(`${USERS_ROUTES.DELIVERIES}`)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Create delivery driver (ADMIN)',
    description:
      'ADMIN only - Creates a new delivery driver and optionally assigns to an office owner',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    description:
      'Delivery driver data with optional office owner assignment and image',
    schema: {
      type: 'object',
      properties: {
        email: {
          type: 'string',
          format: 'email',
          example: 'delivery1@example.com',
        },
        password: {
          type: 'string',
          minLength: 6,
          example: 'strongPassword123',
        },
        firstName: { type: 'string', example: 'Ahmed' },
        lastName: { type: 'string', example: 'Ali' },
        phone: { type: 'string', example: '+966501234567' },
        countryId: { type: 'number', example: 1 },
        cityId: { type: 'number', example: 1 },
        address: { type: 'string', example: 'Riyadh, Saudi Arabia' },
        notificationChannel: {
          type: 'string',
          enum: ['EMAIL', 'WHATSAPP'],
          example: 'WHATSAPP',
        },
        birthday: { type: 'string', format: 'date', example: '1990-05-15' },
        officeOwnerId: {
          type: 'number',
          example: 5,
          description: 'Office owner ID to assign the driver to (optional)',
        },
        image: {
          type: 'string',
          format: 'binary',
          description: 'Profile image (JPG, JPEG, PNG, WebP, max 5MB)',
        },
      },
      required: ['email', 'password', 'firstName', 'lastName', 'phone'],
    },
  })
  @ApiResponse({
    status: 201,
    description: 'Delivery driver created successfully',
  })
  @ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' })
  @ApiResponse({ status: 404, description: 'Office owner not found' })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  @ApiResponse({ status: 422, description: 'Invalid image file type or size' })
  @UseInterceptors(FileInterceptor('image'))
  async createDelivery(
    @Body() createDeliveryDto: CreateDeliveryByOfficeDto,
    @Req() req: any,
    @UploadedFile(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({
          fileType: /^image\/(jpeg|png|gif|webp)$/i,
        })
        .addMaxSizeValidator({
          maxSize: 5 * 1024 * 1024,
        })
        .build({
          errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
          fileIsRequired: false,
        }),
    )
    file: Express.Multer.File,
  ) {
    const reqAny = req;
    const delivery = await this.usersAdminService.createDelivery(
      createDeliveryDto,
      createDeliveryDto.officeOwnerId || undefined,
      file,
    );
    return {
      statusCode: HttpStatus.CREATED,
      message: 'Delivery driver created successfully',
      data: delivery,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.DELIVERIES}`,
    };
  }

  /**
   * Update a delivery driver (ADMIN only)
   * PATCH /users/deliveries/:id
   */
  @Patch(`${USERS_ROUTES.DELIVERIES}/:id`)
  @ApiOperation({
    summary: 'Update delivery driver (ADMIN)',
    description: 'ADMIN only - Updates any delivery driver information',
  })
  @ApiConsumes('multipart/form-data')
  @ApiParam({
    name: 'id',
    type: Number,
    example: 15,
    description: 'Delivery driver ID',
  })
  @ApiBody({
    description: 'Updated delivery driver data with optional image',
    schema: {
      type: 'object',
      properties: {
        firstName: { type: 'string', example: 'Ahmed Updated' },
        lastName: { type: 'string', example: 'Ali Updated' },
        phone: { type: 'string', example: '+966509876543' },
        password: { type: 'string', minLength: 6, example: 'newPassword123' },
        countryId: { type: 'number', example: 1 },
        cityId: { type: 'number', example: 1 },
        address: { type: 'string', example: 'New Address' },
        notificationChannel: {
          type: 'string',
          enum: ['EMAIL', 'WHATSAPP'],
          example: 'WHATSAPP',
        },
        birthday: { type: 'string', format: 'date', example: '1990-05-15' },
        image: {
          type: 'string',
          format: 'binary',
          description: 'New profile image (replaces old one)',
        },
      },
    },
  })
  @ApiResponse({
    status: 200,
    description: 'Delivery driver updated successfully',
  })
  @ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' })
  @ApiResponse({ status: 404, description: 'Delivery driver not found' })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  @ApiResponse({ status: 422, description: 'Invalid image file type or size' })
  @UseInterceptors(FileInterceptor('image'))
  async updateDelivery(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateDeliveryDto: UpdateDeliveryByOfficeDto,
    @UploadedFile(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({
          fileType: /^image\/(jpeg|png|gif|webp)$/i,
        })
        .addMaxSizeValidator({
          maxSize: 5 * 1024 * 1024,
        })
        .build({
          errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
          fileIsRequired: false,
        }),
    )
    file: Express.Multer.File,
  ) {
    const delivery = await this.usersAdminService.updateDelivery(
      id,
      updateDeliveryDto,
      file,
    );
    return {
      statusCode: HttpStatus.OK,
      message: 'Delivery driver updated successfully',
      data: delivery,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.DELIVERIES}/${id}`,
    };
  }

  /**
   * Delete a delivery driver (ADMIN only)
   * DELETE /users/deliveries/:id
   */
  @Delete(`${USERS_ROUTES.DELIVERIES}/:id`)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Delete delivery driver (ADMIN)',
    description: 'ADMIN only - Soft deletes any delivery driver',
  })
  @ApiParam({
    name: 'id',
    type: Number,
    example: 15,
    description: 'Delivery driver ID',
  })
  @ApiResponse({
    status: 200,
    description: 'Delivery driver deleted successfully',
  })
  @ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' })
  @ApiResponse({ status: 404, description: 'Delivery driver not found' })
  async removeDelivery(@Param('id', ParseIntPipe) id: number) {
    await this.usersAdminService.removeDelivery(id);
    return {
      statusCode: HttpStatus.OK,
      message: 'Delivery driver deleted successfully',
      data: {},
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.DELIVERIES}/${id}`,
    };
  }

  /**
   * Confirm/Activate a delivery driver (ADMIN only)
   * PATCH /users/deliveries/:id/confirm
   */
  @Patch(USERS_ROUTES.DELIVERY_CONFIRM)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Confirm/Activate delivery driver (ADMIN)',
    description:
      'ADMIN only - Activates a delivery driver by setting isActive to true',
  })
  @ApiBearerAuth('JWT-auth')
  @ApiParam({
    name: 'id',
    type: Number,
    example: 75,
    description: 'Delivery driver ID',
  })
  @ApiResponse({
    status: 200,
    description: 'Delivery driver activated successfully',
    schema: {
      example: {
        statusCode: 200,
        message: 'Delivery driver activated successfully',
        data: {
          id: 75,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phone: '+966509876543',
          role: 'DELIVERY',
          isActive: true,
          isOnline: false,
          isVerified: true,
          createdAt: '2026-04-03T10:00:00.000Z',
          updatedAt: '2026-04-03T19:00:00.000Z',
        },
        timestamp: '2026-04-03T19:00:00.000Z',
        path: '/api/v1/users/deliveries/75/confirm',
      },
    },
  })
  @ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' })
  @ApiResponse({ status: 404, description: 'Delivery driver not found' })
  async confirmDelivery(@Param('id', ParseIntPipe) id: number) {
    const delivery = await this.usersAdminService.confirmDelivery(id);
    return {
      statusCode: HttpStatus.OK,
      message: 'Delivery driver activated successfully',
      data: delivery,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.DELIVERIES}/${id}/confirm`,
    };
  }

  /**
   * Reset password for a delivery driver (ADMIN only)
   * PATCH /users/deliveries/:id/reset-password
   */
  @Patch(USERS_ROUTES.DELIVERY_RESET_PASSWORD)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Reset delivery driver password (ADMIN)',
    description:
      'ADMIN only - Resets the password for a delivery driver without requiring the old password',
  })
  @ApiBearerAuth('JWT-auth')
  @ApiParam({
    name: 'id',
    type: Number,
    example: 75,
    description: 'Delivery driver ID',
  })
  @ApiResponse({
    status: 200,
    description: 'Password reset successfully',
    schema: {
      example: {
        statusCode: 200,
        message: 'Password reset successfully',
        data: {
          id: 75,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phone: '+966509876543',
          role: 'DELIVERY',
        },
        timestamp: '2026-04-03T19:00:00.000Z',
        path: '/api/v1/users/deliveries/75/reset-password',
      },
    },
  })
  @ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' })
  @ApiResponse({ status: 404, description: 'Delivery driver not found' })
  async resetDeliveryPassword(
    @Param('id', ParseIntPipe) id: number,
    @Body() adminResetPasswordDto: AdminResetPasswordDto,
  ) {
    const delivery = await this.usersAdminService.resetPassword(
      id,
      adminResetPasswordDto.password,
    );
    return {
      statusCode: HttpStatus.OK,
      message: 'Password reset successfully',
      data: delivery,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.DELIVERIES}/${id}/reset-password`,
    };
  }

  /**
   * Create a new office owner (ADMIN only)
   * POST /users/office-owners
   */
  @Post(`${USERS_ROUTES.OFFICE_OWNERS}`)
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FileInterceptor('image'))
  async createOfficeOwner(
    @Body() createOfficeOwnerDto: CreateOfficeOwnerDto,
    @UploadedFile(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({
          fileType: /^image\/(jpeg|png|gif|webp)$/i,
        })
        .addMaxSizeValidator({
          maxSize: 5 * 1024 * 1024, // 5MB
        })
        .build({
          errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
          fileIsRequired: false,
        }),
    )
    file: Express.Multer.File,
  ) {
    const officeOwner = await this.usersAdminService.createOfficeOwner(
      createOfficeOwnerDto,
      file,
    );
    return {
      statusCode: HttpStatus.CREATED,
      message: 'Office owner created successfully',
      data: officeOwner,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/office-owners`,
    };
  }

  /**
   * Get all office owners (ADMIN only)
   * GET /users/office-owners?page=1&limit=10&search=john&countryId=1&cityId=1
   */
  @Get(`${USERS_ROUTES.OFFICE_OWNERS}`)
  async findAllOfficeOwners(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
    @Query('countryId') countryId?: string,
    @Query('cityId') cityId?: string,
  ) {
    const result = await this.usersAdminService.findAllOfficeOwners(
      page ? parseInt(page, 10) : 1,
      limit ? parseInt(limit, 10) : 10,
      search,
      countryId ? parseInt(countryId, 10) : undefined,
      cityId ? parseInt(cityId, 10) : undefined,
    );
    return {
      statusCode: HttpStatus.OK,
      message: 'Operation successful',
      data: result.data,
      pagination: result.pagination,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/office-owners`,
    };
  }

  /**
   * Get one office owner by ID (ADMIN only)
   * GET /users/office-owners/:id
   */
  @Get(`${USERS_ROUTES.OFFICE_OWNER_BY_ID}`)
  async findOneOfficeOwner(@Param('id', ParseIntPipe) id: number) {
    const officeOwner = await this.usersAdminService.findOneOfficeOwner(id);
    return {
      statusCode: HttpStatus.OK,
      message: 'Operation successful',
      data: officeOwner,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/office-owners/${id}`,
    };
  }

  /**
   * Update office owner information (ADMIN only)
   * PATCH /users/office-owners/:id
   */
  @Patch(`${USERS_ROUTES.OFFICE_OWNER_BY_ID}`)
  @UseInterceptors(FileInterceptor('image'))
  async updateOfficeOwner(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateOfficeOwnerDto: UpdateOfficeOwnerDto,
    @UploadedFile(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({
          fileType: /^image\/(jpeg|png|gif|webp)$/i,
        })
        .addMaxSizeValidator({
          maxSize: 5 * 1024 * 1024, // 5MB
        })
        .build({
          errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
          fileIsRequired: false,
        }),
    )
    file: Express.Multer.File,
  ) {
    const officeOwner = await this.usersAdminService.updateOfficeOwner(
      id,
      updateOfficeOwnerDto,
      file,
    );
    return {
      statusCode: HttpStatus.OK,
      message: 'Office owner updated successfully',
      data: officeOwner,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/office-owners/${id}`,
    };
  }

  /**
   * Delete office owner (soft delete) (ADMIN only)
   * DELETE /users/office-owners/:id
   */
  @Delete(`${USERS_ROUTES.OFFICE_OWNER_BY_ID}`)
  @HttpCode(HttpStatus.OK)
  async removeOfficeOwner(@Param('id', ParseIntPipe) id: number) {
    await this.usersAdminService.removeOfficeOwner(id);
    return {
      statusCode: HttpStatus.OK,
      message: 'Office owner deleted successfully',
      data: {},
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/office-owners/${id}`,
    };
  }

  /**
   * Get one user by ID
   * GET /users/:id
   */
  @Get(':id')
  async findOne(@Param('id', ParseIntPipe) id: number) {
    const user = await this.usersAdminService.findOne(id);
    return {
      statusCode: HttpStatus.OK,
      message: 'Operation successful',
      data: user,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${id}`,
    };
  }

  /**
   * Update user information
   * PATCH /users/:id
   */
  @Patch(':id')
  @UseInterceptors(FileInterceptor('image'))
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateUserDto: UpdateUserAdminDto,
    @UploadedFile(
      new ParseFilePipeBuilder()
        .addFileTypeValidator({
          fileType: /^image\/(jpeg|png|gif|webp)$/i,
        })
        .addMaxSizeValidator({
          maxSize: 5 * 1024 * 1024, // 5MB
        })
        .build({
          errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY,
          fileIsRequired: false,
        }),
    )
    file: Express.Multer.File,
  ) {
    const user = await this.usersAdminService.update(id, updateUserDto, file);
    return {
      statusCode: HttpStatus.OK,
      message: 'User updated successfully',
      data: user,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${id}`,
    };
  }

  /**
   * Delete user (soft delete)
   * DELETE /users/:id
   */
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  async remove(@Param('id', ParseIntPipe) id: number) {
    await this.usersAdminService.remove(id);
    return {
      statusCode: HttpStatus.OK,
      message: 'User deleted successfully',
      data: {},
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${id}`,
    };
  }
}

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
  HttpCode,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
  ParseFilePipeBuilder,
  Req,
  Request,
  ParseIntPipe,
} from '@nestjs/common';
import type { Request as ExpressRequest } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { OfficeOwnersService } from '../services/office-owners.service';
import { CreateDeliveryByOfficeDto } from '../dto/create-delivery-by-office.dto';
import { UpdateDeliveryByOfficeDto } from '../dto/update-delivery-by-office.dto';
import { AuthGuard } from '../../../common/guards/auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { UserRole } from '../../../common/enums/user-role.enum';
import { USERS_ROUTES } from '../../../common/constants/api-routes.constants';
import type {
  DeliveryDriverQuery,
  OfficeOwnerContext,
} from '../interfaces/office-owners.interfaces';

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

/**
 * Office Owners Controller
 * Allows office owners to manage their delivery drivers
 * OFFICE_OWNER role only
 */
@ApiTags('Office Owners - Delivery Drivers')
@ApiBearerAuth('JWT-auth')
@Controller(USERS_ROUTES.BASE)
@UseGuards(AuthGuard, RolesGuard)
@Roles(UserRole.OFFICE_OWNER)
export class OfficeOwnersController {
  constructor(private readonly officeOwnersService: OfficeOwnersService) {}

  /**
   * Create a new delivery driver for the office owner
   * POST /users/deliveries
   */
  @Post(USERS_ROUTES.DELIVERIES)
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Create a new delivery driver',
    description:
      'Creates a new delivery driver under the office owner with optional profile image',
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
          description:
            'Office owner ID to assign the driver to (optional - defaults to authenticated user)',
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
  @ApiResponse({
    status: 403,
    description: 'Forbidden - requires OFFICE_OWNER role',
  })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  @ApiResponse({ status: 422, description: 'Invalid image file type or size' })
  @UseInterceptors(FileInterceptor('image'))
  async createDelivery(
    @Body() createDeliveryDto: CreateDeliveryByOfficeDto,
    @Request() req: any,
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
    const reqAny = req;
    // Use officeOwnerId from payload if provided, otherwise use authenticated user's ID
    const officeOwnerId = createDeliveryDto.officeOwnerId || reqAny.user.id;
    const delivery = await this.officeOwnersService.createDelivery(
      officeOwnerId,
      createDeliveryDto,
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
   * Get all delivery drivers belonging to the office owner
   * GET /users/deliveries?page=1&limit=10&search=john&isOnline=true
   */
  @Get(USERS_ROUTES.DELIVERIES)
  @ApiOperation({
    summary: 'Get all delivery drivers (own only)',
    description:
      'Returns all delivery drivers belonging to the authenticated office owner with pagination, filtering, and search support',
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
    description: 'Search by name, email or phone',
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
    description: 'List of delivery drivers with pagination',
  })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - requires OFFICE_OWNER role',
  })
  async findAllDeliveries(
    @Request() req: { user: OfficeOwnerContext },
    @Query() query: DeliveryDriverQuery,
  ) {
    const officeOwnerId = req.user.id;
    const result = await this.officeOwnersService.findAllDeliveries(
      officeOwnerId,
      query.page,
      query.limit,
      query.search,
      query.status === 'ACTIVE'
        ? true
        : query.status === 'INACTIVE'
          ? false
          : undefined,
    );
    return {
      statusCode: HttpStatus.OK,
      message: 'Operation successful',
      data: result.data,
      pagination: result.pagination,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.DELIVERIES}`,
    };
  }

  /**
   * Get one delivery driver belonging to the office owner
   * GET /users/deliveries/:id
   */
  @Get(USERS_ROUTES.DELIVERY_BY_ID)
  @ApiOperation({
    summary: 'Get one delivery driver',
    description:
      'Returns details of a specific delivery driver belonging to the office owner',
  })
  @ApiParam({
    name: 'id',
    type: Number,
    example: 15,
    description: 'Delivery driver ID',
  })
  @ApiResponse({ status: 200, description: 'Delivery driver details' })
  @ApiResponse({
    status: 403,
    description: 'Forbidden - requires OFFICE_OWNER role',
  })
  @ApiResponse({ status: 404, description: 'Delivery driver not found' })
  async findOneDelivery(
    @Param('id', ParseIntPipe) id: number,
    @Request() req: { user: OfficeOwnerContext },
  ) {
    const officeOwnerId = req.user.id;
    const delivery = await this.officeOwnersService.findOneDelivery(
      officeOwnerId,
      id,
    );
    return {
      statusCode: HttpStatus.OK,
      message: 'Operation successful',
      data: delivery,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.DELIVERIES}/${id}`,
    };
  }

  /**
   * Update delivery driver information
   * PATCH /users/deliveries/:id
   */
  @Patch(USERS_ROUTES.DELIVERY_BY_ID)
  @ApiOperation({
    summary: 'Update delivery driver',
    description:
      'Updates delivery driver information with optional image replacement',
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
  @ApiResponse({
    status: 403,
    description: 'Forbidden - requires OFFICE_OWNER role',
  })
  @ApiResponse({ status: 404, description: 'Delivery driver not found' })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  @ApiResponse({ status: 422, description: 'Invalid image file type or size' })
  @UseInterceptors(FileInterceptor('image'))
  async updateDelivery(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateDeliveryDto: UpdateDeliveryByOfficeDto,
    @Request() req: { user: OfficeOwnerContext },
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
    const officeOwnerId = req.user.id;
    const delivery = await this.officeOwnersService.updateDelivery(
      officeOwnerId,
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
   * Delete delivery driver (soft delete)
   * DELETE /users/deliveries/:id
   */
  @Delete(USERS_ROUTES.DELIVERY_BY_ID)
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Delete delivery driver',
    description: 'Soft deletes a delivery driver belonging to the office owner',
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
  @ApiResponse({
    status: 403,
    description: 'Forbidden - requires OFFICE_OWNER role',
  })
  @ApiResponse({ status: 404, description: 'Delivery driver not found' })
  async removeDelivery(
    @Param('id', ParseIntPipe) id: number,
    @Request() req: { user: OfficeOwnerContext },
  ) {
    const officeOwnerId = req.user.id;
    await this.officeOwnersService.removeDelivery(officeOwnerId, id);
    return {
      statusCode: HttpStatus.OK,
      message: 'Delivery driver deleted successfully',
      data: {},
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.DELIVERIES}/${id}`,
    };
  }
}

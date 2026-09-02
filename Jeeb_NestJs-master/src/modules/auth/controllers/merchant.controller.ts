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
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { MerchantService } from '../services/merchant.service';
import { UsersAdminService } from '../services/users-admin.service';
import { CreateMerchantDto } from '../dto/create-merchant.dto';
import { UpdateMerchantDto } from '../dto/update-merchant.dto';
import { FilterMerchantDto } from '../dto/filter-merchant.dto';
import { AdminResetPasswordDto } from '../dto/admin-reset-password.dto';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
  ApiBody,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';
import { AuthGuard } from '../../../common/guards/auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { UserRole } from '../../../common/enums/user-role.enum';
import { USERS_ROUTES } from '../../../common/constants/api-routes.constants';

@ApiTags('Merchants')
@ApiBearerAuth('JWT-auth')
@Controller(USERS_ROUTES.BASE)
@UseGuards(AuthGuard, RolesGuard)
export class MerchantController {
  constructor(
    private readonly merchantService: MerchantService,
    private readonly usersAdminService: UsersAdminService,
  ) {}

  @ApiOperation({
    summary: 'إنشاء تاجر جديد (مع صورة)',
    description:
      'إنشاء حساب تاجر جديد مع إمكانية رفع صورة الملف الشخصي. الصورة تُعالج تلقائياً إلى عدة أحجام.',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        email: {
          type: 'string',
          format: 'email',
          example: 'merchant@example.com',
        },
        password: { type: 'string', minLength: 6, example: 'password123' },
        firstName: { type: 'string', example: 'Ahmed' },
        lastName: { type: 'string', example: 'Mohammed' },
        phone: { type: 'string', example: '+966501234567' },
        countryId: { type: 'number', example: 1 },
        cityId: { type: 'number', example: 1 },
        address: { type: 'string', example: 'Riyadh, Saudi Arabia' },
        birthday: { type: 'string', format: 'date', example: '1990-01-01' },
        image: {
          type: 'string',
          format: 'binary',
          description: 'Profile image (jpg, jpeg, png, webp - max 5MB)',
        },
        restaurantName: { type: 'string', example: 'Pizza Hut' },
        location: {
          type: 'string',
          example: '{"lat": 33.5138, "lng": 36.2765}',
          description: 'Location as JSON string',
        },
      },
      required: ['email', 'password', 'firstName', 'lastName', 'phone'],
    },
  })
  @ApiResponse({ status: 201, description: 'Merchant created successfully' })
  @ApiResponse({ status: 409, description: 'Email already exists' })
  @ApiResponse({ status: 422, description: 'Invalid file type or size' })
  @Post(USERS_ROUTES.MERCHANTS)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.CREATED)
  @UseInterceptors(FileInterceptor('image'))
  async create(
    @Body() createMerchantDto: CreateMerchantDto,
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
    const merchant = await this.merchantService.create(createMerchantDto, file);
    return {
      statusCode: HttpStatus.CREATED,
      message: 'Merchant created successfully',
      data: merchant,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.MERCHANTS}`,
    };
  }

  @ApiOperation({
    summary: 'الحصول على جميع التجار',
    description: 'استرجاع قائمة التجار مع إمكانية الفلترة والتصفح والبحث',
  })
  @ApiQuery({
    name: 'page',
    required: false,
    type: Number,
    example: 1,
    description: 'رقم الصفحة',
  })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    example: 10,
    description: 'عدد العناصر في الصفحة',
  })
  @ApiQuery({
    name: 'search',
    required: false,
    type: String,
    example: 'ahmed',
    description: 'بحث بالاسم أو البريد أو الهاتف',
  })
  @ApiQuery({
    name: 'countryId',
    required: false,
    type: Number,
    example: 1,
    description: 'فلترة حسب الدولة',
  })
  @ApiQuery({
    name: 'isActive',
    required: false,
    type: Boolean,
    example: true,
    description: 'فلترة حسب الحالة',
  })
  @ApiResponse({ status: 200, description: 'Merchants retrieved successfully' })
  @Get(USERS_ROUTES.MERCHANTS)
  @Roles(UserRole.ADMIN, UserRole.CUSTOMER)
  async findAll(@Query() filterDto: FilterMerchantDto) {
    const result = await this.merchantService.findAll(filterDto);
    return {
      statusCode: HttpStatus.OK,
      message: 'Operation successful',
      data: result.data,
      pagination: result.pagination,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.MERCHANTS}`,
    };
  }

  @ApiOperation({
    summary: 'الحصول على تاجر محدد',
    description: 'استرجاع بيانات تاجر محدد بواسطة المعرف',
  })
  @ApiParam({
    name: 'id',
    type: Number,
    example: 10,
    description: 'معرف التاجر',
  })
  @ApiResponse({ status: 200, description: 'Merchant retrieved successfully' })
  @ApiResponse({ status: 404, description: 'Merchant not found' })
  @Get(USERS_ROUTES.MERCHANT_BY_ID)
  @Roles(UserRole.ADMIN, UserRole.CUSTOMER)
  async findOne(@Param('id', ParseIntPipe) id: number) {
    const merchant = await this.merchantService.findOne(id);
    return {
      statusCode: HttpStatus.OK,
      message: 'Operation successful',
      data: merchant,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.MERCHANTS}/${id}`,
    };
  }

  @ApiOperation({
    summary: 'تحديث بيانات التاجر (مع صورة)',
    description:
      'تحديث بيانات التاجر مع إمكانية تغيير الصورة. الصورة القديمة تُحذف تلقائياً.',
  })
  @ApiParam({
    name: 'id',
    type: Number,
    example: 10,
    description: 'معرف التاجر',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        firstName: { type: 'string', example: 'Updated Name' },
        lastName: { type: 'string', example: 'Updated Last Name' },
        phone: { type: 'string', example: '+966507654321' },
        password: { type: 'string', minLength: 6, example: 'newpassword123' },
        countryId: { type: 'number', example: 2 },
        cityId: { type: 'number', example: 2 },
        address: { type: 'string', example: 'Updated Address' },
        birthday: { type: 'string', format: 'date', example: '1990-05-15' },
        isActive: {
          type: 'string',
          example: 'true',
          description: 'Account active status (true/false)',
        },
        isOpen: {
          type: 'string',
          example: 'true',
          description: 'Restaurant open status (true/false)',
        },
        hidePhoneNumber: {
          type: 'string',
          example: 'false',
          description: 'Hide phone number from customers (true/false)',
        },
        image: {
          type: 'string',
          format: 'binary',
          description: 'New profile image (jpg, jpeg, png, webp - max 5MB)',
        },
        restaurantName: { type: 'string', example: 'Pizza Hut Updated' },
        location: {
          type: 'string',
          example: '{"lat": 33.5138, "lng": 36.2765}',
          description: 'Location as JSON string',
        },
      },
    },
  })
  @ApiResponse({ status: 200, description: 'Merchant updated successfully' })
  @ApiResponse({ status: 404, description: 'Merchant not found' })
  @ApiResponse({ status: 422, description: 'Invalid file type or size' })
  @Patch(USERS_ROUTES.MERCHANT_BY_ID)
  @Roles(UserRole.ADMIN)
  @UseInterceptors(FileInterceptor('image'))
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateMerchantDto: UpdateMerchantDto,
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
    const merchant = await this.merchantService.update(
      id,
      updateMerchantDto,
      file,
    );
    return {
      statusCode: HttpStatus.OK,
      message: 'Merchant updated successfully',
      data: merchant,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.MERCHANTS}/${id}`,
    };
  }

  @ApiOperation({
    summary: 'تفعيل حساب التاجر (ADMIN)',
    description:
      'ADMIN only - تفعيل حساب التاجر عن طريق تعيين isActive إلى true',
  })
  @ApiParam({
    name: 'id',
    type: Number,
    example: 10,
    description: 'معرف التاجر',
  })
  @ApiResponse({ status: 200, description: 'Merchant activated successfully' })
  @ApiResponse({ status: 404, description: 'Merchant not found' })
  @Patch(USERS_ROUTES.MERCHANT_CONFIRM)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  async confirmMerchant(@Param('id', ParseIntPipe) id: number) {
    const merchant = await this.merchantService.confirmMerchant(id);
    return {
      statusCode: HttpStatus.OK,
      message: 'تم تفعيل حساب التاجر بنجاح',
      data: merchant,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.MERCHANTS}/${id}/confirm`,
    };
  }

  @ApiOperation({
    summary: 'إعادة تعيين كلمة مرور التاجر (ADMIN)',
    description:
      'ADMIN only - إعادة تعيين كلمة مرور التاجر بدون الحاجة لكلمة المرور القديمة',
  })
  @ApiParam({
    name: 'id',
    type: Number,
    example: 10,
    description: 'معرف التاجر',
  })
  @ApiResponse({ status: 200, description: 'Password reset successfully' })
  @ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' })
  @ApiResponse({ status: 404, description: 'Merchant not found' })
  @Patch(USERS_ROUTES.MERCHANT_RESET_PASSWORD)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  async resetMerchantPassword(
    @Param('id', ParseIntPipe) id: number,
    @Body() adminResetPasswordDto: AdminResetPasswordDto,
  ) {
    const merchant = await this.usersAdminService.resetPassword(
      id,
      adminResetPasswordDto.password,
    );
    return {
      statusCode: HttpStatus.OK,
      message: 'Password reset successfully',
      data: merchant,
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.MERCHANTS}/${id}/reset-password`,
    };
  }

  @ApiOperation({
    summary: 'حذف التاجر (مع حذف الصورة)',
    description:
      'حذف تاجر نهائياً مع حذف الصورة المرتبطة به. لا يمكن حذف تاجر يملك مطاعم.',
  })
  @ApiParam({
    name: 'id',
    type: Number,
    example: 10,
    description: 'معرف التاجر',
  })
  @ApiResponse({ status: 200, description: 'Merchant deleted successfully' })
  @ApiResponse({ status: 404, description: 'Merchant not found' })
  @ApiResponse({
    status: 403,
    description: 'Cannot delete merchant with associated restaurants',
  })
  @Delete(USERS_ROUTES.MERCHANT_BY_ID)
  @Roles(UserRole.ADMIN)
  @HttpCode(HttpStatus.OK)
  async remove(@Param('id', ParseIntPipe) id: number) {
    await this.merchantService.remove(id);
    return {
      statusCode: HttpStatus.OK,
      message: 'Merchant deleted successfully',
      data: {},
      timestamp: new Date().toISOString(),
      path: `/api/v1/${USERS_ROUTES.BASE}/${USERS_ROUTES.MERCHANTS}/${id}`,
    };
  }
}

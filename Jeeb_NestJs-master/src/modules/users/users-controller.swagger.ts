import { applyDecorators } from '@nestjs/common';
import {
  ApiOperation,
  ApiResponse,
  ApiBody,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
} from '@nestjs/swagger';

// ────────────────────────── Customers ──────────────────────────

export function ApiFindAllCustomersEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'قائمة العملاء (ADMIN)',
      description: 'ADMIN only - استرجاع قائمة العملاء مع إمكانية البحث والتصفية',
    }),
    ApiQuery({
      name: 'page',
      required: false,
      type: Number,
      example: 1,
      description: 'رقم الصفحة',
    }),
    ApiQuery({
      name: 'limit',
      required: false,
      type: Number,
      example: 10,
      description: 'عدد العناصر في الصفحة',
    }),
    ApiQuery({
      name: 'search',
      required: false,
      type: String,
      example: 'john',
      description: 'بحث بالاسم أو البريد أو الهاتف',
    }),
    ApiQuery({
      name: 'countryId',
      required: false,
      type: Number,
      example: 1,
      description: 'فلترة حسب الدولة',
    }),
    ApiQuery({
      name: 'cityId',
      required: false,
      type: Number,
      example: 1,
      description: 'فلترة حسب المدينة',
    }),
    ApiResponse({
      status: 200,
      description: 'قائمة العملاء',
      schema: {
        example: {
          data: [
            {
              id: 1,
              firstName: 'John',
              lastName: 'Doe',
              email: 'john@example.com',
              phone: '+963912345678',
              role: 'CUSTOMER',
              isActive: true,
              isOnline: false,
              verifiedAt: '2026-01-01T00:00:00.000Z',
              country: { id: 1, name: 'Syria' },
              city: { id: 1, name: 'Damascus' },
              createdAt: '2026-01-01T00:00:00.000Z',
            },
          ],
          total: 1,
          page: 1,
          limit: 10,
        },
      },
    }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
  );
}

export function ApiFindOneCustomerEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'بيانات عميل (ADMIN)',
      description: 'ADMIN only - استرجاع بيانات عميل محدد مع العلاقات',
    }),
    ApiParam({
      name: 'id',
      type: Number,
      example: 1,
      description: 'معرف العميل',
    }),
    ApiResponse({
      status: 200,
      description: 'بيانات العميل',
      schema: {
        example: {
          id: 1,
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          phone: '+963912345678',
          role: 'CUSTOMER',
          isActive: true,
          isOnline: false,
          verifiedAt: '2026-01-01T00:00:00.000Z',
          country: { id: 1, name: 'Syria' },
          city: { id: 1, name: 'Damascus' },
          images: [],
          merchant: null,
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        },
      },
    }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 404, description: 'User not found' }),
  );
}

export function ApiCreateCustomerEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'إنشاء عميل (ADMIN)',
      description: 'ADMIN only - إنشاء حساب عميل جديد',
    }),
    ApiBody({
      schema: {
        type: 'object',
        properties: {
          email: { type: 'string', format: 'email', example: 'customer@example.com' },
          password: { type: 'string', minLength: 6, example: 'password123' },
          firstName: { type: 'string', example: 'John' },
          lastName: { type: 'string', example: 'Doe' },
          phone: { type: 'string', example: '+963912345678' },
          countryId: { type: 'number', example: 1 },
          cityId: { type: 'number', example: 1 },
          areaId: { type: 'number', example: 1 },
          notificationChannel: {
            type: 'string',
            enum: ['EMAIL', 'WHATSAPP', 'SMS'],
            example: 'EMAIL',
          },
          address: { type: 'string', example: 'Damascus, Syria' },
        },
        required: ['email', 'password', 'firstName', 'lastName', 'phone'],
      },
    }),
    ApiResponse({
      status: 201,
      description: 'تم إنشاء العميل بنجاح',
      schema: {
        example: {
          id: 1,
          firstName: 'John',
          lastName: 'Doe',
          email: 'customer@example.com',
          phone: '+963912345678',
          role: 'CUSTOMER',
          verifiedAt: '2026-01-01T00:00:00.000Z',
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        },
      },
    }),
    ApiResponse({ status: 400, description: 'Validation error' }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 409, description: 'Email already exists' }),
  );
}

export function ApiUpdateCustomerEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'تحديث عميل (ADMIN)',
      description: 'ADMIN only - تحديث بيانات عميل محدد',
    }),
    ApiParam({
      name: 'id',
      type: Number,
      example: 1,
      description: 'معرف العميل',
    }),
    ApiBody({
      schema: {
        type: 'object',
        properties: {
          email: { type: 'string', format: 'email', example: 'updated@example.com' },
          password: { type: 'string', minLength: 6, example: 'newpassword123' },
          firstName: { type: 'string', example: 'John Updated' },
          lastName: { type: 'string', example: 'Doe Updated' },
          phone: { type: 'string', example: '+963912345679' },
          countryId: { type: 'number', example: 2 },
          cityId: { type: 'number', example: 2 },
          areaId: { type: 'number', example: 2 },
          notificationChannel: {
            type: 'string',
            enum: ['EMAIL', 'WHATSAPP', 'SMS'],
            example: 'WHATSAPP',
          },
          address: { type: 'string', example: 'Aleppo, Syria' },
        },
      },
    }),
    ApiResponse({
      status: 200,
      description: 'تم تحديث العميل بنجاح',
      schema: {
        example: {
          id: 1,
          firstName: 'John Updated',
          lastName: 'Doe Updated',
          email: 'updated@example.com',
          phone: '+963912345679',
          role: 'CUSTOMER',
          isActive: true,
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-06-29T00:00:00.000Z',
        },
      },
    }),
    ApiResponse({ status: 400, description: 'Validation error' }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 404, description: 'User not found' }),
  );
}

export function ApiRemoveCustomerEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'حذف عميل (ADMIN)',
      description: 'ADMIN only - حذف عميل. يتم الحذف نهائياً مع الصور والطلبات المعلقة والمفضلة.',
    }),
    ApiParam({
      name: 'id',
      type: Number,
      example: 1,
      description: 'معرف العميل',
    }),
    ApiResponse({ status: 200, description: 'تم حذف العميل بنجاح' }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 404, description: 'User not found' }),
  );
}

// ────────────────────────── Merchants ──────────────────────────

export function ApiFindAllMerchantsEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'قائمة التجار (ADMIN)',
      description: 'ADMIN only - استرجاع قائمة التجار مع إمكانية البحث والتصفية',
    }),
    ApiQuery({
      name: 'page',
      required: false,
      type: Number,
      example: 1,
      description: 'رقم الصفحة',
    }),
    ApiQuery({
      name: 'limit',
      required: false,
      type: Number,
      example: 10,
      description: 'عدد العناصر في الصفحة',
    }),
    ApiQuery({
      name: 'search',
      required: false,
      type: String,
      example: 'ahmed',
      description: 'بحث بالاسم أو البريد أو الهاتف',
    }),
    ApiQuery({
      name: 'countryId',
      required: false,
      type: Number,
      example: 1,
      description: 'فلترة حسب الدولة',
    }),
    ApiQuery({
      name: 'cityId',
      required: false,
      type: Number,
      example: 1,
      description: 'فلترة حسب المدينة',
    }),
    ApiQuery({
      name: 'areaId',
      required: false,
      type: Number,
      example: 1,
      description: 'فلترة حسب المنطقة',
    }),
    ApiQuery({
      name: 'isActive',
      required: false,
      type: Boolean,
      example: true,
      description: 'فلترة حسب حالة التفعيل',
    }),
    ApiQuery({
      name: 'isOpen',
      required: false,
      type: Boolean,
      example: true,
      description: 'فلترة حسب حالة الفتح',
    }),
    ApiResponse({
      status: 200,
      description: 'قائمة التجار',
      schema: {
        example: {
          data: [
            {
              id: 10,
              firstName: 'Ahmed',
              lastName: 'Mohammed',
              email: 'merchant@example.com',
              phone: '+966501234567',
              role: 'MERCHANT',
              isActive: true,
              isOnline: false,
              verifiedAt: '2026-01-01T00:00:00.000Z',
              country: { id: 1, name: 'Saudi Arabia' },
              city: { id: 1, name: 'Riyadh' },
              area: { id: 1, name: 'الملز' },
              merchant: {
                id: 1,
                restaurantName: 'Pizza Hut',
                isOpen: true,
                description: 'Best pizza in town',
              },
              createdAt: '2026-01-01T00:00:00.000Z',
            },
          ],
          total: 1,
          page: 1,
          limit: 10,
        },
      },
    }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
  );
}

export function ApiFindOneMerchantEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'بيانات تاجر (ADMIN)',
      description: 'ADMIN only - استرجاع بيانات تاجر محدد مع العلاقات',
    }),
    ApiParam({
      name: 'id',
      type: Number,
      example: 10,
      description: 'معرف التاجر',
    }),
    ApiResponse({
      status: 200,
      description: 'بيانات التاجر مع الملف التجاري',
      schema: {
        example: {
          user: {
            id: 10,
            firstName: 'Ahmed',
            lastName: 'Mohammed',
            email: 'merchant@example.com',
            phone: '+966501234567',
            role: 'MERCHANT',
            isActive: true,
            verifiedAt: '2026-01-01T00:00:00.000Z',
            images: [],
          },
          id: 1,
          restaurantName: 'Pizza Hut',
          isOpen: true,
          description: 'Best pizza in town',
        },
      },
    }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 404, description: 'Merchant not found' }),
  );
}

export function ApiCreateMerchantEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'إنشاء تاجر (ADMIN)',
      description: 'ADMIN only - إنشاء حساب تاجر جديد',
    }),
    ApiBody({
      schema: {
        type: 'object',
        properties: {
          email: { type: 'string', format: 'email', example: 'merchant@example.com' },
          password: { type: 'string', minLength: 6, example: 'password123' },
          firstName: { type: 'string', example: 'Ahmed' },
          lastName: { type: 'string', example: 'Mohammed' },
          phone: { type: 'string', example: '+966501234567' },
          countryId: { type: 'number', example: 1 },
          cityId: { type: 'number', example: 1 },
          areaId: { type: 'number', example: 1 },
          notificationChannel: {
            type: 'string',
            enum: ['EMAIL', 'WHATSAPP', 'SMS'],
            example: 'EMAIL',
          },
          address: { type: 'string', example: 'Riyadh, Saudi Arabia' },
        },
        required: ['email', 'password', 'firstName', 'lastName', 'phone'],
      },
    }),
    ApiResponse({
      status: 201,
      description: 'تم إنشاء التاجر بنجاح',
      schema: {
        example: {
          id: 10,
          firstName: 'Ahmed',
          lastName: 'Mohammed',
          email: 'merchant@example.com',
          phone: '+966501234567',
          role: 'MERCHANT',
          verifiedAt: '2026-01-01T00:00:00.000Z',
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        },
      },
    }),
    ApiResponse({ status: 400, description: 'Validation error' }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 409, description: 'Email already exists' }),
  );
}

export function ApiUpdateMerchantEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'تحديث تاجر (ADMIN)',
      description: 'ADMIN only - تحديث بيانات تاجر محدد مع إمكانية رفع صورة',
    }),
    ApiParam({
      name: 'id',
      type: Number,
      example: 10,
      description: 'معرف التاجر',
    }),
    ApiBody({
      schema: {
        type: 'object',
        properties: {
          email: { type: 'string', format: 'email', example: 'updated@example.com' },
          password: { type: 'string', minLength: 6, example: 'newpassword123' },
          firstName: { type: 'string', example: 'Ahmed Updated' },
          lastName: { type: 'string', example: 'Mohammed Updated' },
          phone: { type: 'string', example: '+966507654321' },
          countryId: { type: 'number', example: 2 },
          cityId: { type: 'number', example: 2 },
          areaId: { type: 'number', example: 2 },
          notificationChannel: {
            type: 'string',
            enum: ['EMAIL', 'WHATSAPP', 'SMS'],
            example: 'WHATSAPP',
          },
          address: { type: 'string', example: 'Jeddah, Saudi Arabia' },
          restaurantName: { type: 'string', example: 'Pizza Hut Updated' },
          description: { type: 'string', example: 'Updated description' },
          isActive: { type: 'boolean', example: true },
          isOpen: { type: 'boolean', example: true },
          hidePhoneNumber: { type: 'boolean', example: false },
          currentLat: { type: 'number', example: 24.7136 },
          currentLng: { type: 'number', example: 46.6753 },
          location: {
            type: 'string',
            example: '{"lat": 24.7136, "lng": 46.6753}',
            description: 'Location as JSON string',
          },
          image: {
            type: 'string',
            format: 'binary',
            description: 'صورة الملف الشخصي (jpeg, png, gif, webp - max 5MB)',
          },
        },
      },
    }),
    ApiResponse({
      status: 200,
      description: 'تم تحديث التاجر بنجاح',
      schema: {
        example: {
          id: 10,
          firstName: 'Ahmed Updated',
          lastName: 'Mohammed Updated',
          email: 'updated@example.com',
          phone: '+966507654321',
          role: 'MERCHANT',
          isActive: true,
          currentLat: 24.7136,
          currentLng: 46.6753,
          location: { lat: 24.7136, lng: 46.6753 },
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-06-29T00:00:00.000Z',
        },
      },
    }),
    ApiResponse({ status: 400, description: 'Validation error' }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 404, description: 'User not found' }),
  );
}

export function ApiRemoveMerchantEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'حذف تاجر (ADMIN)',
      description: 'ADMIN only - حذف تاجر مع الملف التجاري المرتبط به',
    }),
    ApiParam({
      name: 'id',
      type: Number,
      example: 10,
      description: 'معرف التاجر',
    }),
    ApiResponse({
      status: 200,
      description: 'تم حذف التاجر بنجاح',
      schema: {
        example: {
          message: 'Merchant and user deleted successfully',
        },
      },
    }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 404, description: 'Merchant not found' }),
  );
}

// ────────────────────────── Deliveries (Drivers) ──────────────────────────

export function ApiFindAllDeliveriesEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'قائمة السائقين (ADMIN)',
      description: 'ADMIN only - استرجاع قائمة السائقين مع إمكانية البحث والتصفية',
    }),
    ApiQuery({
      name: 'page',
      required: false,
      type: Number,
      example: 1,
      description: 'رقم الصفحة',
    }),
    ApiQuery({
      name: 'limit',
      required: false,
      type: Number,
      example: 10,
      description: 'عدد العناصر في الصفحة',
    }),
    ApiQuery({
      name: 'search',
      required: false,
      type: String,
      example: 'khalid',
      description: 'بحث بالاسم أو البريد أو الهاتف',
    }),
    ApiQuery({
      name: 'countryId',
      required: false,
      type: Number,
      example: 1,
      description: 'فلترة حسب الدولة',
    }),
    ApiQuery({
      name: 'cityId',
      required: false,
      type: Number,
      example: 1,
      description: 'فلترة حسب المدينة',
    }),
    ApiResponse({
      status: 200,
      description: 'قائمة السائقين',
      schema: {
        example: {
          data: [
            {
              id: 20,
              firstName: 'Khalid',
              lastName: 'Ali',
              email: 'delivery@example.com',
              phone: '+966501234568',
              role: 'DELIVERY',
              isActive: true,
              isOnline: true,
              verifiedAt: '2026-01-01T00:00:00.000Z',
              currentLat: 24.7136,
              currentLng: 46.6753,
              country: { id: 1, name: 'Saudi Arabia' },
              city: { id: 1, name: 'Riyadh' },
              createdAt: '2026-01-01T00:00:00.000Z',
            },
          ],
          total: 1,
          page: 1,
          limit: 10,
        },
      },
    }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
  );
}

export function ApiFindOneDeliveryEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'بيانات سائق (ADMIN)',
      description: 'ADMIN only - استرجاع بيانات سائق محدد مع العلاقات',
    }),
    ApiParam({
      name: 'id',
      type: Number,
      example: 20,
      description: 'معرف السائق',
    }),
    ApiResponse({
      status: 200,
      description: 'بيانات السائق',
      schema: {
        example: {
          id: 20,
          firstName: 'Khalid',
          lastName: 'Ali',
          email: 'delivery@example.com',
          phone: '+966501234568',
          role: 'DELIVERY',
          isActive: true,
          isOnline: true,
          verifiedAt: '2026-01-01T00:00:00.000Z',
          currentLat: 24.7136,
          currentLng: 46.6753,
          country: { id: 1, name: 'Saudi Arabia' },
          city: { id: 1, name: 'Riyadh' },
          images: [],
          merchant: null,
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        },
      },
    }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 404, description: 'User not found' }),
  );
}

export function ApiCreateDeliveryEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'إنشاء سائق (ADMIN)',
      description: 'ADMIN only - إنشاء حساب سائق توصيل جديد',
    }),
    ApiBody({
      schema: {
        type: 'object',
        properties: {
          email: { type: 'string', format: 'email', example: 'delivery@example.com' },
          password: { type: 'string', minLength: 6, example: 'password123' },
          firstName: { type: 'string', example: 'Khalid' },
          lastName: { type: 'string', example: 'Ali' },
          phone: { type: 'string', example: '+966501234568' },
          countryId: { type: 'number', example: 1 },
          cityId: { type: 'number', example: 1 },
          areaId: { type: 'number', example: 1 },
          notificationChannel: {
            type: 'string',
            enum: ['EMAIL', 'WHATSAPP', 'SMS'],
            example: 'EMAIL',
          },
          address: { type: 'string', example: 'Riyadh, Saudi Arabia' },
          isActive: { type: 'boolean', example: true },
          isOnline: { type: 'boolean', example: true },
          currentLat: { type: 'number', example: 24.7136 },
          currentLng: { type: 'number', example: 46.6753 },
          location: {
            type: 'object',
            example: { lat: 24.7136, lng: 46.6753 },
          },
          birthday: { type: 'string', format: 'date', example: '1990-05-15' },
          firebaseToken: { type: 'string', example: 'fcm_token_here' },
        },
        required: ['email', 'password', 'firstName', 'lastName', 'phone'],
      },
    }),
    ApiResponse({
      status: 201,
      description: 'تم إنشاء السائق بنجاح',
      schema: {
        example: {
          id: 20,
          firstName: 'Khalid',
          lastName: 'Ali',
          email: 'delivery@example.com',
          phone: '+966501234568',
          role: 'DELIVERY',
          isActive: true,
          isOnline: true,
          verifiedAt: '2026-01-01T00:00:00.000Z',
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-01-01T00:00:00.000Z',
        },
      },
    }),
    ApiResponse({ status: 400, description: 'Validation error' }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 409, description: 'Email already exists' }),
  );
}

export function ApiUpdateDeliveryEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'تحديث سائق (ADMIN)',
      description: 'ADMIN only - تحديث بيانات سائق توصيل محدد',
    }),
    ApiParam({
      name: 'id',
      type: Number,
      example: 20,
      description: 'معرف السائق',
    }),
    ApiBody({
      schema: {
        type: 'object',
        properties: {
          email: { type: 'string', format: 'email', example: 'updated@example.com' },
          password: { type: 'string', minLength: 6, example: 'newpassword123' },
          firstName: { type: 'string', example: 'Khalid Updated' },
          lastName: { type: 'string', example: 'Ali Updated' },
          phone: { type: 'string', example: '+966507654321' },
          countryId: { type: 'number', example: 2 },
          cityId: { type: 'number', example: 2 },
          areaId: { type: 'number', example: 2 },
          notificationChannel: {
            type: 'string',
            enum: ['EMAIL', 'WHATSAPP', 'SMS'],
            example: 'WHATSAPP',
          },
          address: { type: 'string', example: 'Jeddah, Saudi Arabia' },
          isActive: { type: 'boolean', example: true },
          isOnline: { type: 'boolean', example: true },
          currentLat: { type: 'number', example: 24.7136 },
          currentLng: { type: 'number', example: 46.6753 },
          location: {
            type: 'object',
            example: { lat: 24.7136, lng: 46.6753 },
          },
          birthday: { type: 'string', format: 'date', example: '1990-05-15' },
          firebaseToken: { type: 'string', example: 'new_fcm_token' },
        },
      },
    }),
    ApiResponse({
      status: 200,
      description: 'تم تحديث السائق بنجاح',
      schema: {
        example: {
          id: 20,
          firstName: 'Khalid Updated',
          lastName: 'Ali Updated',
          email: 'updated@example.com',
          phone: '+966507654321',
          role: 'DELIVERY',
          isActive: true,
          isOnline: true,
          createdAt: '2026-01-01T00:00:00.000Z',
          updatedAt: '2026-06-29T00:00:00.000Z',
        },
      },
    }),
    ApiResponse({ status: 400, description: 'Validation error' }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 404, description: 'User not found' }),
  );
}

export function ApiRemoveDeliveryEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'حذف سائق (ADMIN)',
      description:
        'ADMIN only - حذف سائق توصيل. يمنع الحذف إذا كان لدى السائق مهام توصيل نشطة.',
    }),
    ApiParam({
      name: 'id',
      type: Number,
      example: 20,
      description: 'معرف السائق',
    }),
    ApiResponse({
      status: 200,
      description: 'تم حذف السائق بنجاح',
      schema: {
        example: {
          message: 'Delivery user deleted successfully',
        },
      },
    }),
    ApiResponse({
      status: 400,
      description: 'Cannot delete account while on active delivery mission',
    }),
    ApiResponse({ status: 401, description: 'Unauthorized' }),
    ApiResponse({ status: 403, description: 'Forbidden - requires ADMIN role' }),
    ApiResponse({ status: 404, description: 'User not found' }),
  );
}

// ────────────────────────── Toggle Open ──────────────────────────

export function ApiToggleMerchantOpenEndpoint() {
  return applyDecorators(
    ApiBearerAuth('JWT-auth'),
    ApiOperation({
      summary: 'تبديل حالة الفتح (ADMIN / MERCHANT)',
      description: 'ADMIN or MERCHANT - تبديل حالة isOpen للتاجر. معطل حالياً - يُرجى استخدام /merchants/user/:id/toggle-open',
    }),
    ApiParam({
      name: 'id',
      type: Number,
      example: 10,
      description: 'معرف التاجر',
    }),
    ApiResponse({
      status: 400,
      description: 'هذا الـ endpoint معطل - يُرجى استخدام endpoint آخر',
      schema: {
        example: {
          statusCode: 400,
          message: 'Please use /merchants/user/:id/toggle-open endpoint instead',
        },
      },
    }),
  );
}

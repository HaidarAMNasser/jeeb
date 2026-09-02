import { applyDecorators } from '@nestjs/common';
import {
  ApiOperation,
  ApiResponse,
  ApiBody,
  ApiConsumes,
  ApiBearerAuth,
} from '@nestjs/swagger';
import { VerifyAccountDto } from './dto/verify-account.dto';
import { ResendOtpDto } from './dto/resend-otp.dto';
import { LoginDto } from './dto/login.dto';
import { GuestLoginDto } from './dto/guest-login.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';

export function ApiRegisterEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'تسجيل مستخدم جديد',
      description: 'إنشاء حساب جديد مع إمكانية رفع صورة الملف الشخصي',
    }),
    ApiConsumes('multipart/form-data'),
    ApiBody({
      schema: {
        type: 'object',
        properties: {
          email: { type: 'string', format: 'email', example: 'user@example.com' },
          password: { type: 'string', minLength: 6, example: 'password123' },
          firstName: { type: 'string', example: 'John' },
          lastName: { type: 'string', example: 'Doe' },
          phone: { type: 'string', example: '+963912345678' },
          countryId: { type: 'number', example: 1 },
          cityId: { type: 'number', example: 1 },
          address: { type: 'string', example: 'Damascus, Syria' },
          birthday: { type: 'string', format: 'date', example: '1990-01-01' },
          notificationChannel: {
            type: 'string',
            enum: ['SMS', 'EMAIL', 'BOTH'],
            example: 'SMS',
          },
          role: {
            type: 'string',
            enum: ['CUSTOMER', 'DELIVERY', 'MERCHANT'],
            example: 'CUSTOMER',
          },
          restaurantName: {
            type: 'string',
            example: 'مطعم البرغر اللذيذ',
            description: 'Required for MERCHANT role',
          },
          location: {
            type: 'object',
            example: { lat: 33.5138, lng: 36.2765 },
            description: 'Geographic location (lat/lng)',
          },
          image: {
            type: 'string',
            format: 'binary',
            description:
              'Profile image for CUSTOMER or MERCHANT (jpg, jpeg, png, webp - max 5MB)',
          },
          images: {
            type: 'array',
            items: {
              type: 'string',
              format: 'binary',
            },
            description:
              'Profile images for DELIVERY roles (max 3 images, 5MB each)',
          },
        },
        required: ['email', 'password', 'firstName', 'lastName', 'phone'],
      },
    }),
    ApiResponse({
      status: 201,
      description: 'User registered successfully (DELIVERY / MERCHANT)',
      schema: {
        example: {
          message:
            'تم تقديم طلب التسجيل بنجاح. قيد المراجعة من قبل المدير. يرجى التحقق من حسابك باستخدام الرمز المرسل إلى رقم الهاتف.',
          data: {
            message:
              'تم تقديم طلب التسجيل بنجاح. قيد المراجعة من قبل المدير. يرجى التحقق من حسابك باستخدام الرمز المرسل إلى رقم الهاتف.',
          },
        },
      },
    }),
    ApiResponse({
      status: 400,
      description: 'Customer registration disabled - use phone-first flow',
      schema: {
        example: {
          message:
            'Customer registration is now done via the phone-first flow. Please use POST /auth/register/customer/init to start.',
          error: 'Bad Request',
          statusCode: 400,
        },
      },
    }),
    ApiResponse({
      status: 409,
      description: 'Email already exists',
      schema: {
        example: {
          message: 'Email already registered',
          error: 'Conflict',
          statusCode: 409,
        },
      },
    }),
    ApiResponse({
      status: 422,
      description: 'Invalid file type or size',
      schema: {
        example: {
          message: 'File size too large. Max is 5MB',
          error: 'Unprocessable Entity',
          statusCode: 422,
        },
      },
    }),
  );
}

export function ApiVerifyEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'تأكيد الحساب',
      description: 'تأكيد الحساب باستخدام كود OTP المرسل',
    }),
    ApiBody({ type: VerifyAccountDto }),
    ApiResponse({
      status: 200,
      description: 'Account verified successfully',
      schema: {
        example: {
          message: 'Account verified successfully.',
          data: {
            message: 'Account verified successfully.',
            access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
            user: {
              id: 1,
              email: 'user@example.com',
              firstName: 'John',
              lastName: 'Doe',
              role: 'CUSTOMER',
              verifiedAt: '2026-06-07T12:00:00.000Z',
            },
          },
        },
      },
    }),
    ApiResponse({
      status: 400,
      description: 'Invalid OTP code',
      schema: {
        example: {
          message: 'Invalid OTP code',
          error: 'Bad Request',
          statusCode: 400,
        },
      },
    }),
  );
}

export function ApiResendOtpEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'إعادة إرسال OTP',
      description: 'إعادة إرسال كود التأكيد للبريد الإلكتروني',
    }),
    ApiBody({ type: ResendOtpDto }),
    ApiResponse({
      status: 200,
      description: 'OTP sent successfully',
      schema: {
        example: {
          message: 'OTP resent successfully to your email.',
          data: {
            message: 'OTP resent successfully to your email.',
          },
        },
      },
    }),
    ApiResponse({
      status: 400,
      description: 'OTP rate limit exceeded',
      schema: {
        example: {
          message: 'Too many OTP requests, please try again later',
          error: 'Bad Request',
          statusCode: 400,
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'User not found',
      schema: {
        example: {
          message: 'User not found',
          error: 'Not Found',
          statusCode: 404,
        },
      },
    }),
  );
}

export function ApiLoginEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'تسجيل الدخول',
      description:
        'تسجيل الدخول باستخدام البريد الإلكتروني أو رقم الهاتف وكلمة المرور. يجب تقديم حقل email أو phone (أحدهما على الأقل).',
    }),
    ApiBody({ type: LoginDto }),
    ApiResponse({
      status: 200,
      description: 'Login successful',
      schema: {
        example: {
          access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
          user: {
            id: 1,
            email: 'user@example.com',
            firstName: 'John',
            lastName: 'Doe',
            role: 'CUSTOMER',
          },
        },
      },
    }),
    ApiResponse({
      status: 401,
      description: 'Invalid credentials or account not verified',
      schema: {
        example: {
          message: 'Invalid credentials',
          error: 'Unauthorized',
          statusCode: 401,
        },
      },
    }),
  );
}

export function ApiGuestLoginEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'تسجيل الدخول كزائر',
      description: 'تسجيل الدخول باستخدام Firebase Anonymous Token',
    }),
    ApiBody({ type: GuestLoginDto }),
    ApiResponse({
      status: 200,
      description: 'Guest Login successful',
      schema: {
        example: {
          access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
          user: {
            id: 1,
            firstName: 'Guest',
            lastName: 'User',
            role: 'CUSTOMER',
            is_guest: true,
            image: null,
            imageId: null,
          },
        },
      },
    }),
    ApiResponse({
      status: 403,
      description: 'Invalid Firebase Token',
      schema: {
        example: {
          statusCode: 403,
          message: 'Invalid Firebase Token',
          error: 'INVALID_FIREBASE_TOKEN',
          code: 1010,
        },
      },
    }),
  );
}

export function ApiForgotPasswordEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'نسيت كلمة المرور',
      description: 'طلب إعادة تعيين كلمة المرور - يتم إرسال رابط/كود للبريد',
    }),
    ApiBody({ type: ForgotPasswordDto }),
    ApiResponse({
      status: 200,
      description: 'Reset instructions sent',
      schema: {
        example: {
          message: 'OTP sent successfully to your email.',
          data: {
            message: 'OTP sent successfully to your email.',
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'Email not found',
      schema: {
        example: {
          message: 'User not found',
          error: 'Not Found',
          statusCode: 404,
        },
      },
    }),
  );
}

export function ApiResetPasswordEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'إعادة تعيين كلمة المرور',
      description: 'تعيين كلمة مرور جديدة باستخدام كود التأكيد',
    }),
    ApiBody({ type: ResetPasswordDto }),
    ApiResponse({
      status: 200,
      description: 'Password reset successfully',
      schema: {
        example: {
          message: 'Password reset successfully. You can now login.',
          data: {
            message: 'Password reset successfully. You can now login.',
          },
        },
      },
    }),
    ApiResponse({
      status: 400,
      description: 'Invalid OTP code',
      schema: {
        example: {
          message: 'Invalid OTP code',
          error: 'Bad Request',
          statusCode: 400,
        },
      },
    }),
  );
}

export function ApiLogoutEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'تسجيل الخروج',
      description: 'تسجيل خروج المستخدم وإبطال التوكن',
    }),
    ApiBearerAuth('JWT-auth'),
    ApiResponse({
      status: 200,
      description: 'Logout successful',
      schema: {
        example: {
          message: 'Logged out successfully',
        },
      },
    }),
    ApiResponse({
      status: 401,
      description: 'Unauthorized',
      schema: {
        example: {
          message: 'Unauthorized',
          error: 'Unauthorized',
          statusCode: 401,
        },
      },
    }),
  );
}

export function ApiGetProfileEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'الحصول على الملف الشخصي',
      description: 'استرجاع بيانات المستخدم الحالي',
    }),
    ApiBearerAuth('JWT-auth'),
    ApiResponse({
      status: 200,
      description: 'Profile retrieved successfully',
      schema: {
        example: {
          id: 1,
          email: 'user@example.com',
          firstName: 'John',
          lastName: 'Doe',
          role: 'CUSTOMER',
          image: {
            url: 'https://example.com/image.jpg',
          },
        },
      },
    }),
    ApiResponse({
      status: 401,
      description: 'Unauthorized',
      schema: {
        example: {
          message: 'Unauthorized',
          error: 'Unauthorized',
          statusCode: 401,
        },
      },
    }),
  );
}

export function ApiUpdateProfileEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'تحديث الملف الشخصي',
      description: 'تحديث بيانات المستخدم مع إمكانية تغيير الصورة',
    }),
    ApiBearerAuth('JWT-auth'),
    ApiConsumes('multipart/form-data'),
    ApiBody({
      schema: {
        type: 'object',
        properties: {
          firstName: { type: 'string', example: 'Updated Name' },
          lastName: { type: 'string', example: 'Updated Last Name' },
          phone: { type: 'string', example: '+963987654321' },
          countryId: { type: 'number', example: 2 },
          cityId: { type: 'number', example: 2 },
          address: { type: 'string', example: 'Updated Address' },
          birthday: { type: 'string', format: 'date', example: '1990-05-15' },
          image: {
            type: 'array',
            items: {
              type: 'string',
              format: 'binary',
            },
            description:
              'New profile images (jpg, jpeg, png, webp - max 5MB each. For delivery roles: max 3 images allowed. For other roles: only first image is used)',
          },
        },
      },
    }),
    ApiResponse({
      status: 200,
      description: 'Profile updated successfully',
      schema: {
        example: {
          id: 1,
          email: 'user@example.com',
          firstName: 'Updated Name',
          lastName: 'Updated Last Name',
          role: 'CUSTOMER',
        },
      },
    }),
    ApiResponse({
      status: 401,
      description: 'Unauthorized',
      schema: {
        example: {
          message: 'Unauthorized',
          error: 'Unauthorized',
          statusCode: 401,
        },
      },
    }),
    ApiResponse({
      status: 422,
      description: 'Invalid file type or size',
      schema: {
        example: {
          message: 'File size too large. Max is 5MB',
          error: 'Unprocessable Entity',
          statusCode: 422,
        },
      },
    }),
  );
}

export function ApiUpdateFirebaseTokenEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'تحديث Firebase Token',
      description:
        'تحديث FCM token لكل الأدوار، وتوليد Firebase Custom Token لدور DELIVERY فقط',
    }),
    ApiBearerAuth('JWT-auth'),
    ApiResponse({
      status: 201,
      description: 'Firebase token updated successfully',
      schema: {
        example: {
          success: true,
          fcmTokenUpdated: true,
          firebaseUid: 'delivery_12',
          customToken: 'eyJhbGciOiJSUzI1NiIsImtpZCI6I...',
        },
      },
    }),
  );
}

export function ApiDeleteProfileEndpoint() {
  return applyDecorators(
    ApiOperation({
      summary: 'حذف الحساب',
      description: 'حذف حساب المستخدم نهائياً',
    }),
    ApiBearerAuth('JWT-auth'),
    ApiResponse({
      status: 200,
      description: 'Account deleted successfully',
      schema: {
        example: {
          message: 'Account deleted successfully',
        },
      },
    }),
    ApiResponse({
      status: 401,
      description: 'Unauthorized',
      schema: {
        example: {
          message: 'Unauthorized',
          error: 'Unauthorized',
          statusCode: 401,
        },
      },
    }),
  );
}

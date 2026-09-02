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
  Req,
  HttpCode,
  HttpStatus,
  UploadedFile,
  ParseFilePipeBuilder,
  Headers,
  Ip,
  Logger,
  UseInterceptors,
  UploadedFiles,
  Res,
  HttpException,
  BadRequestException,
  Request,
} from '@nestjs/common';
import {
  FileInterceptor,
  FilesInterceptor,
  FileFieldsInterceptor,
} from '@nestjs/platform-express';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { GuestLoginDto } from './dto/guest-login.dto';
import { VerifyAccountDto } from './dto/verify-account.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ResendOtpDto } from './dto/resend-otp.dto';
import { UpdateFirebaseTokenDto } from './dto/update-firebase-token.dto';
import { CustomerInitDto } from './dto/customer-init.dto';
import { CustomerCompleteRegistrationDto } from './dto/customer-complete-registration.dto';
import { ApiTags } from '@nestjs/swagger';
import { AuthGuard } from '../../common/guards/auth.guard';
import { OtpBruteForceGuard } from '../../common/guards/otp-brute-force.guard';
import { OtpAttemptInterceptor } from '../../common/interceptors/otp-attempt.interceptor';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AllowGuest } from '../../common/decorators/allow-guest.decorator';
import { User } from '../../database/entities/user.entity';
import { AUTH_ROUTES } from '../../common/constants/api-routes.constants';
import { Public } from '../../common/decorators/public.decorator';
import { LoggingInterceptor } from '../../common/interceptors/logging.interceptor';
import { UserRole } from '../../common/enums/user-role.enum';
import {
  ApiRegisterEndpoint,
  ApiVerifyEndpoint,
  ApiResendOtpEndpoint,
  ApiLoginEndpoint,
  ApiGuestLoginEndpoint,
  ApiForgotPasswordEndpoint,
  ApiResetPasswordEndpoint,
  ApiLogoutEndpoint,
  ApiGetProfileEndpoint,
  ApiUpdateProfileEndpoint,
  ApiUpdateFirebaseTokenEndpoint,
  ApiDeleteProfileEndpoint,
} from './auth-controller.swagger';

@ApiTags('Auth')
@Controller(AUTH_ROUTES.BASE)
export class AuthController {
  private readonly logger = new Logger(AuthController.name);

  constructor(private readonly authService: AuthService) {}

  @ApiRegisterEndpoint()
  @Post(AUTH_ROUTES.REGISTER)
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'image', maxCount: 1 },
        { name: 'images', maxCount: 3 },
      ],
      {
        limits: { fileSize: 5 * 1024 * 1024 },
        fileFilter: (req, file, cb) => {
          const allowedMimes = [
            'image/jpeg',
            'image/jpg',
            'image/png',
            'image/gif',
            'image/webp',
          ];
          if (allowedMimes.includes(file.mimetype.toLowerCase())) {
            cb(null, true);
          } else {
            cb(
              new HttpException(
                `Invalid file type: ${file.mimetype}. Allowed: image/jpeg, image/png, image/gif, image/webp`,
                HttpStatus.BAD_REQUEST,
              ),
              false,
            );
          }
        },
      },
    ),
    LoggingInterceptor,
  )
  @Public()
  async register(
    @Body() registerDto: RegisterDto,
    @UploadedFiles()
    files: {
      image?: Express.Multer.File[];
      images?: Express.Multer.File[];
    } | null,
  ) {
    let imageArray: Express.Multer.File[] = [];

    if (registerDto.role === UserRole.DELIVERY) {
      // For DELIVERY role: use 'images' field (plural) - up to 3 images
      imageArray = files?.images || [];
    } else {
      // For other roles: use 'image' field (singular) - only first image
      imageArray = files?.image ? [files.image[0]] : [];
    }

    return this.authService.register(registerDto, imageArray);
  }

  @Post(AUTH_ROUTES.CUSTOMER_INIT)
  @HttpCode(HttpStatus.OK)
  @Public()
  async customerInit(@Body() initDto: CustomerInitDto) {
    return this.authService.customerInit(initDto);
  }

  @Post(AUTH_ROUTES.CUSTOMER_VERIFY_PHONE)
  @HttpCode(HttpStatus.OK)
  @Public()
  async customerVerifyPhone(@Body() verifyDto: VerifyAccountDto) {
    const identifier = verifyDto.phone;
    if (!identifier) {
      throw new BadRequestException('Phone is required');
    }
    return this.authService.customerVerifyPhone(identifier, verifyDto.otp);
  }

  @Post(AUTH_ROUTES.CUSTOMER_REGISTER)
  @UseInterceptors(
    FileFieldsInterceptor([{ name: 'image', maxCount: 1 }], {
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (req, file, cb) => {
        const allowedMimes = [
          'image/jpeg',
          'image/jpg',
          'image/png',
          'image/gif',
          'image/webp',
        ];
        if (allowedMimes.includes(file.mimetype.toLowerCase())) {
          cb(null, true);
        } else {
          cb(
            new HttpException(
              `Invalid file type: ${file.mimetype}. Allowed: image/jpeg, image/png, image/gif, image/webp`,
              HttpStatus.BAD_REQUEST,
            ),
            false,
          );
        }
      },
    }),
  )
  @UseGuards(AuthGuard)
  async customerCompleteRegistration(
    @Body() dto: CustomerCompleteRegistrationDto,
    @UploadedFiles()
    files: { image?: Express.Multer.File[] } | null,
    @CurrentUser() user: User,
  ) {
    const imageArray = files?.image ? [files.image[0]] : [];
    return this.authService.customerCompleteRegistration(user.id, dto, imageArray);
  }

  @ApiVerifyEndpoint()
  @Post(AUTH_ROUTES.VERIFY)
  @Public()
  @UseGuards(OtpBruteForceGuard)
  @UseInterceptors(OtpAttemptInterceptor)
  async verify(
    @Body() verifyAccountDto: VerifyAccountDto,
    @Res({ passthrough: true }) res: any,
  ) {
    const identifier = verifyAccountDto.email || verifyAccountDto.phone;
    if (!identifier) {
      throw new BadRequestException('Email or phone is required');
    }
    const result = await this.authService.verifyAccount(
      identifier,
      verifyAccountDto.otp,
    );
    const statusCode = (result as any).statusCode || HttpStatus.OK;
    res.status(statusCode);
    return result;
  }

  @ApiResendOtpEndpoint()
  @Post(AUTH_ROUTES.RESEND_OTP)
  @HttpCode(HttpStatus.OK)
  @Public()
  async resendOtp(@Body() resendOtpDto: ResendOtpDto) {
    const identifier = resendOtpDto.email || resendOtpDto.phone;
    if (!identifier) {
      throw new BadRequestException('Email or phone is required');
    }
    return this.authService.resendOtp(identifier);
  }

  @ApiLoginEndpoint()
  @Post(AUTH_ROUTES.LOGIN)
  @HttpCode(HttpStatus.OK)
  @Public()
  async login(@Body() loginDto: LoginDto, @Request() req: any) {
    const clientIP = this.getClientIP(req);
    return this.authService.login(loginDto, clientIP);
  }

  private getClientIP(request: any): string {
    const forwarded = request.headers['x-forwarded-for'];
    if (forwarded) {
      return forwarded.toString().split(',')[0].trim();
    }
    const realIP = request.headers['x-real-ip'];
    if (realIP) {
      return realIP.toString();
    }
    return request.ip || request.socket?.remoteAddress || 'unknown';
  }

  @ApiGuestLoginEndpoint()
  @Post('guest')
  @HttpCode(HttpStatus.OK)
  @Public()
  async loginGuest(
    @Body() guestLoginDto: GuestLoginDto,
    @Ip() ip: string,
    @Headers('user-agent') userAgent: string,
    @Request() req: any,
  ) {
    const ua = userAgent || req.headers['user-agent'] || 'unknown';
    const clientIp = this.getClientIP(req) || ip;
    return this.authService.loginGuest(guestLoginDto, clientIp, ua);
  }

  @ApiForgotPasswordEndpoint()
  @Post(AUTH_ROUTES.FORGOT_PASSWORD)
  @HttpCode(HttpStatus.OK)
  @Public()
  async forgotPassword(@Body() forgotPasswordDto: ForgotPasswordDto) {
    return this.authService.forgotPassword(forgotPasswordDto);
  }

  @ApiResetPasswordEndpoint()
  @Post(AUTH_ROUTES.RESET_PASSWORD)
  @HttpCode(HttpStatus.OK)
  @Public()
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
    return this.authService.resetPassword(resetPasswordDto);
  }

  @ApiLogoutEndpoint()
  @UseGuards(AuthGuard)
  @Post(AUTH_ROUTES.LOGOUT)
  @AllowGuest()
  @HttpCode(HttpStatus.OK)
  async logout(
    @CurrentUser() user: User,
    @Headers('authorization') auth: string,
  ) {
    const token = auth.replace('Bearer ', '');
    return this.authService.logout(user, token);
  }

  @ApiGetProfileEndpoint()
  @UseGuards(AuthGuard)
  @Get(AUTH_ROUTES.PROFILE)
  async getProfile(@CurrentUser() user: User) {
    return this.authService.getProfile(user);
  }

  @ApiUpdateProfileEndpoint()
  @UseGuards(AuthGuard)
  @Patch(AUTH_ROUTES.PROFILE)
  @UseInterceptors(
    FileFieldsInterceptor(
      [
        { name: 'image', maxCount: 1 },
        { name: 'images', maxCount: 3 },
      ],
      {
        limits: { fileSize: 5 * 1024 * 1024 },
        fileFilter: (req, file, cb) => {
          const allowedMimes = [
            'image/jpeg',
            'image/jpg',
            'image/png',
            'image/gif',
            'image/webp',
          ];
          if (allowedMimes.includes(file.mimetype.toLowerCase())) {
            cb(null, true);
          } else {
            cb(
              new HttpException(
                `Invalid file type: ${file.mimetype}. Allowed: image/jpeg, image/png, image/gif, image/webp`,
                HttpStatus.BAD_REQUEST,
              ),
              false,
            );
          }
        },
      },
    ),
  )
  async updateProfile(
    @CurrentUser() user: User,
    @Body() updateProfileDto: UpdateProfileDto,
    @UploadedFiles()
    files: {
      image?: Express.Multer.File[];
      images?: Express.Multer.File[];
    } | null,
  ) {
    let imageArray: Express.Multer.File[] = [];

    if (user.role === 'DELIVERY') {
      // For DELIVERY role: use 'images' field (plural) - up to 3 images
      imageArray = files?.images || [];
    } else {
      // For other roles: use 'image' field (singular) - only first image
      imageArray = files?.image ? [files.image[0]] : [];
    }

    return this.authService.updateProfile(user, updateProfileDto, imageArray);
  }

  @ApiUpdateFirebaseTokenEndpoint()
  @Post(AUTH_ROUTES.FIREBASE_TOKEN)
  @AllowGuest()
  async updateFirebaseToken(
    @Body() body: UpdateFirebaseTokenDto,
    @CurrentUser() user: User,
  ) {
    if (!body.token && !body.firebaseToken) {
      throw new BadRequestException(
        'Either token or firebaseToken is required',
      );
    }

    const firebaseToken = (body.firebaseToken || body.token)!;
    const data = await this.authService.updateFirebaseToken(
      user,
      firebaseToken,
    );
    return { success: true, ...data };
  }

  @ApiDeleteProfileEndpoint()
  @UseGuards(AuthGuard)
  @Delete(AUTH_ROUTES.PROFILE)
  @HttpCode(HttpStatus.OK)
  async deleteProfile(@CurrentUser() user: User) {
    return this.authService.deleteProfile(user);
  }
}

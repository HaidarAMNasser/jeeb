import {
  Injectable,
  UnauthorizedException,
  HttpException,
  HttpStatus,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../../../database/entities/user.entity';
import { Image } from '../../../database/entities/image.entity';
import { FirebaseService } from '../../firebase/firebase.service';
import * as crypto from 'crypto';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../../users/users.service';
import { TokenService } from '../token.service';
import { LoginAttemptService } from '../../../common/services/login-attempt.service';
import { IPBlockService } from '../../../common/services/ip-block.service';
import { SecurityNotificationService } from '../../notifications/security-notification.service';
import { ImageProcessingService } from '../../../common/image-processing/image-processing.service';
import { StorageService } from '../../../common/storage/storage.service';
import { MerchantsService } from '../../merchants/merchants.service';
import { LoginDto } from '../dto/login.dto';
import { UserRole } from '../../../common/enums/user-role.enum';
import { GuestRedisService } from './guest-redis.service';

@Injectable()
export class LoginService {
  private readonly logger = new Logger(LoginService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly tokenService: TokenService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly loginAttemptService: LoginAttemptService,
    private readonly ipBlockService: IPBlockService,
    private readonly securityNotificationService: SecurityNotificationService,
    private readonly merchantsProfileService: MerchantsService,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly storageService: StorageService,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly firebaseService: FirebaseService,
    private readonly guestRedisService: GuestRedisService,
  ) {}

  async login(loginDto: LoginDto, ip?: string) {
    const clientIP = ip || 'unknown';

    const isEmail = !!loginDto.email;
    const identifier = isEmail
      ? loginDto.email!.toLowerCase()
      : loginDto.phone!;

    await this.checkIdentifierAndIPBlock(identifier, clientIP);

    const user = isEmail
      ? await this.usersService.findOneByEmailWithPassword(identifier)
      : await this.usersService.findOneByPhoneWithPassword(identifier);

    if (!user) {
      await this.handleFailedLogin(undefined, identifier, clientIP);
      throw this.invalidCredentialsException();
    }

    const isPasswordValid = await bcrypt.compare(
      loginDto.password,
      user.password,
    );
    if (!isPasswordValid) {
      await this.handleFailedLogin(user.id, identifier, clientIP);
      throw this.invalidCredentialsException();
    }

    await this.validateAccountStatus(user);

    await this.loginAttemptService.resetAttempts(identifier);
    await this.loginAttemptService.resetIPAttempts(clientIP);
    await this.checkNewDeviceLogin(user.id, clientIP);

    user.lastLoginAt = new Date();
    user.lastLoginIp = clientIP;
    await this.userRepository.save(user);

    if (loginDto.firebaseToken) {
      await this.usersService.updateFirebaseToken(
        user.id,
        loginDto.firebaseToken,
      );
      user.firebaseToken = loginDto.firebaseToken;
    }

    return this.buildLoginResponse(user);
  }

  private async checkAccountBlock(email: string): Promise<void> {
    const activeBlock = await this.loginAttemptService.hasActiveBlock(email);
    if (!activeBlock) return;

    if (activeBlock.isPermanent) {
      throw new HttpException(
        {
          message:
            'Your account has been permanently blocked due to repeated failed login attempts. Please contact support.',
          error: 'ACCOUNT_PERMANENTLY_BLOCKED',
          code: 1005,
        },
        HttpStatus.FORBIDDEN,
      );
    }

    const remainingTime = activeBlock.expiresAt
      ? activeBlock.expiresAt.getTime() - Date.now()
      : 0;

    if (remainingTime > 0) {
      const hoursLeft = Math.ceil(remainingTime / (1000 * 60 * 60));
      throw new HttpException(
        {
          message: 'Account is temporarily locked',
          error: 'ACCOUNT_LOCKED',
          code: 1005,
          blockLevel: activeBlock.blockLevel,
          expiresAt: activeBlock.expiresAt,
          tryAgainIn:
            hoursLeft > 24
              ? `${Math.ceil(hoursLeft / 24)} days`
              : `${hoursLeft} hours`,
        },
        HttpStatus.FORBIDDEN,
      );
    }

    await this.loginAttemptService.unblockByEmail(email);
  }

  private async checkIdentifierAndIPBlock(
    identifier: string,
    ip: string,
  ): Promise<void> {
    // 1. Check IP block first
    const isIPBlocked = await this.loginAttemptService.isIPBlocked(ip);
    if (isIPBlocked) {
      const ipAttempts = await this.loginAttemptService.getIPAttempts(ip);
      throw new HttpException(
        {
          message:
            'Too many failed login attempts from your IP address. Please try again in 5 minutes.',
          error: 'IP_TEMPORARILY_BLOCKED',
          code: 1009,
          attempts: ipAttempts,
          tryAgainIn: '5 minutes',
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    // 2. Check identifier block
    const activeBlock =
      await this.loginAttemptService.hasActiveBlock(identifier);
    if (activeBlock) {
      if (activeBlock.isPermanent) {
        throw new HttpException(
          {
            message:
              'Your account has been permanently blocked due to repeated failed login attempts. Please contact support.',
            error: 'ACCOUNT_PERMANENTLY_BLOCKED',
            code: 1005,
          },
          HttpStatus.FORBIDDEN,
        );
      }

      const remainingTime = activeBlock.expiresAt
        ? activeBlock.expiresAt.getTime() - Date.now()
        : 0;

      if (remainingTime > 0) {
        const hoursLeft = Math.ceil(remainingTime / (1000 * 60 * 60));
        throw new HttpException(
          {
            message: 'Account is temporarily locked',
            error: 'ACCOUNT_LOCKED',
            code: 1005,
            blockLevel: activeBlock.blockLevel,
            expiresAt: activeBlock.expiresAt,
            tryAgainIn:
              hoursLeft > 24
                ? `${Math.ceil(hoursLeft / 24)} days`
                : `${hoursLeft} hours`,
          },
          HttpStatus.FORBIDDEN,
        );
      }

      await this.loginAttemptService.unblockByEmail(identifier);
    }
  }

  private async checkIPBlock(clientIP: string): Promise<void> {
    const isIPBlocked = await this.ipBlockService.checkAndBlock(clientIP);
    if (isIPBlocked) {
      throw new HttpException(
        {
          message:
            'Too many failed attempts from your IP. Please try again later.',
          error: 'IP_BLOCKED',
          code: 1009,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private async validateAccountStatus(user: User): Promise<void> {
    if (!user.verifiedAt) {
      throw new UnauthorizedException({
        message: 'Account not verified. Please verify your account first.',
        error: 'EMAIL_NOT_VERIFIED',
        code: 1007,
      });
    }

    if (!user.isActive) {
      if (user.role === UserRole.DELIVERY || user.role === UserRole.MERCHANT) {
        throw new UnauthorizedException({
          message:
            'حسابك قيد المراجعة من قبل المدير. يرجى التواصل مع الإدارة لتفعيل حسابك.',
          error: 'ACCOUNT_PENDING',
          code: 1006,
        });
      }
      throw new UnauthorizedException({
        message: 'Account is suspended. Please contact support.',
        error: 'ACCOUNT_DISABLED',
        code: 1006,
      });
    }
  }

  private async checkNewDeviceLogin(
    userId: number,
    clientIP: string,
  ): Promise<void> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (user?.lastLoginIp && user.lastLoginIp !== clientIP) {
      await this.securityNotificationService.sendNewDeviceLoginNotification(
        userId,
        clientIP,
      );
    }
  }

  private invalidCredentialsException() {
    return new UnauthorizedException({
      message: 'Invalid email/phone or password',
      error: 'INVALID_CREDENTIALS',
      code: 1002,
    });
  }

  async handleFailedLogin(
    userId: number | undefined,
    identifier: string,
    ip: string,
  ): Promise<void> {
    const attempts = await this.loginAttemptService.recordFailedAttempt(
      identifier,
      ip,
    );

    // 1. Block identifier only if user exists (prevent blocking real users)
    if (userId && attempts >= 5) {
      const block = await this.loginAttemptService.createBlock(
        identifier,
        userId,
        ip,
        attempts,
      );
      const durationText = this.loginAttemptService.getDurationText(
        block.blockLevel,
      );

      await this.securityNotificationService.sendAccountLockedNotification(
        userId,
        identifier,
        block.blockLevel,
        durationText,
      );
    }

    // 2. Send warning at 3 failed attempts
    if (attempts === 3 && userId) {
      await this.securityNotificationService.sendFailedAttemptsWarning(
        userId,
        identifier,
        attempts,
      );
    }

    // 3. IP block is handled separately via recordFailedAttempt
    // (IP is blocked after 3 attempts automatically)
  }

  private async buildLoginResponse(user: User) {
    const accessToken = await this.tokenService.generateAccessToken(user);

    if (user.role === UserRole.MERCHANT) {
      return this.buildMerchantResponse(user, accessToken);
    } else if (user.role === UserRole.DELIVERY) {
      return this.buildDeliveryResponse(user, accessToken);
    } else {
      return this.buildCustomerResponse(user, accessToken);
    }
  }

  private async buildMerchantResponse(user: User, accessToken: string) {
    const merchantResponse = await this.merchantsProfileService.findByUserId(
      user.id,
    );
    if (!merchantResponse || !merchantResponse.user) {
      throw new NotFoundException('Merchant profile not found');
    }

    const userData = merchantResponse.user;
    this.resolveImageUrls(userData.images);

    const flattenedUser = {
      id: userData.id,
      firstName: userData.firstName,
      lastName: userData.lastName,
      email: userData.email,
      phone:
        merchantResponse.hidePhoneNumber === true ? undefined : userData.phone,
      role: userData.role,
      notificationChannel: userData.notificationChannel,
      firebaseToken: userData.firebaseToken,
      countryId: userData.countryId,
      country: userData.country,
      cityId: userData.cityId,
      city: userData.city,
      areaId: userData.areaId,
      area: userData.area,
      address: userData.address,
      isOnline: userData.isOnline,
      isActive: userData.isActive,
      verifiedAt: userData.verifiedAt,
      location: userData.location,
      currentLat: userData.currentLat,
      currentLng: userData.currentLng,
      birthday: userData.birthday,
      createdAt: userData.createdAt,
      updatedAt: userData.updatedAt,
      deletedAt: userData.deletedAt,
      officeOwnerId: userData.officeOwnerId,
      image: userData.images?.[0] || null,
      imageId: userData.images?.[0]?.id || null,
      merchantId: merchantResponse.id,
      restaurantName: merchantResponse.restaurantName,
      isOpen: merchantResponse.isOpen,
      description: merchantResponse.description,
      hidePhoneNumber: merchantResponse.hidePhoneNumber,
      estimatedDeliveryMinutes: merchantResponse.estimatedDeliveryMinutes,
    };

    return { access_token: accessToken, user: flattenedUser };
  }

  private buildCustomerResponse(user: User, accessToken: string) {
    const mainImage = user.images?.[0] || null;
    this.resolveImageUrls(mainImage ? [mainImage] : []);

    const { password, deletedAt, images, ...userResult } = user as any;
    return {
      access_token: accessToken,
      user: { ...userResult, image: mainImage, imageId: mainImage?.id || null },
    };
  }

  private buildGuestResponse(user: User, accessToken: string) {
    const mainImage = user.images?.[0] || null;
    this.resolveImageUrls(mainImage ? [mainImage] : []);

    const { password, deletedAt, images, email, phone, ...userResult } =
      user as any;
    return {
      access_token: accessToken,
      user: {
        ...userResult,
        image: mainImage,
        imageId: mainImage?.id || null,
        is_guest: true,
      },
    };
  }

  private buildDeliveryResponse(user: User, accessToken: string) {
    this.resolveImageUrls(user.images);
    const { password, deletedAt, image, ...userResult } = user as any;
    return { access_token: accessToken, user: userResult };
  }

  async updateFirebaseToken(
    userId: number,
    firebaseToken: string,
  ): Promise<User> {
    this.logger.log(`🔄 [FIREBASE] Updating FCM token for user ${userId}`);
    await this.usersService.updateFirebaseToken(userId, firebaseToken);
    const user = await this.usersService.findOneById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    this.logger.log(
      `✅ [FIREBASE] FCM token updated for user ${userId} - Email: ${user.email}`,
    );
    return user;
  }

  private resolveImageUrls(images: any[] | undefined) {
    if (!images) return;
    for (const img of images) {
      img.url = this.storageService.resolveUrl(img.url) || img.url;
      img.mobileUrl = this.storageService.resolveUrl(img.mobileUrl);
      img.thumbnailUrl = this.storageService.resolveUrl(img.thumbnailUrl);
    }
  }

  async handleGuestLogin(ip?: string, ua?: string) {
    const clientIP = ip || 'unknown';
    const userAgent = ua || 'unknown';

    // Redis-based guest — firebaseToken ignored
    const { guestId, data } = await this.guestRedisService.getOrCreate(clientIP, userAgent);

    const virtualUser: any = {
      id: (parseInt(guestId.replace(/-/g, '').slice(0, 7), 16) % 1900000000) + 900000 || 900000,
      firstName: 'Guest',
      lastName: 'User',
      role: UserRole.CUSTOMER,
      isActive: true,
      is_guest: true,
      email: `guest-${guestId}@jeeb.local`,
      phone: null,
      images: [],
      createdAt: data.createdAt,
      lastLoginAt: new Date(),
      lastLoginIp: clientIP,
    };

    // Guest token — signed directly without DB persistence (no FK)
    const expiresIn = this.configService.get<string>('JWT_EXPIRATION_CUSTOMER') || '1d';
    const accessToken = await this.jwtService.signAsync(
      { sub: virtualUser.id, email: virtualUser.email, role: virtualUser.role, is_guest: true },
      { expiresIn } as any,
    );

    return {
      access_token: accessToken,
      user: {
        id: virtualUser.id,
        firstName: virtualUser.firstName,
        lastName: virtualUser.lastName,
        role: virtualUser.role,
        isActive: true,
        is_guest: true,
        image: null,
        imageId: null,
        createdAt: virtualUser.createdAt,
      },
    };
  }
}

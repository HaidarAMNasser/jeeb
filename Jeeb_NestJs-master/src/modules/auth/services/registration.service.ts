import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../../../database/entities/user.entity';
import { Image } from '../../../database/entities/image.entity';
import { UsersService } from '../../users/users.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { MerchantsService } from '../../merchants/merchants.service';
import { TokenService } from '../token.service';
import { ImageProcessingService } from '../../../common/image-processing/image-processing.service';
import { StorageService } from '../../../common/storage/storage.service';
import { FirebaseService } from '../../firebase/firebase.service';
import { CountriesService } from '../../countries/countries.service';
import { CitiesService } from '../../cities/cities.service';
import { ImageEntityType } from '../../../common/enums/image-entity-type.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { NotificationType } from '../../../common/enums/notification-type.enum';
import { UserRole } from '../../../common/enums/user-role.enum';
import { ErrorCodes, createErrorResponse } from '../../../common/constants/error-codes';
import { RegisterDto } from '../dto/register.dto';
import { CreateUserDto } from '../dto/create-user.dto';
import { CustomerRegistrationStrategy } from '../strategies/customer-registration.strategy';

@Injectable()
export class RegistrationService {
  private readonly logger = new Logger(RegistrationService.name);

  constructor(
    private readonly customerStrategy: CustomerRegistrationStrategy,
    private readonly usersService: UsersService,
    private readonly notificationsService: NotificationsService,
    private readonly merchantsProfileService: MerchantsService,
    private readonly tokenService: TokenService,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly storageService: StorageService,
    private readonly firebaseService: FirebaseService,
    private readonly countriesService: CountriesService,
    private readonly citiesService: CitiesService,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async register(registerDto: RegisterDto, files?: Express.Multer.File[]) {
    const role = registerDto.role || UserRole.CUSTOMER;
    const allowedRoles = [
      UserRole.CUSTOMER,
      UserRole.MERCHANT,
      UserRole.DELIVERY,
    ];

    if (!allowedRoles.includes(role)) {
      throw new ForbiddenException('Registration is not allowed for this role');
    }

    if (role === UserRole.CUSTOMER) {
      throw new BadRequestException(
        'Customer registration is now done via the phone-first flow. Please use POST /auth/register/customer/init to start.',
      );
    }

    await this.validateLocation(registerDto.countryId, registerDto.cityId);

    let user = await this.usersService.findOneByEmailWithDeleted(
      registerDto.email,
    );

    if (user && !user.deletedAt && user.verifiedAt) {
      throw new BadRequestException(
        createErrorResponse('USER_EMAIL_EXISTS', 409),
      );
    }
    if (user && !user.deletedAt && !user.verifiedAt) {
      return {
        message:
          'يوجد حساب غير موثق مسبقاً. الرجاء استخدام إعادة إرسال رمز التحقق.',
        data: {
          message:
            'يوجد حساب غير موثق مسبقاً. الرجاء استخدام إعادة إرسال رمز التحقق.',
          identifier: user.email || user.phone,
        },
      };
    }

    if (role === UserRole.DELIVERY) {
      const phoneUser = await this.usersService.findOneByPhoneWithDeleted(
        registerDto.phone,
      );

      if (phoneUser && !phoneUser.deletedAt && phoneUser.verifiedAt) {
        throw new BadRequestException({
          message: ErrorCodes.USER_PHONE_EXISTS.message,
          code: ErrorCodes.USER_PHONE_EXISTS.code,
        });
      }
      if (phoneUser && !phoneUser.deletedAt && !phoneUser.verifiedAt) {
        return {
          message:
            'يوجد حساب غير موثق مسبقاً. الرجاء استخدام إعادة إرسال رمز التحقق.',
          data: {
            message:
              'يوجد حساب غير موثق مسبقاً. الرجاء استخدام إعادة إرسال رمز التحقق.',
            identifier: phoneUser.email || phoneUser.phone,
          },
        };
      }
    }

    if (role === UserRole.MERCHANT && !registerDto.restaurantName) {
      throw new BadRequestException(
        'Restaurant name is required for merchant registration',
      );
    }

    const isActive =
      role === UserRole.DELIVERY || role === UserRole.MERCHANT ? false : true;
    const hashedPassword = await bcrypt.hash(registerDto.password, 10);

    if (user && user.deletedAt) {
      await this.usersService.restore(user.id);
      const updatedUser = await this.usersService.update(user.id, {
        ...registerDto,
        password: hashedPassword,
        role,
        notificationChannel:
          registerDto.notificationChannel || NotificationChannel.FIREBASE,
        deletedAt: null,
        verifiedAt: null,
        currentLat: registerDto.location?.lat,
        currentLng: registerDto.location?.lng,
        location: registerDto.location,
        isOnline: false,
        isActive,
      });
      user = updatedUser;
    } else {
      user = await this.usersService.create({
        ...registerDto,
        password: hashedPassword,
        role,
        notificationChannel:
          registerDto.notificationChannel || NotificationChannel.FIREBASE,
        currentLat: registerDto.location?.lat,
        currentLng: registerDto.location?.lng,
        location: registerDto.location,
        isOnline: false,
        isActive,
      });
    }

    if (!user) {
      throw new BadRequestException('Failed to create user');
    }

    if (role === UserRole.DELIVERY) {
      try {
        await this.firebaseService.createDriverDocument({
          id: user.id,
          currentLat: user.currentLat || 0,
          currentLng: user.currentLng || 0,
          isOnline: false,
        });
      } catch (error) {
        this.logger.error(
          'Failed to create driver document in Firebase:',
          error,
        );
      }
    }

    if (role === UserRole.MERCHANT) {
      await this.merchantsProfileService.createMerchantProfile(user.id, {
        restaurantName: registerDto.restaurantName || undefined,
        description: registerDto.description || '',
        isOpen: registerDto.isOpen,
        type: registerDto.type,
      });
    }

    await this.notifyAdminsForNewRegistration(
      user,
      role,
      registerDto.restaurantName,
    );
    await this.processProfileImages(user.id, role, files);

    const otp = this.generateOtp();
    const recipient =
      user.notificationChannel === NotificationChannel.EMAIL
        ? user.email!
        : user.phone;

    try {
      await this.notificationsService.sendOtp(
        recipient,
        otp,
        user.notificationChannel,
        user.id,
      );
    } catch (error) {
      this.logger.error(
        `Failed to send OTP for user ${user.id}: ${error instanceof Error ? error.message : error}`,
      );
    }

    const successMessage = `تم تقديم طلب التسجيل بنجاح. قيد المراجعة من قبل المدير. يرجى التحقق من حسابك باستخدام الرمز المرسل إلى ${user.notificationChannel === NotificationChannel.EMAIL ? 'البريد الإلكتروني' : 'رقم الهاتف'}.`;

    return { message: successMessage, data: { message: successMessage } };
  }

  async verifyAccount(identifier: string, otp: string) {
    let user = await this.usersService.findOneByEmail(identifier);
    if (!user) {
      user = await this.usersService.findOneByPhone(identifier);
    }
    if (!user) {
      throw new NotFoundException(
        createErrorResponse('USER_NOT_FOUND', 404),
      );
    }

    if (user.verifiedAt) {
      return { message: 'Account already verified' };
    }

    const recipient =
      user.notificationChannel === NotificationChannel.EMAIL
        ? user.email!
        : user.phone;

    const isValid = await this.notificationsService.verifyOtp(
      recipient,
      otp,
      NotificationType.OTP,
    );
    if (!isValid) {
      throw new BadRequestException(
        createErrorResponse('OTP_INVALID', 400),
      );
    }

    await this.usersService.update(user.id, {
      verifiedAt: new Date(),
      notificationChannel: NotificationChannel.FIREBASE,
    });

    await this.notifyAdminsForVerification(user);

    const accessToken = await this.tokenService.generateAccessToken(user);

    const successMessage =
      user.role === UserRole.DELIVERY || user.role === UserRole.MERCHANT
        ? 'تم التحقق من حسابك بنجاح. حسابك قيد المراجعة من قبل المدير.'
        : 'Account verified successfully.';

    if (user.role === UserRole.DELIVERY) {
      return {
        statusCode: 202,
        message: successMessage,
        data: { message: successMessage, userId: user.id },
      };
    }

    if (user.role === UserRole.MERCHANT) {
      return {
        statusCode: 202,
        message: successMessage,
        data: {
          message: successMessage,
          userId: user.id,
          isActive: user.isActive,
        },
      };
    }

    return this.buildUserVerificationResponse(
      user,
      accessToken,
      successMessage,
    );
  }

  async createAdminOrMerchant(createUserDto: CreateUserDto) {
    await this.validateLocation(createUserDto.countryId, createUserDto.cityId);

    if (
      createUserDto.role &&
      ![UserRole.MERCHANT, UserRole.ADMIN].includes(createUserDto.role)
    ) {
      throw new ForbiddenException(
        'Creation is only allowed for Merchants and Admins.',
      );
    }

    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);

    const adminUser = await this.usersService.create({
      ...createUserDto,
      password: hashedPassword,
      role: createUserDto.role || UserRole.MERCHANT,
      notificationChannel: NotificationChannel.FIREBASE,
      verifiedAt: new Date(),
      isOnline: true,
    });

    return { message: 'User created successfully.', userId: adminUser.id };
  }

  private async validateLocation(countryId?: number, cityId?: number) {
    if (countryId) {
      try {
        await this.countriesService.findOne(countryId);
      } catch (error) {
        if (error instanceof NotFoundException) {
          throw new BadRequestException(
            `Country with ID ${countryId} not found`,
          );
        }
        throw error;
      }
    }

    if (cityId) {
      try {
        const city = await this.citiesService.findOne(cityId);
        if (countryId && city.country?.id !== countryId) {
          throw new BadRequestException(
            `City with ID ${cityId} does not belong to Country with ID ${countryId}`,
          );
        }
      } catch (error) {
        if (error instanceof NotFoundException) {
          throw new BadRequestException(`City with ID ${cityId} not found`);
        }
        throw error;
      }
    }
  }

  private async notifyAdminsForNewRegistration(
    user: any,
    role: UserRole,
    restaurantName?: string,
  ) {
    if (role === UserRole.DELIVERY || role === UserRole.MERCHANT) {
      const admins = await this.userRepository.find({
        where: { role: UserRole.ADMIN },
      });
      if (admins && admins.length > 0) {
        const notificationType =
          role === UserRole.DELIVERY
            ? NotificationType.DELIVERY_REGISTRATION
            : NotificationType.MERCHANT_REGISTRATION;
        const title =
          role === UserRole.DELIVERY ? 'تسجيل سائق جديد' : 'تسجيل مطعم جديد';
        const body =
          role === UserRole.DELIVERY
            ? `تم تقديم طلب تسجيل سائق جديد: ${user.firstName} ${user.lastName}`
            : `تم تقديم طلب تسجيل مطعم جديد: ${restaurantName}`;

        for (const admin of admins) {
          await this.notificationsService.sendToUser(
            admin.id,
            notificationType,
            title,
            body,
            NotificationChannel.FIREBASE,
            { userId: String(user.id), role: String(user.role) },
          );
        }
      }
    }
  }

  private async notifyAdminsForVerification(user: any) {
    if (user.role === UserRole.DELIVERY || user.role === UserRole.MERCHANT) {
      const admins = await this.userRepository.find({
        where: { role: UserRole.ADMIN },
      });
      if (admins && admins.length > 0) {
        const notificationType =
          user.role === UserRole.DELIVERY
            ? NotificationType.DELIVERY_VERIFIED
            : NotificationType.MERCHANT_VERIFIED;
        const title =
          user.role === UserRole.DELIVERY ? 'تحقق حساب سائق' : 'تحقق حساب مطعم';
        const body =
          user.role === UserRole.DELIVERY
            ? `تم التحقق من حساب السائق: ${user.firstName} ${user.lastName}`
            : `تم التحقق من حساب المطعم`;

        for (const admin of admins) {
          await this.notificationsService.sendToUser(
            admin.id,
            notificationType,
            title,
            body,
            NotificationChannel.FIREBASE,
            { userId: String(user.id), role: String(user.role) },
          );
        }
      }
    }
  }

  private async processProfileImages(
    userId: number,
    role: UserRole,
    files?: Express.Multer.File[],
  ) {
    if (!files || files.length === 0) return;

    if (role === UserRole.DELIVERY) {
      const filesToProcess = files.slice(0, 3);
      for (const singleFile of filesToProcess) {
        await this.processAndSaveImage(userId, singleFile);
      }
    } else {
      await this.processAndSaveImage(userId, files[0]);
    }
  }

  private async processAndSaveImage(
    userId: number,
    file: Express.Multer.File,
  ): Promise<Image> {
    const path = `users/${userId}`;
    const processedImages = await this.imageProcessingService.processAndUpload(
      file,
      path,
    );

    const image = this.imageRepository.create({
      entityType: ImageEntityType.USER,
      entityId: userId,
      url: processedImages.original,
      mobileUrl: processedImages.mobile,
      thumbnailUrl: processedImages.thumbnail,
      isMain: true,
      displayOrder: 0,
    });

    return this.imageRepository.save(image);
  }

  private buildMerchantVerificationResponse(
    user: any,
    accessToken: string,
    message: string,
  ) {
    return {
      message,
      data: {
        message,
        access_token: accessToken,
        user: { id: user.id, email: user.email },
      },
    };
  }

  private buildUserVerificationResponse(
    user: any,
    accessToken: string,
    message: string,
  ) {
    const mainImage = user.images?.[0] || null;
    const imageId = mainImage?.id || null;
    const { password, deletedAt, images, ...userResult } = user;
    return {
      message,
      data: {
        message,
        access_token: accessToken,
        user: { ...userResult, image: mainImage, imageId },
      },
    };
  }

  private generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
}

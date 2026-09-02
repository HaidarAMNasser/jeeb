import {
  Injectable,
  BadRequestException,
  Logger,
  Inject,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import Redis from 'ioredis';
import { User } from '../../../database/entities/user.entity';
import { Image } from '../../../database/entities/image.entity';
import { UsersService } from '../../users/users.service';
import { NotificationsService } from '../../notifications/notifications.service';
import { ImageProcessingService } from '../../../common/image-processing/image-processing.service';
import { StorageService } from '../../../common/storage/storage.service';
import { CountriesService } from '../../countries/countries.service';
import { CitiesService } from '../../cities/cities.service';
import { ImageEntityType } from '../../../common/enums/image-entity-type.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { NotificationType } from '../../../common/enums/notification-type.enum';
import { UserRole } from '../../../common/enums/user-role.enum';
import { TokenService } from '../token.service';
import { CustomerInitDto } from '../dto/customer-init.dto';
import { CustomerCompleteRegistrationDto } from '../dto/customer-complete-registration.dto';
import {
  ErrorCodes,
  createErrorResponse,
} from '../../../common/constants/error-codes';
import { REDIS_CLIENT } from '../../../common/redis/redis.constants';

@Injectable()
export class CustomerRegistrationFlowService {
  private readonly logger = new Logger(CustomerRegistrationFlowService.name);
  private readonly SESSION_TTL = 900; // 15 minutes

  constructor(
    private readonly usersService: UsersService,
    private readonly notificationsService: NotificationsService,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly storageService: StorageService,
    private readonly countriesService: CountriesService,
    private readonly citiesService: CitiesService,
    private readonly tokenService: TokenService,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
  ) {}

  private redisKey(phone: string): string {
    return `reg_customer:${phone}`;
  }

  async init(initDto: CustomerInitDto): Promise<Record<string, any>> {
    const { phone, firstName, lastName, password } = initDto;

    const existingUser = await this.usersService.findOneByPhoneWithDeleted(phone);
    if (existingUser && !existingUser.deletedAt) {
      throw new BadRequestException(
        createErrorResponse('USER_PHONE_EXISTS', 409),
      );
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const otp = this.generateOtp();
    await this.notificationsService.sendOtp(
      phone,
      otp,
      NotificationChannel.WHATSAPP,
    );

    await this.redis.set(
      this.redisKey(phone),
      JSON.stringify({
        status: 'pending',
        phone,
        firstName,
        lastName,
        password: hashedPassword,
      }),
      'EX',
      this.SESSION_TTL,
    );

    return {
      message: 'OTP sent successfully to your phone.',
    };
  }

  async verifyPhone(
    phone: string,
    otp: string,
  ): Promise<Record<string, any>> {
    const sessionRaw = await this.redis.get(this.redisKey(phone));
    if (!sessionRaw) {
      throw new BadRequestException(
        createErrorResponse('INVALID_PHONE', 400),
      );
    }

    const session = JSON.parse(sessionRaw);
    if (session.status !== 'pending') {
      throw new BadRequestException(
        'Phone already verified. Please complete your registration.',
      );
    }

    const isValid = await this.notificationsService.verifyOtp(
      phone,
      otp,
      NotificationType.OTP,
    );
    if (!isValid) {
      throw new BadRequestException(
        createErrorResponse('OTP_INVALID', 400),
      );
    }

    const user = await this.usersService.create({
      phone,
      firstName: session.firstName,
      lastName: session.lastName,
      password: session.password,
      role: UserRole.CUSTOMER,
      notificationChannel: NotificationChannel.FIREBASE,
      verifiedAt: new Date(),
      isActive: true,
    });

    if (!user) {
      throw new BadRequestException(
        createErrorResponse('INTERNAL_SERVER_ERROR', 500),
      );
    }

    await this.redis.del(this.redisKey(phone));

    const accessToken = await this.tokenService.generateAccessToken(user);

    return {
      message: 'Account created and verified successfully.',
      data: {
        message: 'Account created and verified successfully.',
        access_token: accessToken,
        user: {
          id: user.id,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          role: user.role,
        },
      },
    };
  }

  async completeRegistration(
    userId: number,
    dto: CustomerCompleteRegistrationDto,
    files?: Express.Multer.File[],
  ): Promise<Record<string, any>> {
    const { email, countryId, cityId } = dto;

    const user = await this.usersService.findOneById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (countryId) {
      await this.validateCountry(countryId);
    }
    if (cityId) {
      await this.validateCity(cityId, countryId);
    }

    if (email) {
      const existingUser = await this.usersService.findOneByEmailWithDeleted(email);
      if (existingUser && existingUser.id !== userId && !existingUser.deletedAt) {
        throw new BadRequestException(
          createErrorResponse('USER_EMAIL_EXISTS', 409),
        );
      }
    }

    const updateData: Partial<User> = {};

    if (email !== undefined) updateData.email = email;
    if (countryId !== undefined) updateData.countryId = countryId;
    if (cityId !== undefined) updateData.cityId = cityId;
    if (dto.address !== undefined) updateData.address = dto.address;
    if (dto.birthday !== undefined) updateData.birthday = dto.birthday;
    if (dto.location !== undefined) {
      updateData.location = dto.location;
      updateData.currentLat = dto.location.lat;
      updateData.currentLng = dto.location.lng;
    }
    if (dto.isOnline !== undefined) updateData.isOnline = dto.isOnline;

    const updatedUser = await this.usersService.update(userId, updateData);

    if (!updatedUser) {
      throw new BadRequestException(
        createErrorResponse('INTERNAL_SERVER_ERROR', 500),
      );
    }

    await this.processProfileImages(userId, files);

    const mainImage = updatedUser.images?.[0] || null;
    const { password, deletedAt, images, ...userResult } = updatedUser as any;

    return {
      message: 'Profile updated successfully.',
      data: {
        message: 'Profile updated successfully.',
        user: { ...userResult, image: mainImage, imageId: mainImage?.id || null },
      },
    };
  }

  private async validateCountry(countryId: number) {
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

  private async validateCity(cityId: number, countryId?: number) {
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

  private async processProfileImages(
    userId: number,
    files?: Express.Multer.File[],
  ) {
    if (!files || files.length === 0) return;
    await this.processAndSaveImage(userId, files[0]);
  }

  private async processAndSaveImage(
    userId: number,
    file: Express.Multer.File,
  ): Promise<Image> {
    const path = `users/${userId}`;
    const processedImages =
      await this.imageProcessingService.processAndUpload(file, path);

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

  private generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
}

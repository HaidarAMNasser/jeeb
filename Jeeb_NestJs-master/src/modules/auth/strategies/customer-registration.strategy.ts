import {
  Injectable,
  BadRequestException,
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
import { ImageProcessingService } from '../../../common/image-processing/image-processing.service';
import { StorageService } from '../../../common/storage/storage.service';
import { CountriesService } from '../../countries/countries.service';
import { CitiesService } from '../../cities/cities.service';
import { ImageEntityType } from '../../../common/enums/image-entity-type.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { UserRole } from '../../../common/enums/user-role.enum';
import {
  ErrorCodes,
  createErrorResponse,
} from '../../../common/constants/error-codes';
import { RegisterDto } from '../dto/register.dto';
import { RegistrationStrategy } from './registration-strategy.interface';

@Injectable()
export class CustomerRegistrationStrategy implements RegistrationStrategy {
  readonly role = UserRole.CUSTOMER;
  private readonly logger = new Logger(CustomerRegistrationStrategy.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly notificationsService: NotificationsService,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly storageService: StorageService,
    private readonly countriesService: CountriesService,
    private readonly citiesService: CitiesService,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
  ) {}

  async register(
    registerDto: RegisterDto,
    files?: Express.Multer.File[],
  ): Promise<Record<string, any>> {
    await this.validateLocation(registerDto.countryId, registerDto.cityId);

    let user = await this.usersService.findOneByEmailWithDeleted(
      registerDto.email,
    );
    if (user && !user.deletedAt) {
      throw new BadRequestException(
        createErrorResponse('USER_EMAIL_EXISTS', 409),
      );
    }

    const phoneUser = await this.usersService.findOneByPhoneWithDeleted(
      registerDto.phone,
    );
    if (phoneUser && !phoneUser.deletedAt) {
      throw new BadRequestException(
        createErrorResponse('USER_PHONE_EXISTS', 409),
      );
    }

    const hashedPassword = await bcrypt.hash(registerDto.password, 10);

    if (user && user.deletedAt) {
      await this.usersService.restore(user.id);
      user = await this.usersService.update(user.id, {
        ...registerDto,
        password: hashedPassword,
        role: UserRole.CUSTOMER,
        notificationChannel:
          registerDto.notificationChannel || NotificationChannel.FIREBASE,
        deletedAt: null,
        verifiedAt: null,
        currentLat: registerDto.location?.lat,
        currentLng: registerDto.location?.lng,
        location: registerDto.location,
        isOnline: false,
        isActive: true,
      });
    } else {
      user = await this.usersService.create({
        ...registerDto,
        password: hashedPassword,
        role: UserRole.CUSTOMER,
        notificationChannel:
          registerDto.notificationChannel || NotificationChannel.FIREBASE,
        currentLat: registerDto.location?.lat,
        currentLng: registerDto.location?.lng,
        location: registerDto.location,
        isOnline: false,
        isActive: true,
      });
    }

    if (!user) {
      throw new BadRequestException(
        createErrorResponse('INTERNAL_SERVER_ERROR', 500),
      );
    }

    await this.processProfileImages(user.id, files);

    const otp = this.generateOtp();
    await this.notificationsService.sendOtp(
      user.phone,
      otp,
      NotificationChannel.WHATSAPP,
      user.id,
    );

    const successMessage =
      'User registered successfully. Please verify your account using the OTP sent to your phone.';

    return {
      message: successMessage,
      data: { message: successMessage, userId: user.id },
    };
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

import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like, IsNull, Not, In } from 'typeorm';
import { User } from '../../../database/entities/user.entity';
import { Merchant } from '../../../database/entities/merchant.entity';
import { Image } from '../../../database/entities/image.entity';
import { Product } from '../../../database/entities/product.entity';
import { Order } from '../../../database/entities/order.entity';
import { Review } from '../../../database/entities/review.entity';
import { Area } from '../../../database/entities/area.entity';
import { UserRole } from '../../../common/enums/user-role.enum';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { ImageEntityType } from '../../../common/enums/image-entity-type.enum';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { CreateMerchantDto } from '../dto/create-merchant.dto';
import { UpdateMerchantDto } from '../dto/update-merchant.dto';
import { FilterMerchantDto } from '../dto/filter-merchant.dto';
import { ImageProcessingService } from '../../../common/image-processing/image-processing.service';
import { MerchantsService } from '../../merchants/merchants.service';
import { ErrorCodes } from '../../../common/constants/error-codes';
import { ConfigService } from '@nestjs/config';
import { StorageService } from '../../../common/storage/storage.service';
import * as bcrypt from 'bcrypt';
import { SearchService, CaseSensitivity } from '../../../common/search';
import { NotificationsService } from '../../notifications/notifications.service';
import { NotificationType } from '../../../common/enums/notification-type.enum';

@Injectable()
export class MerchantService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    @InjectRepository(Area)
    private readonly areaRepository: Repository<Area>,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly merchantsService: MerchantsService,
    private readonly configService: ConfigService,
    private readonly storageService: StorageService,
    private readonly searchService: SearchService,
    private readonly notificationsService: NotificationsService,
  ) {}
  private readonly logger = new Logger(MerchantService.name);

  private getQueryRunner() {
    return this.userRepository.manager.connection.createQueryRunner();
  }

  /**
   * Create a new merchant (ADMIN only)
   * Role is automatically assigned as MERCHANT
   * Note: Email and phone uniqueness is enforced by database constraints
   */
  async create(
    createMerchantDto: CreateMerchantDto,
    file?: Express.Multer.File,
  ): Promise<User> {
    const existingEmail = await this.userRepository.findOne({
      where: { email: createMerchantDto.email },
      withDeleted: true,
    });
    if (existingEmail && !existingEmail.deletedAt) {
      throw new ConflictException('Email already registered');
    }

    // Validate areaId exists if provided
    if (createMerchantDto.areaId) {
      const areaExists = await this.areaRepository.findOne({
        where: { id: createMerchantDto.areaId },
      });
      if (!areaExists) {
        throw new BadRequestException(
          `Area with ID ${createMerchantDto.areaId} not found`,
        );
      }
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(createMerchantDto.password, 10);

    // Create merchant user with automatic role assignment
    // Admin-created merchants are auto-verified and marked as online
    const merchant = this.userRepository.create({
      ...createMerchantDto,
      password: hashedPassword,
      role: UserRole.MERCHANT,
      notificationChannel: NotificationChannel.FIREBASE,
      isOnline: true,
      verifiedAt: new Date(),
    });

    const savedMerchant = await this.userRepository.save(merchant);

    // Create merchant profile in new merchants table
    await this.merchantsService.createMerchantProfile(savedMerchant.id, {
      restaurantName: createMerchantDto.restaurantName || undefined,
      description: createMerchantDto.description || undefined,
      type: createMerchantDto.type,
    });

    // Process and save image if provided
    if (file) {
      await this.processAndSaveImage(savedMerchant.id, file);
    }

    // Return merchant with image relation
    return this.findOne(savedMerchant.id);
  }

  /**
   * Find all merchants with filtering, pagination and comprehensive search
   */
  async findAll(filterDto: FilterMerchantDto): Promise<{
    data: any[];
    pagination: {
      total: number;
      page: number;
      limit: number;
      totalPages: number;
      hasNextPage: boolean;
      hasPreviousPage: boolean;
    };
  }> {
    const { search, countryId, cityId, isActive, isOpen, isVerified, type } =
      filterDto;

    this.logger.log(
      `🔍 [findAll] Filters: isActive=${isActive} (${typeof isActive}), isOpen=${isOpen} (${typeof isOpen}), search=${search}, type=${type}`,
    );

    const page = filterDto.page || 1;
    const limit = filterDto.limit || 10;
    const skip = (page - 1) * limit;

    const queryBuilder = this.userRepository.createQueryBuilder('user');
    queryBuilder.leftJoinAndSelect('user.country', 'country');
    queryBuilder.leftJoinAndSelect('user.city', 'city');
    queryBuilder.leftJoinAndSelect('user.area', 'area');
    queryBuilder.leftJoinAndSelect('user.merchant', 'merchant');

    queryBuilder.andWhere('user.role = :role', { role: UserRole.MERCHANT });

    // Filter by verification status if requested
    if (isVerified === true) {
      queryBuilder.andWhere('user.verifiedAt IS NOT NULL');
    } else if (isVerified === false) {
      queryBuilder.andWhere('user.verifiedAt IS NULL');
    } else {
      // By default, only return verified users as per original logic
      queryBuilder.andWhere('user.verifiedAt IS NOT NULL');
    }

    if (countryId) {
      queryBuilder.andWhere('user.countryId = :countryId', { countryId });
    }
    if (cityId) {
      queryBuilder.andWhere('user.cityId = :cityId', { cityId });
    }

    if (isActive !== undefined) {
      // Corrected: use user.isActive instead of isOnline
      queryBuilder.andWhere('user.isActive = :isActive', { isActive });
    }

    if (isOpen !== undefined) {
      queryBuilder.andWhere('merchant.isOpen = :isOpen', { isOpen });
    }

    if (type) {
      queryBuilder.andWhere('merchant.type = :type', { type });
    }

    if (search) {
      const searchResult = this.searchService.buildSearchConditions(
        [
          'user.firstName',
          'user.lastName',
          'user.email',
          'user.phone',
          'merchant.restaurantName',
        ],
        search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    const [users, total] = await queryBuilder
      .skip(skip)
      .take(limit)
      .orderBy('user.createdAt', 'DESC')
      .getManyAndCount();

    // Fetch images directly for each merchant (matching original logic)
    const merchantsWithImages = await Promise.all(
      users.map(async (user) => {
        const userImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.USER,
            entityId: user.id,
          },
        });
        return this.flattenMerchantResponse(user, userImages);
      }),
    );

    const totalPages = Math.ceil(total / limit);

    return {
      data: merchantsWithImages,
      pagination: {
        total,
        page,
        limit,
        totalPages,
        hasNextPage: page < totalPages,
        hasPreviousPage: page > 1,
      },
    };
  }

  /**
   * Find one merchant by ID
   */
  async findOne(id: number): Promise<User> {
    // Use query builder to force fresh data fetch (without images relation)
    const merchant = await this.userRepository
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.country', 'country')
      .leftJoinAndSelect('user.city', 'city')
      .leftJoinAndSelect('user.area', 'area')
      .leftJoinAndSelect('user.merchant', 'merchant')
      .where('user.id = :id AND user.role = :role', {
        id,
        role: UserRole.MERCHANT,
      })
      .getOne();

    if (!merchant) {
      throw new NotFoundException({
        statusCode: 404,
        message: ErrorCodes.MERCHANT_NOT_FOUND.message,
        code: ErrorCodes.MERCHANT_NOT_FOUND.code,
      });
    }

    // Fetch images directly from image repository to bypass TypeORM caching
    const userImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: id,
      },
    });

    return this.flattenMerchantResponse(merchant, userImages);
  }

  /**
   * Flatten merchant response - move merchant fields to main object
   */
  private flattenMerchantResponse(merchant: User, images: Image[] = []): any {
    const result: any = {};

    // Add merchant fields directly
    if (merchant.merchant) {
      result.id = merchant.id;
      result.userId = merchant.merchant.userId;
      result.merchantId = merchant.merchant.id;
      result.restaurantName = merchant.merchant.restaurantName;
      result.isOpen = merchant.merchant.isOpen;
      result.description = merchant.merchant.description;
      result.hidePhoneNumber = merchant.merchant.hidePhoneNumber;
      result.estimatedDeliveryMinutes =
        merchant.merchant.estimatedDeliveryMinutes;
      result.type = merchant.merchant.type;
    }

    // Add user fields
    result.firstName = merchant.firstName;
    result.lastName = merchant.lastName;
    result.email = merchant.email;
    result.isActive = merchant.isActive;
    result.isOnline = merchant.isOnline;
    result.address = merchant.address;
    result.cityId = merchant.cityId;
    result.city = merchant.city;
    result.countryId = merchant.countryId;
    result.country = merchant.country;
    result.areaId = merchant.areaId;
    result.area = merchant.area;
    result.notificationChannel = merchant.notificationChannel;
    result.verifiedAt = merchant.verifiedAt;
    result.createdAt = merchant.createdAt;
    result.updatedAt = merchant.updatedAt;
    result.deletedAt = merchant.deletedAt;
    result.role = merchant.role;
    result.firebaseToken = merchant.firebaseToken;
    result.birthday = merchant.birthday;
    result.location = merchant.location;
    result.currentLat = merchant.currentLat;
    result.currentLng = merchant.currentLng;
    result.officeOwnerId = merchant.officeOwnerId;

    // Handle phone visibility
    if (merchant.merchant?.hidePhoneNumber !== true) {
      result.phone = merchant.phone;
    }

    // Add image with full URLs if exists (single image for merchant)
    if (images && images.length > 0) {
      const mainImage = images[0];
      mainImage.url =
        this.storageService.resolveUrl(mainImage.url) || mainImage.url;
      mainImage.mobileUrl =
        this.storageService.resolveUrl(mainImage.mobileUrl) ||
        mainImage.mobileUrl;
      mainImage.thumbnailUrl =
        this.storageService.resolveUrl(mainImage.thumbnailUrl) ||
        mainImage.thumbnailUrl;

      result.image = mainImage;
      result.imageId = mainImage.id;
    }

    return result;
  }

  /**
   * Update merchant information
   * Handles both user fields and merchant profile fields
   */
  async update(
    id: number,
    updateMerchantDto: UpdateMerchantDto,
    file?: Express.Multer.File,
  ): Promise<User> {
    const merchantUser = await this.userRepository
      .createQueryBuilder('user')
      .leftJoinAndSelect('user.merchant', 'merchant')
      .where('user.id = :id AND user.role = :role', {
        id,
        role: UserRole.MERCHANT,
      })
      .getOne();

    if (!merchantUser) {
      throw new NotFoundException({
        statusCode: 404,
        message: ErrorCodes.MERCHANT_NOT_FOUND.message,
        code: ErrorCodes.MERCHANT_NOT_FOUND.code,
      });
    }

    const existingImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: id,
      },
    });

    if (updateMerchantDto.password) {
      updateMerchantDto.password = await bcrypt.hash(
        updateMerchantDto.password,
        10,
      );
    }

    if (file) {
      if (existingImages && existingImages.length > 0) {
        const mainImage = existingImages[0];
        await this.imageProcessingService.deleteImages({
          original: mainImage.url,
          mobile: mainImage.mobileUrl || undefined,
          thumbnail: mainImage.thumbnailUrl || undefined,
        });
        for (const img of existingImages) {
          await this.imageRepository.remove(img);
        }
      }

      await this.processAndSaveImage(id, file);
    }

    const merchantProfileData: {
      restaurantName?: string;
      description?: string;
      isOpen?: boolean;
      hidePhoneNumber?: boolean;
      isActive?: boolean;
    } = {};

    if (updateMerchantDto.restaurantName !== undefined) {
      merchantProfileData.restaurantName = updateMerchantDto.restaurantName;
    }
    if (updateMerchantDto.description !== undefined) {
      merchantProfileData.description = updateMerchantDto.description;
    }
    if (updateMerchantDto.isOpen !== undefined) {
      merchantProfileData.isOpen = updateMerchantDto.isOpen;
    }
    if (updateMerchantDto.hidePhoneNumber !== undefined) {
      merchantProfileData.hidePhoneNumber = updateMerchantDto.hidePhoneNumber;
    }
    if (updateMerchantDto.isActive !== undefined) {
      merchantProfileData.isActive = updateMerchantDto.isActive;
    }

    const {
      restaurantName,
      description,
      isOpen,
      hidePhoneNumber,
      ...userUpdateData
    } = updateMerchantDto;

    // Sync logic for location, currentLat, currentLng
    if (userUpdateData.location) {
      userUpdateData.currentLat = userUpdateData.location.lat;
      userUpdateData.currentLng = userUpdateData.location.lng;
    }

    if (
      userUpdateData.currentLat !== undefined &&
      userUpdateData.currentLng !== undefined
    ) {
      userUpdateData.location = {
        lat: userUpdateData.currentLat,
        lng: userUpdateData.currentLng,
      };
    }

    if (userUpdateData.email) {
      const existingUser = await this.userRepository.findOne({
        where: { email: userUpdateData.email },
        withDeleted: true,
      });
      if (existingUser && existingUser.id !== id && !existingUser.deletedAt) {
        const { BadRequestException } = require('@nestjs/common');
        throw new BadRequestException('Email already registered');
      }
    }

    Object.assign(merchantUser, userUpdateData);
    await this.userRepository.save(merchantUser);

    if (merchantUser.merchant && Object.keys(merchantProfileData).length > 0) {
      await this.merchantsService.updateMerchant(
        id,
        merchantProfileData,
        UserRole.ADMIN,
      );
    }

    if (updateMerchantDto.isActive !== undefined) {
      await this.sendMerchantStatusNotification(id, updateMerchantDto.isActive);
    }

    return this.findOne(id);
  }

  async confirmMerchant(id: number): Promise<User> {
    const merchant = await this.userRepository.findOne({
      where: { id, role: UserRole.MERCHANT },
    });

    if (!merchant) {
      throw new NotFoundException({
        statusCode: 404,
        message: ErrorCodes.MERCHANT_NOT_FOUND.message,
        code: ErrorCodes.MERCHANT_NOT_FOUND.code,
      });
    }

    await this.userRepository.update(id, { isActive: true });

    await this.sendMerchantStatusNotification(id, true);

    return this.findOne(id);
  }

  private async sendMerchantStatusNotification(
    merchantId: number,
    isActive: boolean,
  ): Promise<void> {
    const title = isActive ? 'تفعيل الحساب' : 'تعطيل الحساب';
    const body = isActive
      ? 'تم تفعيل حساب مطعمك بنجاح. يمكنك الآن تسجيل الدخول وإدارة طلباتك.'
      : 'تم تعطيل حساب مطعمك. يرجى التواصل مع الإدارة للمزيد من المعلومات.';

    await this.notificationsService.sendToUser(
      merchantId,
      NotificationType.MERCHANT_ACCOUNT_STATUS,
      title,
      body,
      NotificationChannel.FIREBASE,
      { merchantId: String(merchantId), status: String(isActive) },
    );
  }

  /**
   * Delete/Remove merchant (HARD DELETE - completely removes from database)
   */
  async remove(id: number): Promise<void> {
    const merchant = await this.findOne(id);
    const queryRunner = this.getQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Delete merchant image if exists
      if (merchant.images && merchant.images.length > 0) {
        for (const img of merchant.images) {
          await this.imageProcessingService.deleteImages({
            original: img.url,
            mobile: img.mobileUrl || undefined,
            thumbnail: img.thumbnailUrl || undefined,
          });
          await queryRunner.manager.remove(img);
        }
      }

      // Delete products and their images
      const products = await this.productRepository.find({
        where: { merchantId: id },
      });

      for (const product of products) {
        const productImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.PRODUCT,
            entityId: product.id,
          },
        });

        for (const img of productImages) {
          await this.imageProcessingService.deleteImages({
            original: img.url,
            mobile: img.mobileUrl || undefined,
            thumbnail: img.thumbnailUrl || undefined,
          });
          await queryRunner.manager.remove(img);
        }

        await queryRunner.manager.delete(Review, {
          entityType: 'PRODUCT',
          entityId: product.id,
        });
      }

      await queryRunner.manager.delete(Product, { merchantId: id });

      // Delete pending orders for this merchant
      await queryRunner.manager.delete(Order, {
        ownerId: id,
        status: In([OrderStatus.PENDING, OrderStatus.CONFIRMED]),
      });

      // Update orders where this merchant is the owner
      await queryRunner.manager
        .createQueryBuilder()
        .update(Order)
        .set({ ownerId: null })
        .where('ownerId = :id', { id })
        .execute();

      // HARD DELETE: Delete merchant profile first, then the user
      await queryRunner.manager.delete(Merchant, { userId: id });
      await queryRunner.manager.delete(User, id);

      await queryRunner.commitTransaction();
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Process and save user image
   */
  private async processAndSaveImage(
    userId: number,
    file: Express.Multer.File,
  ): Promise<void> {
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
      user: { id: userId } as User,
    });

    await this.imageRepository.save(image);
  }

  /**
   * Search merchants by various criteria
   */
  async search(query: string): Promise<User[]> {
    const merchants = await this.userRepository
      .createQueryBuilder('user')
      .where('user.role = :role', { role: UserRole.MERCHANT })
      .andWhere(
        '(user.firstName LIKE :query OR user.lastName LIKE :query OR user.email LIKE :query OR user.phone LIKE :query)',
        { query: `%${query}%` },
      )
      .leftJoinAndSelect('user.country', 'country')
      .leftJoinAndSelect('user.city', 'city')
      .leftJoinAndSelect('user.area', 'area')
      .leftJoinAndSelect('user.merchant', 'merchant')
      .orderBy('user.createdAt', 'DESC')
      .getMany();

    // Fetch images directly for each merchant
    const merchantsWithImages = await Promise.all(
      merchants.map(async (merchant) => {
        const merchantImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.USER,
            entityId: merchant.id,
          },
        });
        return this.flattenMerchantResponse(merchant, merchantImages);
      }),
    );

    return merchantsWithImages;
  }
}

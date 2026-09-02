import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like, In, IsNull, Not, DataSource } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../../../database/entities/user.entity';
import { Image } from '../../../database/entities/image.entity';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { Order } from '../../../database/entities/order.entity';
import { Review } from '../../../database/entities/review.entity';
import { Product } from '../../../database/entities/product.entity';
import { UserRole } from '../../../common/enums/user-role.enum';
import { ImageProcessingService } from '../../../common/image-processing/image-processing.service';
import { ImageEntityType } from '../../../common/enums/image-entity-type.enum';
import { StorageService } from '../../../common/storage/storage.service';
import { CreateUserDto } from '../dto/create-user.dto';
import { UpdateUserAdminDto } from '../dto/update-user-admin.dto';
import { FilterUserDto } from '../dto/filter-user.dto';
import { CreateOfficeOwnerDto } from '../dto/create-office-owner.dto';
import { UpdateOfficeOwnerDto } from '../dto/update-office-owner.dto';
import { CreateDeliveryByOfficeDto } from '../dto/create-delivery-by-office.dto';
import { UpdateDeliveryByOfficeDto } from '../dto/update-delivery-by-office.dto';
import { CountriesService } from '../../countries/countries.service';
import { CitiesService } from '../../cities/cities.service';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { SearchService, CaseSensitivity } from '../../../common/search';
import { FirebaseService } from '../../firebase/firebase.service';

@Injectable()
export class UsersAdminService {
  private readonly logger = new Logger(UsersAdminService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
    @InjectRepository(DeliveryAssignment)
    private readonly deliveryAssignmentRepository: Repository<DeliveryAssignment>,
    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly countriesService: CountriesService,
    private readonly citiesService: CitiesService,
    private readonly searchService: SearchService,
    private readonly storageService: StorageService,
    private readonly dataSource: DataSource,
    private readonly firebaseService: FirebaseService,
  ) {}

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
      let city;
      try {
        city = await this.citiesService.findOne(cityId);
      } catch (error) {
        if (error instanceof NotFoundException) {
          throw new BadRequestException(`City with ID ${cityId} not found`);
        }
        throw error;
      }

      if (countryId && city.country.id !== countryId) {
        throw new BadRequestException(
          `City with ID ${cityId} does not belong to Country with ID ${countryId}`,
        );
      }
    }
  }

  async create(
    createUserDto: CreateUserDto,
    file?: Express.Multer.File,
  ): Promise<User> {
    // Validate location
    await this.validateLocation(createUserDto.countryId, createUserDto.cityId);

    // Check if user already exists
    const existingUser = await this.userRepository.findOne({
      where: { email: createUserDto.email },
      withDeleted: true,
    });

    if (existingUser && !existingUser.deletedAt) {
      throw new ConflictException('Email already exists');
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);

    // Create user with admin defaults
    const user = this.userRepository.create({
      ...createUserDto,
      password: hashedPassword,
      role: createUserDto.role || UserRole.CUSTOMER,
      notificationChannel: NotificationChannel.FIREBASE,
      isOnline: true,
      verifiedAt: new Date(), // Admin-created users are auto-verified
    });

    const savedUser = await this.userRepository.save(user);

    // Process and save image if provided
    if (file) {
      await this.processAndSaveImage(savedUser.id, file);
    }

    // Return user with image relation
    return this.findOne(savedUser.id);
  }

  async findAll(filterDto: FilterUserDto) {
    const {
      page = 1,
      limit = 10,
      search,
      countryId,
      cityId,
      role,
      isVerified,
      isOnline,
    } = filterDto;
    const skip = (page - 1) * limit;

    // If search is provided, use comprehensive search across firstName, lastName, email, phone
    if (search) {
      const queryBuilder = this.userRepository.createQueryBuilder('user');
      queryBuilder.leftJoinAndSelect('user.country', 'country');
      queryBuilder.leftJoinAndSelect('user.city', 'city');
      queryBuilder.leftJoinAndSelect('user.images', 'images');

      if (role) {
        queryBuilder.andWhere('user.role = :role', { role });
      }
      if (countryId) {
        queryBuilder.andWhere('user.countryId = :countryId', { countryId });
      }
      if (cityId) {
        queryBuilder.andWhere('user.cityId = :cityId', { cityId });
      }
      if (isVerified !== undefined) {
        queryBuilder.andWhere('user.isVerified = :isVerified', { isVerified });
      }
      if (isOnline !== undefined) {
        queryBuilder.andWhere('user.isOnline = :isOnline', { isOnline });
      }

      // Only return verified users (verifiedAt is not null)
      queryBuilder.andWhere('user.verifiedAt IS NOT NULL');

      const searchResult = this.searchService.buildSearchConditions(
        ['user.firstName', 'user.lastName', 'user.email', 'user.phone'],
        search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });

      const [users, total] = await queryBuilder
        .skip(skip)
        .take(limit)
        .orderBy('user.createdAt', 'DESC')
        .getManyAndCount();

      const totalPages = Math.ceil(total / limit);

      return {
        data: users,
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

    // Regular findAll without search
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const whereConditions: any = {};

    if (countryId) {
      whereConditions.countryId = countryId;
    }

    if (cityId) {
      whereConditions.cityId = cityId;
    }

    if (role) {
      whereConditions.role = role;
    }

    if (isVerified !== undefined) {
      whereConditions.verifiedAt = isVerified
        ? // eslint-disable-next-line @typescript-eslint/no-explicit-any
          Like('%' as any)
        : null;
    }

    if (isOnline !== undefined) {
      whereConditions.isOnline = isOnline;
    }

    // Only return verified users (verifiedAt is not null)
    whereConditions.verifiedAt = Not(IsNull());

    const [users, total] = await this.userRepository.findAndCount({
      where: whereConditions,
      relations: ['country', 'city'],
      skip,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    const totalPages = Math.ceil(total / limit);

    // Fetch images directly for each user to avoid TypeORM caching
    const usersWithImages = await Promise.all(
      users.map(async (user) => {
        const userImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.USER,
            entityId: user.id,
          },
        });
        return this.formatUserResponse(user, userImages);
      }),
    );

    return {
      data: usersWithImages,
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
   * Format user response based on role
   */
  private formatUserResponse(user: User, images: Image[] = []): any {
    const result: any = { ...user };

    // Remove password and deletedAt
    delete result.password;
    delete result.deletedAt;

    // Resolve image URLs
    if (images && images.length > 0) {
      for (const img of images) {
        img.url = this.storageService.resolveUrl(img.url) || img.url;
        img.mobileUrl = this.storageService.resolveUrl(img.mobileUrl);
        img.thumbnailUrl = this.storageService.resolveUrl(img.thumbnailUrl);
      }
    }

    // For DELIVERY: return images array
    if (user.role === UserRole.DELIVERY) {
      delete result.image;
      result.images = images;
    } else {
      // For CUSTOMER, MERCHANT, ADMIN: return image + imageId (single image)
      delete result.images;
      const mainImage = images && images.length > 0 ? images[0] : null;
      result.image = mainImage;
      result.imageId = mainImage?.id ?? null;
    }

    return result;
  }

  async findOne(id: number): Promise<User> {
    // Fetch user without images relation to avoid caching issues
    const user = await this.userRepository.findOne({
      where: { id },
      relations: ['country', 'city'],
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    // Fetch images directly from image repository
    const userImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: id,
      },
    });

    return this.formatUserResponse(user, userImages) as User;
  }

  async search(query: string): Promise<User[]> {
    if (!query || query.trim() === '') {
      return [];
    }

    const searchTerm = `%${query}%`;

    const users = await this.userRepository.find({
      where: [
        { firstName: Like(searchTerm) },
        { lastName: Like(searchTerm) },
        { email: Like(searchTerm) },
        { phone: Like(searchTerm) },
      ],
      relations: ['country', 'city'],
      take: 20,
    });

    // Fetch images directly for each user
    const usersWithImages = await Promise.all(
      users.map(async (user) => {
        const userImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.USER,
            entityId: user.id,
          },
        });
        return this.formatUserResponse(user, userImages);
      }),
    );

    return usersWithImages as User[];
  }

  async update(
    id: number,
    updateUserDto: UpdateUserAdminDto,
    file?: Express.Multer.File,
  ): Promise<User> {
    // Fetch user without images relation
    const user = await this.userRepository.findOne({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    // Fetch images directly from image repository
    const existingImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: id,
      },
    });

    // Validate location if provided
    if (updateUserDto.countryId || updateUserDto.cityId) {
      await this.validateLocation(
        updateUserDto.countryId,
        updateUserDto.cityId,
      );
    }

    // Handle image update
    if (file) {
      // Get first image from the images array
      const mainImage =
        existingImages && existingImages.length > 0 ? existingImages[0] : null;

      // Delete old image if exists
      if (mainImage) {
        await this.imageProcessingService.deleteImages({
          original: mainImage.url,
          mobile: mainImage.mobileUrl || undefined,
          thumbnail: mainImage.thumbnailUrl || undefined,
        });
        await this.imageRepository.remove(mainImage);
      }
      // Upload new image
      await this.processAndSaveImage(user.id, file);
    }

    // Handle password update and cast notificationChannel properly
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData: any = { ...updateUserDto };
    if (updateUserDto.password) {
      updateData.password = await bcrypt.hash(updateUserDto.password, 10);
    }

    // Update user

    await this.userRepository.update(id, updateData);

    // Return updated user with relations
    return this.findOne(id);
  }

  async remove(id: number): Promise<void> {
    const user = await this.userRepository.findOne({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      switch (user.role) {
        case UserRole.CUSTOMER:
          await this.deleteCustomer(queryRunner, id);
          break;

        case UserRole.DELIVERY:
          await this.deleteDelivery(queryRunner, id);
          break;

        case UserRole.MERCHANT:
          await this.deleteMerchant(queryRunner, id);
          break;

        default:
          await this.softDeleteUser(queryRunner, id);
          break;
      }

      await queryRunner.commitTransaction();
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  private async deleteCustomer(
    queryRunner: any,
    userId: number,
  ): Promise<void> {
    const existingImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: userId,
      },
    });

    for (const img of existingImages) {
      await this.imageProcessingService.deleteImages({
        original: img.url,
        mobile: img.mobileUrl || undefined,
        thumbnail: img.thumbnailUrl || undefined,
      });
      await queryRunner.manager.remove(img);
    }

    await queryRunner.manager.delete(Order, {
      customerId: userId,
      status: OrderStatus.PENDING,
    });

    await queryRunner.manager.delete(User, userId);
  }

  private async deleteDelivery(
    queryRunner: any,
    userId: number,
  ): Promise<void> {
    const activeAssignment = await this.deliveryAssignmentRepository.findOne({
      where: {
        deliveryId: userId,
        status: In([
          DeliveryStatus.ASSIGNED,
          DeliveryStatus.NOTIFIED,
          DeliveryStatus.ACCEPTED,
          DeliveryStatus.PICKED,
        ]),
      },
    });

    if (activeAssignment) {
      throw new BadRequestException(
        'Cannot delete delivery driver while on active delivery mission',
      );
    }

    const existingImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: userId,
      },
    });

    for (const img of existingImages) {
      await this.imageProcessingService.deleteImages({
        original: img.url,
        mobile: img.mobileUrl || undefined,
        thumbnail: img.thumbnailUrl || undefined,
      });
      await queryRunner.manager.remove(img);
    }

    await queryRunner.manager.delete(User, userId);

    try {
      await this.firebaseService.deleteDriverDocument(userId);
    } catch (error) {
      this.logger.error(
        `Failed to delete driver document in Firebase for driver ${userId}`,
        error,
      );
    }
  }

  private async deleteMerchant(
    queryRunner: any,
    userId: number,
  ): Promise<void> {
    const existingImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: userId,
      },
    });

    for (const img of existingImages) {
      await this.imageProcessingService.deleteImages({
        original: img.url,
        mobile: img.mobileUrl || undefined,
        thumbnail: img.thumbnailUrl || undefined,
      });
      await queryRunner.manager.remove(img);
    }

    const products = await this.productRepository.find({
      where: { merchantId: userId },
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

    await queryRunner.manager.delete(Product, { merchantId: userId });

    await queryRunner.manager.delete(Order, {
      ownerId: userId,
      status: OrderStatus.PENDING,
    });

    await queryRunner.manager
      .createQueryBuilder()
      .update(Order)
      .set({ ownerId: null })
      .where('ownerId = :userId', { userId })
      .execute();

    const reviews = await this.reviewRepository.find({
      where: { reviewerId: userId },
    });

    for (const review of reviews) {
      await queryRunner.manager
        .createQueryBuilder()
        .update(Review)
        .set({ reviewerId: null })
        .where('id = :id', { id: review.id })
        .execute();
    }

    await queryRunner.manager.delete(User, userId);
  }

  private async softDeleteUser(
    queryRunner: any,
    userId: number,
  ): Promise<void> {
    const existingImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: userId,
      },
    });

    for (const img of existingImages) {
      await this.imageProcessingService.deleteImages({
        original: img.url,
        mobile: img.mobileUrl || undefined,
        thumbnail: img.thumbnailUrl || undefined,
      });
      await queryRunner.manager.remove(img);
    }

    await queryRunner.manager.softDelete(User, userId);
  }

  /**
   * Process and save image for a user
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
    });

    await this.imageRepository.save(image);
  }

  /**
   * Find all delivery drivers (for ADMIN) with comprehensive search
   */
  async findAllDeliveries(
    page: number = 1,
    limit: number = 10,
    search?: string,
    countryId?: number,
    cityId?: number,
    isOnline?: boolean,
    officeOwnerId?: number,
  ): Promise<{ data: User[]; pagination: any }> {
    const skip = (page - 1) * limit;

    // If search is provided, use comprehensive search across firstName, email, phone
    if (search) {
      const queryBuilder = this.userRepository.createQueryBuilder('user');
      queryBuilder.leftJoinAndSelect('user.country', 'country');
      queryBuilder.leftJoinAndSelect('user.city', 'city');
      queryBuilder.leftJoinAndSelect('user.images', 'images');
      queryBuilder.leftJoinAndSelect('user.officeOwner', 'officeOwner');

      queryBuilder.andWhere('user.role = :role', { role: UserRole.DELIVERY });

      // Only return verified users (verifiedAt is not null)
      queryBuilder.andWhere('user.verifiedAt IS NOT NULL');

      if (countryId) {
        queryBuilder.andWhere('user.countryId = :countryId', { countryId });
      }
      if (cityId) {
        queryBuilder.andWhere('user.cityId = :cityId', { cityId });
      }
      if (isOnline !== undefined) {
        queryBuilder.andWhere('user.isOnline = :isOnline', { isOnline });
      }
      if (officeOwnerId) {
        queryBuilder.andWhere('user.officeOwnerId = :officeOwnerId', {
          officeOwnerId,
        });
      }

      const searchResult = this.searchService.buildSearchConditions(
        ['user.firstName', 'user.lastName', 'user.email', 'user.phone'],
        search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });

      const [users, total] = await queryBuilder
        .skip(skip)
        .take(limit)
        .orderBy('user.createdAt', 'DESC')
        .getManyAndCount();

      return {
        data: users,
        pagination: {
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit),
          hasNextPage: page * limit < total,
          hasPreviousPage: page > 1,
        },
      };
    }

    // Regular findAll without search
    const whereConditions: any = {
      role: UserRole.DELIVERY,
      verifiedAt: Not(IsNull()), // Only return verified users
    };

    if (countryId) {
      whereConditions.countryId = countryId;
    }

    if (cityId) {
      whereConditions.cityId = cityId;
    }

    if (isOnline !== undefined) {
      whereConditions.isOnline = isOnline;
    }

    if (officeOwnerId) {
      whereConditions.officeOwnerId = officeOwnerId;
    }

    const [users, total] = await this.userRepository.findAndCount({
      where: whereConditions,
      relations: ['country', 'city', 'officeOwner'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    // Fetch images directly for each user
    const usersWithImages = await Promise.all(
      users.map(async (user) => {
        const userImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.USER,
            entityId: user.id,
          },
        });
        return this.formatUserResponse(user, userImages);
      }),
    );

    return {
      data: usersWithImages,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page * limit < total,
        hasPreviousPage: page > 1,
      },
    };
  }

  /**
   * Search delivery drivers by name, email, or phone (for ADMIN) - kept for backward compatibility
   */
  async searchDeliveries(query: string): Promise<User[]> {
    if (!query || query.trim() === '') {
      return [];
    }

    const queryBuilder = this.userRepository.createQueryBuilder('user');
    queryBuilder.leftJoinAndSelect('user.country', 'country');
    queryBuilder.leftJoinAndSelect('user.city', 'city');
    queryBuilder.leftJoinAndSelect('user.officeOwner', 'officeOwner');
    queryBuilder.andWhere('user.role = :role', { role: UserRole.DELIVERY });

    const searchResult = this.searchService.buildSearchConditions(
      ['user.firstName', 'user.lastName', 'user.email', 'user.phone'],
      query,
      CaseSensitivity.INSENSITIVE,
    );
    queryBuilder.andWhere(searchResult.condition, {
      [searchResult.paramName]: searchResult.paramValue,
    });

    const users = await queryBuilder.take(20).getMany();

    // Fetch images directly for each user
    const usersWithImages = await Promise.all(
      users.map(async (user) => {
        const userImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.USER,
            entityId: user.id,
          },
        });
        return this.formatUserResponse(user, userImages);
      }),
    );

    return usersWithImages as User[];
  }

  /**
   * Find one delivery driver by ID (for ADMIN)
   */
  async findOneDelivery(id: number): Promise<User> {
    const delivery = await this.userRepository.findOne({
      where: {
        id,
        role: UserRole.DELIVERY,
      },
      relations: ['country', 'city', 'officeOwner'],
    });

    if (!delivery) {
      throw new NotFoundException(`Delivery driver with ID ${id} not found`);
    }

    // Fetch images directly from image repository
    const userImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: id,
      },
    });

    return this.formatUserResponse(delivery, userImages) as User;
  }

  /**
   * Create a new delivery driver (for ADMIN - can assign to any office owner)
   */
  async createDelivery(
    createDeliveryDto: CreateDeliveryByOfficeDto,
    officeOwnerId?: number,
    file?: Express.Multer.File,
  ): Promise<User> {
    // Validate location
    await this.validateLocation(
      createDeliveryDto.countryId,
      createDeliveryDto.cityId,
    );

    // Check if office owner exists (only if officeOwnerId is provided)
    if (officeOwnerId) {
      const officeOwner = await this.userRepository.findOne({
        where: {
          id: officeOwnerId,
          role: UserRole.OFFICE_OWNER,
        },
      });

      if (!officeOwner) {
        throw new NotFoundException(
          `Office owner with ID ${officeOwnerId} not found`,
        );
      }
    }

    // Check if user already exists
    const existingUser = await this.userRepository.findOne({
      where: { email: createDeliveryDto.email },
      withDeleted: true,
    });

    if (existingUser && !existingUser.deletedAt) {
      throw new ConflictException('Email already exists');
    }

    // If user was soft deleted, restore and update
    if (existingUser?.deletedAt) {
      await this.userRepository.restore(existingUser.id);

      const hashedPassword = await bcrypt.hash(createDeliveryDto.password, 10);

      if (createDeliveryDto.birthday) {
        const birthdayDate = new Date(createDeliveryDto.birthday);
        if (isNaN(birthdayDate.getTime())) {
          throw new BadRequestException('Invalid birthday date format');
        }
      }

      const updateData: any = {
        ...createDeliveryDto,
        password: hashedPassword,
        role: UserRole.DELIVERY,
        officeOwnerId: officeOwnerId,
        notificationChannel: NotificationChannel.FIREBASE,
        isOnline: true,
        verifiedAt: new Date(),
        deletedAt: null,
      };

      // Handle location object (parse JSON string if needed)
      if (createDeliveryDto.location) {
        let loc;
        if (typeof createDeliveryDto.location === 'string') {
          try {
            loc = JSON.parse(createDeliveryDto.location);
          } catch (e) {
            loc = { lat: undefined, lng: undefined };
          }
        } else if (
          typeof createDeliveryDto.location === 'object' &&
          createDeliveryDto.location !== null
        ) {
          loc = createDeliveryDto.location;
        } else {
          loc = { lat: undefined, lng: undefined };
        }
        if (loc.lat !== undefined) {
          updateData.currentLat = loc.lat;
        }
        if (loc.lng !== undefined) {
          updateData.currentLng = loc.lng;
        }
        // Store as JSON object in DB
        updateData.location = loc;
      }

      await this.userRepository.update(existingUser.id, updateData);

      // Process and save image if provided
      if (file) {
        await this.processAndSaveImage(existingUser.id, file);
      }

      try {
        await this.firebaseService.createDriverDocument({
          id: existingUser.id,
          currentLat: 0,
          currentLng: 0,
          isOnline: true,
        });
      } catch (error) {
        this.logger.error(
          `Failed to create driver document in Firebase for driver ${existingUser.id}`,
          error,
        );
      }

      return this.findOneDelivery(existingUser.id);
    }

    // Create new delivery driver
    const hashedPassword = await bcrypt.hash(createDeliveryDto.password, 10);

    if (createDeliveryDto.birthday) {
      const birthdayDate = new Date(createDeliveryDto.birthday);
      if (isNaN(birthdayDate.getTime())) {
        throw new BadRequestException('Invalid birthday date format');
      }
    }

    const userData: any = { ...createDeliveryDto, password: hashedPassword };

    // Handle location object (parse JSON string if needed)
    if (createDeliveryDto.location) {
      let loc;
      if (typeof createDeliveryDto.location === 'string') {
        try {
          loc = JSON.parse(createDeliveryDto.location);
        } catch (e) {
          loc = { lat: undefined, lng: undefined };
        }
      } else if (
        typeof createDeliveryDto.location === 'object' &&
        createDeliveryDto.location !== null
      ) {
        loc = createDeliveryDto.location;
      } else {
        loc = { lat: undefined, lng: undefined };
      }
      if (loc.lat !== undefined) {
        userData.currentLat = loc.lat;
      }
      if (loc.lng !== undefined) {
        userData.currentLng = loc.lng;
      }
      // Store as JSON object in DB
      userData.location = loc;
    }

    const user = this.userRepository.create({
      ...userData,
      password: hashedPassword,
      role: UserRole.DELIVERY,
      officeOwnerId: officeOwnerId,
      notificationChannel: NotificationChannel.FIREBASE,
      isOnline: true,
      verifiedAt: new Date(),
    });

    const savedUser = (await this.userRepository.save(user)) as unknown as User;

    // Process and save image if provided
    if (file) {
      await this.processAndSaveImage(savedUser.id, file);
    }

    try {
      const lat = userData.currentLat || 0;
      const lng = userData.currentLng || 0;
      await this.firebaseService.createDriverDocument({
        id: savedUser.id,
        currentLat: lat,
        currentLng: lng,
        isOnline: true,
      });
    } catch (error) {
      this.logger.error(
        `Failed to create driver document in Firebase for driver ${savedUser.id}`,
        error,
      );
    }

    return this.findOneDelivery(savedUser.id);
  }

  /**
   * Update a delivery driver (for ADMIN - can update any delivery driver)
   */
  async updateDelivery(
    deliveryId: number,
    updateDeliveryDto: UpdateDeliveryByOfficeDto,
    file?: Express.Multer.File,
  ): Promise<User> {
    // Fetch delivery user without images relation
    const delivery = await this.userRepository.findOne({
      where: {
        id: deliveryId,
        role: UserRole.DELIVERY,
      },
      relations: ['country', 'city', 'officeOwner'],
    });

    if (!delivery) {
      throw new NotFoundException(
        `Delivery driver with ID ${deliveryId} not found`,
      );
    }

    // Fetch images directly from image repository
    const existingImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: deliveryId,
      },
    });

    // Check if driver is currently on an active mission
    if (await this.isDriverBusy(deliveryId)) {
      throw new BadRequestException(
        'Cannot update delivery driver while on active delivery mission',
      );
    }

    // Validate location if provided
    if (updateDeliveryDto.countryId || updateDeliveryDto.cityId) {
      await this.validateLocation(
        updateDeliveryDto.countryId,
        updateDeliveryDto.cityId,
      );
    }

    // Check for email conflicts
    if (updateDeliveryDto.email) {
      const existingUser = await this.userRepository.findOne({
        where: { email: updateDeliveryDto.email },
      });

      if (existingUser && existingUser.id !== deliveryId) {
        throw new ConflictException('Email already exists');
      }
    }

    // Delete old image if new one is uploaded (delivery can have multiple images)
    if (file && existingImages && existingImages.length > 0) {
      for (const img of existingImages) {
        await this.imageProcessingService.deleteImages({
          original: img.url,
          mobile: img.mobileUrl ?? undefined,
          thumbnail: img.thumbnailUrl ?? undefined,
        });
        await this.imageRepository.remove(img);
      }
    }

    // Handle password update
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData: any = { ...updateDeliveryDto };

    // Convert string boolean values to actual booleans
    if (updateData.isActive !== undefined) {
      if (updateData.isActive === 'true' || updateData.isActive === '1') {
        updateData.isActive = true;
      } else if (
        updateData.isActive === 'false' ||
        updateData.isActive === '0'
      ) {
        updateData.isActive = false;
      }
    }

    if (updateData.isOnline !== undefined) {
      if (updateData.isOnline === 'true' || updateData.isOnline === '1') {
        updateData.isOnline = true;
      } else if (
        updateData.isOnline === 'false' ||
        updateData.isOnline === '0'
      ) {
        updateData.isOnline = false;
      }
    }

    if ((updateDeliveryDto as { password?: string }).password) {
      updateData.password = await bcrypt.hash(
        (updateDeliveryDto as { password?: string }).password!,
        10,
      );
    }

    // Handle location object (parse JSON string if needed)
    if (updateDeliveryDto.location) {
      let loc;
      if (typeof updateDeliveryDto.location === 'string') {
        try {
          loc = JSON.parse(updateDeliveryDto.location);
        } catch (e) {
          loc = { lat: undefined, lng: undefined };
        }
      } else if (
        typeof updateDeliveryDto.location === 'object' &&
        updateDeliveryDto.location !== null
      ) {
        loc = updateDeliveryDto.location;
      } else {
        loc = { lat: undefined, lng: undefined };
      }
      if (loc.lat !== undefined) {
        updateData.currentLat = loc.lat;
      }
      if (loc.lng !== undefined) {
        updateData.currentLng = loc.lng;
      }
      // Store as JSON object in DB
      updateData.location = loc;
    }

    // Update user
    await this.userRepository.update(deliveryId, updateData);

    // Process and save new image if provided
    if (file) {
      await this.processAndSaveImage(deliveryId, file);
    }

    // Return updated delivery
    return this.findOneDelivery(deliveryId);
  }

  /**
   * Confirm/Activate a delivery driver (for ADMIN)
   * Sets isActive to true
   */
  async confirmDelivery(deliveryId: number): Promise<User> {
    const delivery = await this.userRepository.findOne({
      where: {
        id: deliveryId,
        role: UserRole.DELIVERY,
      },
    });

    if (!delivery) {
      throw new NotFoundException(
        `Delivery driver with ID ${deliveryId} not found`,
      );
    }

    // Update isActive to true
    await this.userRepository.update(deliveryId, { isActive: true });

    // Return updated delivery
    return this.findOneDelivery(deliveryId);
  }

  /**
   * Delete a delivery driver (for ADMIN - can delete any delivery driver)
   */
  async removeDelivery(deliveryId: number): Promise<void> {
    // Fetch delivery user without images relation
    const delivery = await this.userRepository.findOne({
      where: {
        id: deliveryId,
        role: UserRole.DELIVERY,
      },
    });

    if (!delivery) {
      throw new NotFoundException(
        `Delivery driver with ID ${deliveryId} not found`,
      );
    }

    // Fetch images directly from image repository
    const existingImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: deliveryId,
      },
    });

    // Check if driver is currently on an active mission
    if (await this.isDriverBusy(deliveryId)) {
      throw new BadRequestException(
        'Cannot delete delivery driver while on active delivery mission',
      );
    }

    // Delete associated images
    if (existingImages && existingImages.length > 0) {
      for (const img of existingImages) {
        await this.imageProcessingService.deleteImages({
          original: img.url,
          mobile: img.mobileUrl ?? undefined,
          thumbnail: img.thumbnailUrl ?? undefined,
        });
        await this.imageRepository.remove(img);
      }
    }

    // Soft delete the delivery driver
    await this.userRepository.softDelete(deliveryId);

    try {
      await this.firebaseService.deleteDriverDocument(deliveryId);
    } catch (error) {
      this.logger.error(
        `Failed to delete driver document in Firebase for driver ${deliveryId}`,
        error,
      );
    }
  }

  /**
   * Check if delivery driver is currently on an active mission
   */
  private async isDriverBusy(deliveryId: number): Promise<boolean> {
    const activeAssignment = await this.deliveryAssignmentRepository.findOne({
      where: {
        deliveryId,
        status: In([
          DeliveryStatus.ASSIGNED,
          DeliveryStatus.ACCEPTED,
          DeliveryStatus.PICKED,
        ]),
      },
    });
    return !!activeAssignment;
  }

  /**
   * Create a new office owner (for ADMIN)
   */
  async createOfficeOwner(
    createOfficeOwnerDto: CreateOfficeOwnerDto,
    file?: Express.Multer.File,
  ): Promise<User> {
    // Validate location
    await this.validateLocation(
      createOfficeOwnerDto.countryId,
      createOfficeOwnerDto.cityId,
    );

    // Check if user already exists
    const existingUser = await this.userRepository.findOne({
      where: { email: createOfficeOwnerDto.email },
      withDeleted: true,
    });

    if (existingUser && !existingUser.deletedAt) {
      throw new ConflictException('Email already exists');
    }

    // If user was soft deleted, restore and update
    if (existingUser?.deletedAt) {
      await this.userRepository.restore(existingUser.id);

      const hashedPassword = await bcrypt.hash(
        createOfficeOwnerDto.password,
        10,
      );

      const updateData = {
        ...createOfficeOwnerDto,
        password: hashedPassword,
        role: UserRole.OFFICE_OWNER,
        notificationChannel:
          createOfficeOwnerDto.notificationChannel ??
          NotificationChannel.WHATSAPP,
        isOnline: true,
        verifiedAt: new Date(),
        deletedAt: null,
      };

      await this.userRepository.update(existingUser.id, updateData);

      // Process and save image if provided
      if (file) {
        await this.processAndSaveImage(existingUser.id, file);
      }

      return this.findOneOfficeOwner(existingUser.id);
    }

    // Create new office owner
    const hashedPassword = await bcrypt.hash(createOfficeOwnerDto.password, 10);

    const user = this.userRepository.create({
      ...createOfficeOwnerDto,
      password: hashedPassword,
      role: UserRole.OFFICE_OWNER,
      notificationChannel:
        createOfficeOwnerDto.notificationChannel ??
        NotificationChannel.WHATSAPP,
      isOnline: true,
      verifiedAt: new Date(),
    });

    const savedUser = await this.userRepository.save(user);

    // Process and save image if provided
    if (file) {
      await this.processAndSaveImage(savedUser.id, file);
    }

    return this.findOneOfficeOwner(savedUser.id);
  }

  /**
   * Find all office owners (for ADMIN) with comprehensive search
   */
  async findAllOfficeOwners(
    page: number = 1,
    limit: number = 10,
    search?: string,
    countryId?: number,
    cityId?: number,
  ): Promise<{ data: User[]; pagination: any }> {
    const skip = (page - 1) * limit;

    // If search is provided, use comprehensive search across firstName, email, phone
    if (search) {
      const queryBuilder = this.userRepository.createQueryBuilder('user');
      queryBuilder.leftJoinAndSelect('user.country', 'country');
      queryBuilder.leftJoinAndSelect('user.city', 'city');
      queryBuilder.leftJoinAndSelect('user.images', 'images');
      queryBuilder.leftJoinAndSelect('user.deliveryDrivers', 'deliveryDrivers');

      queryBuilder.andWhere('user.role = :role', {
        role: UserRole.OFFICE_OWNER,
      });

      if (countryId) {
        queryBuilder.andWhere('user.countryId = :countryId', { countryId });
      }
      if (cityId) {
        queryBuilder.andWhere('user.cityId = :cityId', { cityId });
      }

      const searchResult = this.searchService.buildSearchConditions(
        ['user.firstName', 'user.lastName', 'user.email', 'user.phone'],
        search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });

      const [users, total] = await queryBuilder
        .skip(skip)
        .take(limit)
        .orderBy('user.createdAt', 'DESC')
        .getManyAndCount();

      return {
        data: users,
        pagination: {
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit),
          hasNextPage: page * limit < total,
          hasPreviousPage: page > 1,
        },
      };
    }

    // Regular findAll without search
    const whereConditions: any = {
      role: UserRole.OFFICE_OWNER,
    };

    if (countryId) {
      whereConditions.countryId = countryId;
    }

    if (cityId) {
      whereConditions.cityId = cityId;
    }

    const [users, total] = await this.userRepository.findAndCount({
      where: whereConditions,
      relations: ['country', 'city', 'deliveryDrivers'],
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });

    // Fetch images directly for each user
    const usersWithImages = await Promise.all(
      users.map(async (user) => {
        const userImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.USER,
            entityId: user.id,
          },
        });
        return this.formatUserResponse(user, userImages);
      }),
    );

    return {
      data: usersWithImages,
      pagination: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
        hasNextPage: page * limit < total,
        hasPreviousPage: page > 1,
      },
    };
  }

  /**
   * Search office owners by name, email, or phone (for ADMIN) - kept for backward compatibility
   */
  async searchOfficeOwners(query: string): Promise<User[]> {
    if (!query || query.trim() === '') {
      return [];
    }

    const queryBuilder = this.userRepository.createQueryBuilder('user');
    queryBuilder.leftJoinAndSelect('user.country', 'country');
    queryBuilder.leftJoinAndSelect('user.city', 'city');
    queryBuilder.andWhere('user.role = :role', { role: UserRole.OFFICE_OWNER });

    const searchResult = this.searchService.buildSearchConditions(
      ['user.firstName', 'user.lastName', 'user.email', 'user.phone'],
      query,
      CaseSensitivity.INSENSITIVE,
    );
    queryBuilder.andWhere(searchResult.condition, {
      [searchResult.paramName]: searchResult.paramValue,
    });

    const users = await queryBuilder.take(20).getMany();

    // Fetch images directly for each user
    const usersWithImages = await Promise.all(
      users.map(async (user) => {
        const userImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.USER,
            entityId: user.id,
          },
        });
        return this.formatUserResponse(user, userImages);
      }),
    );

    return usersWithImages as User[];
  }

  /**
   * Find one office owner by ID (for ADMIN)
   */
  async findOneOfficeOwner(id: number): Promise<User> {
    const officeOwner = await this.userRepository.findOne({
      where: {
        id,
        role: UserRole.OFFICE_OWNER,
      },
      relations: ['country', 'city', 'deliveryDrivers'],
    });

    if (!officeOwner) {
      throw new NotFoundException(`Office owner with ID ${id} not found`);
    }

    // Fetch images directly from image repository
    const userImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: id,
      },
    });

    return this.formatUserResponse(officeOwner, userImages) as User;
  }

  /**
   * Update office owner information (for ADMIN)
   */
  async updateOfficeOwner(
    id: number,
    updateOfficeOwnerDto: UpdateOfficeOwnerDto,
    file?: Express.Multer.File,
  ): Promise<User> {
    // Fetch office owner without images relation
    const officeOwner = await this.userRepository.findOne({
      where: {
        id,
        role: UserRole.OFFICE_OWNER,
      },
      relations: ['country', 'city', 'deliveryDrivers'],
    });

    if (!officeOwner) {
      throw new NotFoundException(`Office owner with ID ${id} not found`);
    }

    // Fetch images directly from image repository
    const existingImages = await this.imageRepository.find({
      where: {
        entityType: ImageEntityType.USER,
        entityId: id,
      },
    });

    // Validate location if provided
    if (updateOfficeOwnerDto.countryId || updateOfficeOwnerDto.cityId) {
      await this.validateLocation(
        updateOfficeOwnerDto.countryId,
        updateOfficeOwnerDto.cityId,
      );
    }

    // Check for email conflicts
    if (updateOfficeOwnerDto.email) {
      const existingUser = await this.userRepository.findOne({
        where: { email: updateOfficeOwnerDto.email },
      });

      if (existingUser && existingUser.id !== id) {
        throw new ConflictException('Email already exists');
      }
    }

    // Delete old image if new one is uploaded
    if (file && existingImages && existingImages.length > 0) {
      const mainImage = existingImages[0];
      await this.imageProcessingService.deleteImages({
        original: mainImage.url,
        mobile: mainImage.mobileUrl ?? undefined,
        thumbnail: mainImage.thumbnailUrl ?? undefined,
      });
      await this.imageRepository.remove(mainImage);
    }

    // Handle password update
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData: any = { ...updateOfficeOwnerDto };
    if ((updateOfficeOwnerDto as { password?: string }).password) {
      updateData.password = await bcrypt.hash(
        (updateOfficeOwnerDto as { password?: string }).password!,
        10,
      );
    }

    // Update user
    await this.userRepository.update(id, updateData);

    // Process and save new image if provided
    if (file) {
      await this.processAndSaveImage(id, file);
    }

    return this.findOneOfficeOwner(id);
  }

  /**
   * Delete office owner (soft delete) (for ADMIN)
   */
  async removeOfficeOwner(id: number): Promise<void> {
    const officeOwner = await this.findOneOfficeOwner(id);

    // Delete associated image
    if (officeOwner.image) {
      await this.imageProcessingService.deleteImages({
        original: officeOwner.image.url,
        mobile: officeOwner.image.mobileUrl ?? undefined,
        thumbnail: officeOwner.image.thumbnailUrl ?? undefined,
      });
      await this.imageRepository.remove(officeOwner.image);
    }

    // Soft delete the office owner
    await this.userRepository.softDelete(id);
  }

  async resetPassword(userId: number, newPassword: string): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await this.userRepository.update(userId, { password: hashedPassword });

    return this.findOne(userId);
  }
}

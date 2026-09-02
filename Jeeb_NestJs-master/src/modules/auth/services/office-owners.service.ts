import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Like, In } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from '../../../database/entities/user.entity';
import { Image } from '../../../database/entities/image.entity';
import { UserRole } from '../../../common/enums/user-role.enum';
import { ImageProcessingService } from '../../../common/image-processing/image-processing.service';
import { ImageEntityType } from '../../../common/enums/image-entity-type.enum';
import { CreateDeliveryByOfficeDto } from '../dto/create-delivery-by-office.dto';
import { UpdateDeliveryByOfficeDto } from '../dto/update-delivery-by-office.dto';
import { CountriesService } from '../../countries/countries.service';
import { CitiesService } from '../../cities/cities.service';
import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { SearchService, CaseSensitivity } from '../../../common/search';
import { FirebaseService } from '../../firebase/firebase.service';

@Injectable()
export class OfficeOwnersService {
  private readonly logger = new Logger(OfficeOwnersService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Image)
    private readonly imagesRepository: Repository<Image>,
    @InjectRepository(DeliveryAssignment)
    private readonly deliveryAssignmentRepository: Repository<DeliveryAssignment>,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly countriesService: CountriesService,
    private readonly citiesService: CitiesService,
    private readonly searchService: SearchService,
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

  /**
   * Create a new delivery driver for the office owner
   */
  async createDelivery(
    officeOwnerId: number,
    createDeliveryDto: CreateDeliveryByOfficeDto,
    file?: Express.Multer.File,
  ): Promise<User> {
    // Validate location
    await this.validateLocation(
      createDeliveryDto.countryId,
      createDeliveryDto.cityId,
    );

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

      const updateData: any = {
        ...createDeliveryDto,
        password: hashedPassword,
        role: UserRole.DELIVERY,
        officeOwnerId: officeOwnerId,
        notificationChannel: NotificationChannel.FIREBASE,
        isOnline: true,
        verifiedAt: new Date(),
        deletedAt: null,
        birthday: createDeliveryDto.birthday
          ? new Date(createDeliveryDto.birthday)
          : undefined,
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

      const updatedUser = await this.userRepository.findOne({
        where: { id: existingUser.id },
        relations: ['country', 'city', 'images'],
      });

      if (!updatedUser) {
        throw new NotFoundException(
          `User with ID ${existingUser.id} not found after restore`,
        );
      }

      // Process and save images if provided
      if (file) {
        await this.processAndSaveImage(updatedUser.id, file);
      }

      try {
        await this.firebaseService.createDriverDocument({
          id: updatedUser.id,
          currentLat: 0,
          currentLng: 0,
          isOnline: true,
        });
      } catch (error) {
        this.logger.error(
          `Failed to create driver document in Firebase for driver ${updatedUser.id}`,
          error,
        );
      }

      return this.findOneDelivery(officeOwnerId, updatedUser.id);
    }

    // Create new delivery driver
    const hashedPassword = await bcrypt.hash(createDeliveryDto.password, 10);

    const userData: any = {
      ...createDeliveryDto,
      password: hashedPassword,
      role: UserRole.DELIVERY,
      officeOwnerId: officeOwnerId,
      notificationChannel: NotificationChannel.FIREBASE,
      isOnline: true,
      verifiedAt: new Date(),
      birthday: createDeliveryDto.birthday
        ? new Date(createDeliveryDto.birthday)
        : undefined,
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
        userData.currentLat = loc.lat;
      }
      if (loc.lng !== undefined) {
        userData.currentLng = loc.lng;
      }
      // Store as JSON object in DB
      userData.location = loc;
    }

    const user = this.userRepository.create(userData);

    const savedUser = (await this.userRepository.save(user)) as unknown as User;

    // Process and save images if provided
    if (file) {
      await this.processAndSaveImage(savedUser.id, file);
    }

    try {
      await this.firebaseService.createDriverDocument({
        id: savedUser.id,
        currentLat: 0,
        currentLng: 0,
        isOnline: true,
      });
    } catch (error) {
      this.logger.error(
        `Failed to create driver document in Firebase for driver ${savedUser.id}`,
        error,
      );
    }

    // Return user with relations
    return this.findOneDelivery(officeOwnerId, savedUser.id);
  }

  /**
   * Find all delivery drivers belonging to the office owner with search support
   */
  async findAllDeliveries(
    officeOwnerId: number,
    page: number = 1,
    limit: number = 10,
    search?: string,
    isOnline?: boolean,
  ): Promise<{ data: User[]; pagination: any }> {
    const skip = (page - 1) * limit;

    // If search is provided, use queryBuilder
    if (search) {
      const queryBuilder = this.userRepository.createQueryBuilder('user');
      queryBuilder.leftJoinAndSelect('user.country', 'country');
      queryBuilder.leftJoinAndSelect('user.city', 'city');
      queryBuilder.leftJoinAndSelect('user.imagess', 'images');

      queryBuilder.andWhere('user.role = :role', { role: UserRole.DELIVERY });
      queryBuilder.andWhere('user.officeOwnerId = :officeOwnerId', {
        officeOwnerId,
      });

      if (isOnline !== undefined) {
        queryBuilder.andWhere('user.isOnline = :isOnline', { isOnline });
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

    // Regular find without search
    const whereConditions: any = {
      role: UserRole.DELIVERY,
      officeOwnerId: officeOwnerId,
    };

    if (isOnline !== undefined) {
      whereConditions.isOnline = isOnline;
    }

    const [users, total] = await this.userRepository.findAndCount({
      where: whereConditions,
      relations: ['country', 'city', 'images'],
      skip,
      take: limit,
      order: { createdAt: 'DESC' },
    });

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

  /**
   * Search delivery drivers by name, email, or phone (kept for backward compatibility)
   */
  async searchDeliveries(
    officeOwnerId: number,
    query: string,
  ): Promise<User[]> {
    if (!query || query.trim() === '') {
      return [];
    }

    const queryBuilder = this.userRepository.createQueryBuilder('user');
    queryBuilder.leftJoinAndSelect('user.country', 'country');
    queryBuilder.leftJoinAndSelect('user.city', 'city');
    queryBuilder.leftJoinAndSelect('user.imagess', 'images');
    queryBuilder.andWhere('user.role = :role', { role: UserRole.DELIVERY });
    queryBuilder.andWhere('user.officeOwnerId = :officeOwnerId', {
      officeOwnerId,
    });

    const searchResult = this.searchService.buildSearchConditions(
      ['user.firstName', 'user.lastName', 'user.email', 'user.phone'],
      query,
      CaseSensitivity.INSENSITIVE,
    );
    queryBuilder.andWhere(searchResult.condition, {
      [searchResult.paramName]: searchResult.paramValue,
    });

    return queryBuilder.take(20).getMany();
  }

  /**
   * Find one delivery driver belonging to the office owner
   */
  async findOneDelivery(
    officeOwnerId: number,
    deliveryId: number,
  ): Promise<User> {
    const user = await this.userRepository.findOne({
      where: {
        id: deliveryId,
        role: UserRole.DELIVERY,
        officeOwnerId: officeOwnerId,
      },
      relations: ['country', 'city', 'images'],
    });

    if (!user) {
      throw new NotFoundException(
        `Delivery driver with ID ${deliveryId} not found or does not belong to your office`,
      );
    }

    return user;
  }

  /**
   * Update a delivery driver belonging to the office owner
   */
  async updateDelivery(
    officeOwnerId: number,
    deliveryId: number,
    updateDeliveryDto: UpdateDeliveryByOfficeDto,
    file?: Express.Multer.File,
  ): Promise<User> {
    // Check if delivery exists and belongs to the office owner
    const delivery = await this.findOneDelivery(officeOwnerId, deliveryId);

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

    // Delete old images if new one is uploaded
    if (file && delivery.images && delivery.images.length > 0) {
      // Get first image from the array
      const mainImage = delivery.images[0];

      // First, unlink the images from the user
      await this.userRepository.update(deliveryId, {
        images: [],
      });

      // Then delete the images files and record
      await this.imageProcessingService.deleteImages({
        original: mainImage.url,
        mobile: mainImage.mobileUrl ?? undefined,
        thumbnail: mainImage.thumbnailUrl ?? undefined,
      });
      await this.imagesRepository.remove(mainImage);
    }

    // Handle password update
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const updateData: any = { ...updateDeliveryDto };
    if ((updateDeliveryDto as { password?: string }).password) {
      updateData.password = await bcrypt.hash(
        (updateDeliveryDto as { password?: string }).password!,
        10,
      );
    }

    // Update user
    await this.userRepository.update(deliveryId, updateData);

    // Process and save new images if provided
    if (file) {
      await this.processAndSaveImage(deliveryId, file);
    }

    // Return updated delivery
    return this.findOneDelivery(officeOwnerId, deliveryId);
  }

  /**
   * Delete a delivery driver belonging to the office owner
   */
  async removeDelivery(
    officeOwnerId: number,
    deliveryId: number,
  ): Promise<void> {
    // Check if delivery exists and belongs to the office owner
    const delivery = await this.findOneDelivery(officeOwnerId, deliveryId);

    // Check if driver is currently on an active mission
    if (await this.isDriverBusy(deliveryId)) {
      throw new BadRequestException(
        'Cannot delete delivery driver while on active delivery mission',
      );
    }

    // Delete associated images
    if (delivery.images && delivery.images.length > 0) {
      const mainImage = delivery.images[0];
      await this.imageProcessingService.deleteImages({
        original: mainImage.url,
        mobile: mainImage.mobileUrl ?? undefined,
        thumbnail: mainImage.thumbnailUrl ?? undefined,
      });
      await this.imagesRepository.remove(mainImage);
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
   * Verify that a delivery driver belongs to the office owner
   */
  async verifyDeliveryOwnership(
    officeOwnerId: number,
    deliveryId: number,
  ): Promise<boolean> {
    const delivery = await this.userRepository.findOne({
      where: {
        id: deliveryId,
        role: UserRole.DELIVERY,
        officeOwnerId: officeOwnerId,
      },
    });

    return !!delivery;
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
   * Process and save images for a delivery driver
   */
  private async processAndSaveImage(
    userId: number,
    file: Express.Multer.File,
  ): Promise<void> {
    const uploadResult = await this.imageProcessingService.processAndUpload(
      file,
      `users/${userId}`,
    );

    const images = this.imagesRepository.create({
      url: uploadResult.original,
      mobileUrl: uploadResult.mobile,
      thumbnailUrl: uploadResult.thumbnail,
      entityType: ImageEntityType.USER,
      entityId: userId,
      isMain: true,
    });

    const savedImage = await this.imagesRepository.save(images);
  }
}

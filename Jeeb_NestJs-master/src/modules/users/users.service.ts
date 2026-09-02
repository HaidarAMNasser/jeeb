import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, In } from 'typeorm';
import { User } from '../../database/entities/user.entity';
import { Image } from '../../database/entities/image.entity';
import { Area } from '../../database/entities/area.entity';
import { Order } from '../../database/entities/order.entity';
import { Favorite } from '../../database/entities/favorite.entity';
import { DeliveryAssignment } from '../../database/entities/delivery-assignment.entity';
import { DeliveryStatus } from '../../common/enums/delivery-status.enum';
import { normalizePhone } from '../../common/utils/phone.util';
import { PaginatedResult } from '../../common/interfaces/paginated-result.interface';
import { CustomerFilterDto } from './dto/customer-filter.dto';
import { MerchantFilterDto } from './dto/merchant-filter.dto';
import { DeliveryFilterDto } from './dto/delivery-filter.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { CreateMerchantDto } from './dto/create-merchant.dto';
import { CreateDeliveryDto } from './dto/create-delivery.dto';
import { UserRole } from '../../common/enums/user-role.enum';
import { OrderStatus } from '../../common/enums/order-status.enum';
import { ImageEntityType } from '../../common/enums/image-entity-type.enum';
import * as bcrypt from 'bcrypt';
import { UpdateCustomerDto } from './dto/update-customer.dto';
import { UpdateMerchantDto } from './dto/update-merchant.dto';
import { UpdateDeliveryDto } from './dto/update-delivery.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationChannel } from '../../common/enums/notification-channel.enum';
import { SearchService, CaseSensitivity } from '../../common/search';
import { MerchantsService } from '../merchants/merchants.service';
import { ImageProcessingService } from '../../common/image-processing/image-processing.service';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
    @InjectRepository(DeliveryAssignment)
    private readonly deliveryAssignmentRepository: Repository<DeliveryAssignment>,
    @InjectRepository(Area)
    private readonly areaRepository: Repository<Area>,
    private readonly notificationsService: NotificationsService,
    private readonly searchService: SearchService,
    private readonly merchantsService: MerchantsService,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly dataSource: DataSource,
  ) {}
  private readonly logger = new Logger(UsersService.name);
  async findAllCustomers(
    query: CustomerFilterDto,
  ): Promise<PaginatedResult<User>> {
    const { page, limit, search, countryId, cityId } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.userRepository.createQueryBuilder('user');
    queryBuilder
      .where('user.role = :role', { role: UserRole.CUSTOMER })
      .leftJoinAndSelect('user.country', 'country')
      .leftJoinAndSelect('user.city', 'city');

    if (search) {
      const searchResult = this.searchService.buildSearchConditions(
        ['user.firstName', 'user.lastName', 'user.email', 'user.phone'],
        search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    if (countryId) {
      queryBuilder.andWhere('user.countryId = :countryId', { countryId });
    }

    if (cityId) {
      queryBuilder.andWhere('user.cityId = :cityId', { cityId });
    }

    const [data, total] = await queryBuilder
      .orderBy('user.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();
    return {
      data,
      total,
      page,
      limit,
    };
  }

  async findAllMerchants(
    query: MerchantFilterDto,
  ): Promise<PaginatedResult<User>> {
    const { page, limit, search, countryId, cityId, areaId, isActive, isOpen } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.userRepository.createQueryBuilder('user');
    queryBuilder
      .where('user.role = :role', { role: UserRole.MERCHANT })
      .leftJoinAndSelect('user.country', 'country')
      .leftJoinAndSelect('user.city', 'city')
      .leftJoinAndSelect('user.area', 'area')
      .leftJoinAndSelect('user.merchant', 'merchantProfile');

    if (search) {
      const searchResult = this.searchService.buildSearchConditions(
        ['user.firstName', 'user.lastName', 'user.email', 'user.phone'],
        search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    if (countryId) {
      queryBuilder.andWhere('user.countryId = :countryId', { countryId });
    }

    if (cityId) {
      queryBuilder.andWhere('user.cityId = :cityId', { cityId });
    }

    if (areaId) {
      queryBuilder.andWhere('user.areaId = :areaId', { areaId });
    }

    if (isActive !== undefined) {
      queryBuilder.andWhere('user.isActive = :isActive', { isActive });
    }

    if (isOpen !== undefined) {
      queryBuilder.andWhere('merchantProfile.isOpen = :isOpen', { isOpen });
    }

    const [data, total] = await queryBuilder
      .orderBy('user.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();
    return {
      data,
      total,
      page,
      limit,
    };
  }

  async findAllDeliveries(
    query: DeliveryFilterDto,
  ): Promise<PaginatedResult<User>> {
    const { page, limit, search, countryId, cityId } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.userRepository.createQueryBuilder('user');
    queryBuilder
      .where('user.role = :role', { role: UserRole.DELIVERY })
      .leftJoinAndSelect('user.country', 'country')
      .leftJoinAndSelect('user.city', 'city');

    if (search) {
      const searchResult = this.searchService.buildSearchConditions(
        ['user.firstName', 'user.lastName', 'user.email', 'user.phone'],
        search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    if (countryId) {
      queryBuilder.andWhere('user.countryId = :countryId', { countryId });
    }

    if (cityId) {
      queryBuilder.andWhere('user.cityId = :cityId', { cityId });
    }

    const [data, total] = await queryBuilder
      .orderBy('user.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();
    return {
      data,
      total,
      page,
      limit,
    };
  }

  async createCustomer(createDto: CreateCustomerDto): Promise<User> {
    const { password, ...rest } = createDto;
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = this.userRepository.create({
      ...rest,
      password: hashedPassword,
      role: UserRole.CUSTOMER,
      verifiedAt: new Date(),
    });

    const savedUser = await this.userRepository.save(user);

    // Send Welcome Email
    if (
      createDto.notificationChannel === NotificationChannel.EMAIL ||
      createDto.email
    ) {
      await this.notificationsService.sendWelcomeEmail(
        savedUser.email!,
        savedUser.firstName,
      );
    }

    return savedUser;
  }

  async createMerchant(createDto: CreateMerchantDto): Promise<User> {
    this.logger.log('🔧 [SERVICE] Creating merchant...');
    this.logger.log('   DTO:', JSON.stringify(createDto, null, 2));
    this.logger.log(
      '  countryId:',
      createDto.countryId,
      '| Type:',
      typeof createDto.countryId,
    );
    this.logger.log(
      '   cityId:',
      createDto.cityId,
      '| Type:',
      typeof createDto.cityId,
    );

    const existingEmail = await this.findOneByEmailWithDeleted(createDto.email);
    if (existingEmail && !existingEmail.deletedAt) {
      throw new BadRequestException('Email already registered');
    }

    if (createDto.areaId) {
      const areaExists = await this.areaRepository.findOne({
        where: { id: createDto.areaId },
      });
      if (!areaExists) {
        throw new BadRequestException('المنطقة المحددة غير موجودة');
      }
    }

    const { password, ...rest } = createDto;
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = this.userRepository.create({
      ...rest,
      password: hashedPassword,
      role: UserRole.MERCHANT,
      verifiedAt: new Date(),
    });

    const savedUser = await this.userRepository.save(user);

    // Send Welcome Email
    if (
      createDto.notificationChannel === NotificationChannel.EMAIL ||
      createDto.email
    ) {
      await this.notificationsService.sendWelcomeEmail(
        savedUser.email!,
        savedUser.firstName,
      );
    }

    return savedUser;
  }

  async createDelivery(createDto: CreateDeliveryDto): Promise<User> {
    const { password, ...rest } = createDto;
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = this.userRepository.create({
      ...rest,
      password: hashedPassword,
      role: UserRole.DELIVERY,
      verifiedAt: new Date(),
    });

    const savedUser = await this.userRepository.save(user);

    // Send Welcome Email
    if (
      createDto.notificationChannel === NotificationChannel.EMAIL ||
      createDto.email
    ) {
      await this.notificationsService.sendWelcomeEmail(
        savedUser.email!,
        savedUser.firstName,
      );
    }

    return savedUser;
  }

  async updateCustomer(
    id: number,
    updateDto: UpdateCustomerDto,
  ): Promise<User> {
    const user = await this.findOneById(id);
    if (!user) throw new NotFoundException('User not found');

    if (updateDto.password) {
      updateDto.password = await bcrypt.hash(updateDto.password, 10);
    }

    Object.assign(user, updateDto);
    return this.userRepository.save(user);
  }

  async updateMerchant(
    id: number,
    updateDto: UpdateMerchantDto,
    file?: Express.Multer.File,
  ): Promise<User> {
    const user = await this.findOneById(id);
    if (!user) throw new NotFoundException('User not found');

    if (updateDto.password) {
      updateDto.password = await bcrypt.hash(updateDto.password, 10);
    }

    if (updateDto.location) {
      updateDto.currentLat = updateDto.location.lat;
      updateDto.currentLng = updateDto.location.lng;
    }

    if (
      updateDto.currentLat !== undefined &&
      updateDto.currentLng !== undefined
    ) {
      updateDto.location = {
        lat: updateDto.currentLat,
        lng: updateDto.currentLng,
      };
    }

    if (updateDto.email) {
      const existingUser = await this.findOneByEmailWithDeleted(updateDto.email);
      if (existingUser && existingUser.id !== id && !existingUser.deletedAt) {
        throw new BadRequestException('Email already registered');
      }
    }

    Object.assign(user, updateDto);

    const savedUser = await this.userRepository.save(user);

    // If it's a merchant, also update the merchant profile
    if (savedUser.role === UserRole.MERCHANT) {
      const merchantProfileData = {
        restaurantName: updateDto.restaurantName,
        description: updateDto.description,
        isOpen: updateDto.isOpen,
        hidePhoneNumber: updateDto.hidePhoneNumber,
        isActive: updateDto.isActive,
      };

      // Filter out undefined fields
      Object.keys(merchantProfileData).forEach(
        (key) =>
          merchantProfileData[key] === undefined &&
          delete merchantProfileData[key],
      );

      if (Object.keys(merchantProfileData).length > 0) {
        await this.merchantsService.updateMerchant(
          id,
          merchantProfileData,
          UserRole.ADMIN,
        );
      }
    }

    return savedUser;
  }

  async updateDelivery(
    id: number,
    updateDto: UpdateDeliveryDto,
  ): Promise<User> {
    const user = await this.findOneById(id);
    if (!user) throw new NotFoundException('User not found');

    if (updateDto.password) {
      updateDto.password = await bcrypt.hash(updateDto.password, 10);
    }

    if (updateDto.location) {
      updateDto.currentLat = updateDto.location.lat;
      updateDto.currentLng = updateDto.location.lng;
    }

    if (
      updateDto.currentLat !== undefined &&
      updateDto.currentLng !== undefined
    ) {
      updateDto.location = {
        lat: updateDto.currentLat,
        lng: updateDto.currentLng,
      };
    }

    Object.assign(user, updateDto);
    const saved = await this.userRepository.save(user);
    return saved;
  }

  async findOneById(id: number): Promise<User | null> {
    return this.userRepository.findOne({ where: { id } });
  }

  async findOneByIdWithRelations(id: number): Promise<User | null> {
    return this.userRepository.findOne({
      where: { id },
      relations: ['country', 'city', 'area', 'images', 'merchant'],
    });
  }

  async findOneByEmail(email: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { email },
    });
  }

  async findOneByPhone(phone: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { phone: normalizePhone(phone) },
    });
  }

  async findOneByPhoneWithDeleted(phone: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { phone: normalizePhone(phone) },
      withDeleted: true,
    });
  }

  async findOneByEmailWithDeleted(email: string): Promise<User | null> {
    return this.userRepository.findOne({
      where: { email },
      withDeleted: true,
    });
  }

  async findOneByEmailWithPassword(email: string): Promise<User | null> {
    return this.userRepository
      .createQueryBuilder('user')
      .addSelect('user.password')
      .leftJoinAndSelect('user.country', 'country')
      .leftJoinAndSelect('user.city', 'city')
      .leftJoinAndSelect('user.area', 'area')
      .leftJoinAndSelect('user.images', 'image')
      .where('user.email = :email', { email })
      .getOne();
  }

  async findOneByPhoneWithPassword(phone: string): Promise<User | null> {
    const normalized = normalizePhone(phone);
    return this.userRepository
      .createQueryBuilder('user')
      .addSelect('user.password')
      .leftJoinAndSelect('user.country', 'country')
      .leftJoinAndSelect('user.city', 'city')
      .leftJoinAndSelect('user.area', 'area')
      .leftJoinAndSelect('user.images', 'image')
      .where('user.phone = :phone', { phone: normalized })
      .getOne();
  }

  async updateFirebaseToken(
    userId: number,
    firebaseToken: string,
  ): Promise<void> {
    await this.userRepository.update(userId, { firebaseToken });
  }

  async create(userData: Partial<User>): Promise<User> {
    const user = this.userRepository.create(userData);
    return this.userRepository.save(user);
  }

  async update(id: number, updateData: Partial<User>): Promise<User | null> {
    if (updateData.email) {
      const existingUser = await this.findOneByEmailWithDeleted(updateData.email);
      if (existingUser && existingUser.id !== id && !existingUser.deletedAt) {
        throw new BadRequestException('Email already registered');
      }
    }

    const user = await this.userRepository.preload({
      id,
      ...updateData,
    });

    if (!user) {
      return null;
    }

    return this.userRepository.save(user);
  }

  async softDelete(id: number): Promise<void> {
    const user = await this.userRepository.findOne({
      where: { id },
      withDeleted: true,
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // HARD DELETE for CUSTOMER role
    if (user.role === UserRole.CUSTOMER) {
      const queryRunner = this.dataSource.createQueryRunner();
      await queryRunner.connect();
      await queryRunner.startTransaction();

      try {
        // Delete user images
        const existingImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.USER,
            entityId: id,
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

        // Delete pending orders for this customer
        await queryRunner.manager.delete(Order, {
          customerId: id,
          status: In([OrderStatus.PENDING, OrderStatus.CONFIRMED]),
        });

        // Delete user favorites
        await queryRunner.manager.delete(Favorite, { userId: id });

        // HARD DELETE the user
        await queryRunner.manager.delete(User, id);

        await queryRunner.commitTransaction();
      } catch (error) {
        await queryRunner.rollbackTransaction();
        throw error;
      } finally {
        await queryRunner.release();
      }
    }
    // HARD DELETE for DELIVERY role
    else if (user.role === UserRole.DELIVERY) {
      const queryRunner = this.dataSource.createQueryRunner();
      await queryRunner.connect();
      await queryRunner.startTransaction();

      try {
        // Check for active delivery assignments
        const activeAssignments = await this.deliveryAssignmentRepository.find({
          where: {
            deliveryId: id,
            status: In([
              DeliveryStatus.ASSIGNED,
              DeliveryStatus.NOTIFIED,
              DeliveryStatus.ACCEPTED,
              DeliveryStatus.PICKED,
            ]),
          },
          relations: ['order'],
        });

        if (activeAssignments.length > 0) {
          const orderInfo = activeAssignments
            .map((a) => `#${a.orderId} (${a.order?.status || 'UNKNOWN'})`)
            .join(', ');
          throw new BadRequestException(
            `Cannot delete account while on active delivery mission. Active orders: ${orderInfo}`,
          );
        }

        // Delete user images
        const existingImages = await this.imageRepository.find({
          where: {
            entityType: ImageEntityType.USER,
            entityId: id,
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

        // HARD DELETE the user
        await queryRunner.manager.delete(User, id);

        await queryRunner.commitTransaction();
      } catch (error) {
        await queryRunner.rollbackTransaction();
        throw error;
      } finally {
        await queryRunner.release();
      }
    } else {
      // Soft delete for MERCHANT and ADMIN roles
      await this.userRepository.softDelete(id);
    }
  }

  async hardDelete(id: number): Promise<void> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (user) {
      await this.userRepository.remove(user);
    }
  }

  async restore(id: number): Promise<void> {
    await this.userRepository.restore(id);
  }

  async toggleMerchantOpen(id: number): Promise<User> {
    throw new BadRequestException(
      'Please use /merchants/user/:id/toggle-open endpoint instead',
    );
  }
}

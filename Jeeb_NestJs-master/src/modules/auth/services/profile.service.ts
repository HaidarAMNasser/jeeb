import {
  Injectable,
  BadRequestException,
  NotFoundException,
  Logger,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, In } from 'typeorm';
import { User } from '../../../database/entities/user.entity';
import { Image } from '../../../database/entities/image.entity';
import { Order } from '../../../database/entities/order.entity';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { Review } from '../../../database/entities/review.entity';
import { Invoice } from '../../../database/entities/invoice.entity';
import { PaymentTransaction } from '../../../database/entities/payment-transaction.entity';
import { UsersService } from '../../users/users.service';
import { MerchantsService } from '../../merchants/merchants.service';
import { ImageProcessingService } from '../../../common/image-processing/image-processing.service';
import { StorageService } from '../../../common/storage/storage.service';
import { FirebaseService } from '../../firebase/firebase.service';
import { CountriesService } from '../../countries/countries.service';
import { CitiesService } from '../../cities/cities.service';
import { AreasService } from '../../areas/areas.service';
import { ImageEntityType } from '../../../common/enums/image-entity-type.enum';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { OrderStatus } from '../../../common/enums/order-status.enum';
import { UserRole } from '../../../common/enums/user-role.enum';
import { UpdateProfileDto } from '../dto/update-profile.dto';

@Injectable()
export class ProfileService {
  private readonly logger = new Logger(ProfileService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly merchantsProfileService: MerchantsService,
    private readonly merchantsService: MerchantsService,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly storageService: StorageService,
    private readonly firebaseService: FirebaseService,
    private readonly countriesService: CountriesService,
    private readonly citiesService: CitiesService,
    private readonly areasService: AreasService,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
    @InjectRepository(Order)
    private readonly orderRepository: Repository<Order>,
    @InjectRepository(DeliveryAssignment)
    private readonly deliveryAssignmentRepository: Repository<DeliveryAssignment>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly dataSource: DataSource,
  ) {}

  async getProfile(user: User) {
    if (user.role === UserRole.MERCHANT) {
      return this.getMerchantProfile(user.id);
    }

    const foundUser = await this.usersService.findOneByIdWithRelations(user.id);
    if (!foundUser) {
      throw new NotFoundException('User not found');
    }

    const userImages = await this.imageRepository.find({
      where: { entityType: ImageEntityType.USER, entityId: user.id },
    });

    this.resolveImageUrls(userImages);

    if (user.role === UserRole.DELIVERY) {
      const { password, deletedAt, image, ...result } = foundUser as any;
      return { ...result, images: userImages };
    }

    const mainImage = userImages[0] || null;
    const imageId = mainImage?.id || null;
    const { password, deletedAt, images, ...result } = foundUser as any;
    return { ...result, image: mainImage, imageId };
  }

  async updateProfile(
    user: User,
    updateProfileDto: UpdateProfileDto,
    files?: Express.Multer.File[],
  ) {
    const dbUser = await this.userRepository.findOne({
      where: { id: user.id },
      select: ['id', 'password'],
    });
    if (!dbUser) {
      throw new NotFoundException('User not found');
    }

    if (user.role === UserRole.DELIVERY) {
      await this.checkActiveDelivery(user.id);
      await this.checkIncompleteOrders(user.id, 'update profile');
    }

    await this.validateLocation(
      updateProfileDto.countryId,
      updateProfileDto.cityId,
      updateProfileDto.areaId,
    );

    if (files && files.length > 0) {
      await this.handleProfileImageUpdate(user.id, user.role, files);
    }

    if (user.role === UserRole.MERCHANT) {
      await this.handleMerchantFieldsUpdate(user.id, updateProfileDto);
    }

    const {
      isOnline,
      latitude,
      longitude,
      password,
      new_password,
      confirmed_password,
      ...userData
    } = updateProfileDto as any;
    if (isOnline !== undefined) {
      userData.isOnline = isOnline === 'true';
    }

    if (latitude !== undefined && longitude !== undefined) {
      userData.location = {
        lat: latitude,
        lng: longitude,
      };
      userData.currentLat = latitude;
      userData.currentLng = longitude;
    }

    if (password || new_password || confirmed_password) {
      if (!password || !new_password || !confirmed_password) {
        throw new BadRequestException(
          'يجب إدخال كلمة المرور القديمة والجديدة والتأكيد',
        );
      }

      if (new_password !== confirmed_password) {
        throw new BadRequestException('كلمة المرور الجديدة غير متطابقة');
      }

      if (!dbUser.password) {
        throw new BadRequestException(
          'لا يمكنك تغيير كلمة المرور لأن حسابك ليس لديه كلمة مرور',
        );
      }

      const isPasswordValid = await bcrypt.compare(password, dbUser.password);
      if (!isPasswordValid) {
        throw new BadRequestException('كلمة المرور القديمة غير صحيحة');
      }

      const hashedPassword = await bcrypt.hash(new_password, 10);
      await this.userRepository.update(user.id, { password: hashedPassword });
    }

    await this.usersService.update(user.id, userData);

    return this.getProfile(user);
  }

  async deleteProfile(user: User) {
    const foundUser = await this.usersService.findOneByIdWithRelations(user.id);
    if (!foundUser) {
      throw new NotFoundException('User not found');
    }

    if (foundUser.role === UserRole.DELIVERY) {
      await this.checkActiveDelivery(user.id);
      await this.checkIncompleteOrders(user.id, 'delete account');
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      switch (foundUser.role) {
        case UserRole.CUSTOMER:
          await this.deleteCustomerProfile(queryRunner, foundUser.id);
          break;
        case UserRole.DELIVERY:
          await this.deleteDeliveryProfile(queryRunner, foundUser.id);
          break;
        case UserRole.MERCHANT:
          await this.deleteMerchantProfile(queryRunner, foundUser.id);
          break;
        default:
          await this.deleteUser(queryRunner, foundUser.id);
          break;
      }

      await queryRunner.commitTransaction();
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }

    return { message: 'Account deleted successfully' };
  }

  private async getMerchantProfile(userId: number) {
    const merchant = await this.merchantsProfileService.findByUserId(userId);
    if (!merchant || !merchant.user) {
      throw new NotFoundException('Merchant profile not found');
    }

    this.resolveImageUrls(merchant.user.images);

    const mainImage = merchant.user.images?.[0] || null;
    const imageId = mainImage?.id || null;

    const { user: userData, ...merchantData } = merchant;
    const { password, deletedAt, images, ...userFields } = userData;

    return { ...userFields, image: mainImage, imageId, ...merchantData };
  }

  private async validateLocation(
    countryId?: number,
    cityId?: number,
    areaId?: number,
  ) {
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

    if (areaId) {
      try {
        await this.areasService.findOne(areaId);
      } catch (error) {
        if (error instanceof NotFoundException) {
          throw new BadRequestException(`Area with ID ${areaId} not found`);
        }
        throw error;
      }
    }
  }

  private async checkActiveDelivery(userId: number) {
    const activeAssignments = await this.deliveryAssignmentRepository.find({
      where: {
        deliveryId: userId,
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
        `Cannot update account while on active delivery mission. Active orders: ${orderInfo}`,
      );
    }
  }

  private async checkIncompleteOrders(userId: number, action: string) {
    const incompleteStatuses = [
      OrderStatus.PENDING,
      OrderStatus.CONFIRMED,
      OrderStatus.SEARCHING,
      OrderStatus.PREPARING,
      OrderStatus.READY_FOR_PICKUP,
      OrderStatus.ASSIGNED,
      OrderStatus.PICKED_UP,
      OrderStatus.ON_THE_WAY,
      OrderStatus.DELIVERED,
      OrderStatus.PAID,
    ];

    const assignments = await this.deliveryAssignmentRepository.find({
      where: {
        deliveryId: userId,
        status: DeliveryStatus.ACCEPTED,
      },
      relations: ['order'],
    });

    const incompleteOrders = assignments.filter(
      (assignment) =>
        assignment.order &&
        incompleteStatuses.includes(assignment.order.status),
    );

    if (incompleteOrders.length > 0) {
      const orderInfo = incompleteOrders
        .map((a) => `#${a.orderId} (${a.order?.status || 'UNKNOWN'})`)
        .join(', ');
      throw new BadRequestException(
        `Cannot ${action} while having incomplete orders. Please complete all orders first. Incomplete orders: ${orderInfo}`,
      );
    }
  }

  private async handleProfileImageUpdate(
    userId: number,
    role: UserRole,
    files: Express.Multer.File[],
  ) {
    const dbImages = await this.imageRepository.find({
      where: { entityType: ImageEntityType.USER, entityId: userId },
      order: { createdAt: 'DESC' },
    });

    if (role === UserRole.DELIVERY) {
      await this.updateDeliveryImages(userId, files, dbImages);
    } else {
      await this.updateUserImages(userId, files[0], dbImages);
    }
  }

  private async updateDeliveryImages(
    userId: number,
    files: Express.Multer.File[],
    dbImages: Image[],
  ) {
    const filesToProcess = files.slice(0, 3);
    const imagesToDelete = dbImages.slice(0, filesToProcess.length);

    const uploadedData: any[] = [];
    for (const file of filesToProcess) {
      const processed = await this.imageProcessingService.processAndUpload(
        file,
        `users/${userId}`,
      );
      uploadedData.push(processed);
    }

    for (const oldImage of imagesToDelete) {
      await this.imageProcessingService.deleteImages({
        original: oldImage.url,
        mobile: oldImage.mobileUrl || undefined,
        thumbnail: oldImage.thumbnailUrl || undefined,
      });
      await this.imageRepository.remove(oldImage);
    }

    for (const data of uploadedData) {
      const image = this.imageRepository.create({
        entityType: ImageEntityType.USER,
        entityId: userId,
        url: data.original,
        mobileUrl: data.mobile,
        thumbnailUrl: data.thumbnail,
        isMain: true,
        displayOrder: 0,
      });
      await this.imageRepository.save(image);
    }
  }

  private async updateUserImages(
    userId: number,
    file: Express.Multer.File,
    dbImages: Image[],
  ) {
    if (dbImages.length > 0) {
      for (const oldImage of dbImages) {
        await this.imageProcessingService.deleteImages({
          original: oldImage.url,
          mobile: oldImage.mobileUrl || undefined,
          thumbnail: oldImage.thumbnailUrl || undefined,
        });
        await this.imageRepository.remove(oldImage);
      }
    }

    const processed = await this.imageProcessingService.processAndUpload(
      file,
      `users/${userId}`,
    );
    const image = this.imageRepository.create({
      entityType: ImageEntityType.USER,
      entityId: userId,
      url: processed.original,
      mobileUrl: processed.mobile,
      thumbnailUrl: processed.thumbnail,
      isMain: true,
      displayOrder: 0,
    });
    await this.imageRepository.save(image);
  }

  private async handleMerchantFieldsUpdate(
    userId: number,
    updateProfileDto: UpdateProfileDto,
  ) {
    const merchantFields: any = {};

    if (updateProfileDto.restaurantName !== undefined) {
      merchantFields.restaurantName = updateProfileDto.restaurantName;
    }
    if (updateProfileDto.isOpen !== undefined) {
      merchantFields.isOpen =
        typeof updateProfileDto.isOpen === 'string'
          ? updateProfileDto.isOpen === 'true'
          : updateProfileDto.isOpen;
    }
    if (updateProfileDto.description !== undefined) {
      merchantFields.description = updateProfileDto.description;
    }

    if (Object.keys(merchantFields).length > 0) {
      await this.merchantsProfileService.updateMerchant(userId, merchantFields);
    }
  }

  private async deleteCustomerProfile(queryRunner: any, userId: number) {
    const images = await this.imageRepository.find({
      where: { entityType: ImageEntityType.USER, entityId: userId },
    });

    for (const img of images) {
      await this.imageProcessingService.deleteImages({
        original: img.url,
        mobile: img.mobileUrl || undefined,
        thumbnail: img.thumbnailUrl || undefined,
      });
      await queryRunner.manager.remove(img);
    }

    await queryRunner.manager.delete(Review, { reviewerId: userId });
    const ordersToDelete = await queryRunner.manager.find(Order, {
      where: { customerId: userId, status: In([OrderStatus.PENDING, OrderStatus.CONFIRMED]) },
      select: ['id'],
    });
    const orderIds = ordersToDelete.map((o: any) => o.id);
    if (orderIds.length) {
      await queryRunner.manager.delete(Invoice, { orderId: In(orderIds) });
      await queryRunner.manager.delete(PaymentTransaction, { orderId: In(orderIds) });
    }
    await queryRunner.manager.delete(Order, {
      customerId: userId,
      status: In([OrderStatus.PENDING, OrderStatus.CONFIRMED]),
    });
    await queryRunner.manager.delete(DeliveryAssignment, { deliveryId: userId });
    await queryRunner.manager.delete(User, userId);
  }

  private async deleteDeliveryProfile(queryRunner: any, userId: number) {
    const activeAssignments = await this.deliveryAssignmentRepository.find({
      where: {
        deliveryId: userId,
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

    const images = await this.imageRepository.find({
      where: { entityType: ImageEntityType.USER, entityId: userId },
    });

    for (const img of images) {
      await this.imageProcessingService.deleteImages({
        original: img.url,
        mobile: img.mobileUrl || undefined,
        thumbnail: img.thumbnailUrl || undefined,
      });
      await queryRunner.manager.remove(img);
    }

    await queryRunner.manager.delete(Review, { reviewerId: userId });
    await queryRunner.manager.delete(DeliveryAssignment, { deliveryId: userId });
    await queryRunner.manager.delete(User, userId);

    try {
      await this.firebaseService.deleteDriverDocument(userId);
    } catch (error) {
      this.logger.error(
        'Failed to delete driver document from Firebase:',
        error,
      );
    }
  }

  private async deleteMerchantProfile(queryRunner: any, userId: number) {
    await queryRunner.manager.delete(Review, { reviewerId: userId });
    await queryRunner.manager.delete(DeliveryAssignment, { deliveryId: userId });
    await queryRunner.manager.delete(User, userId);
  }

  private async deleteUser(queryRunner: any, userId: number) {
    await queryRunner.manager.delete(Review, { reviewerId: userId });
    await queryRunner.manager.delete(DeliveryAssignment, { deliveryId: userId });
    await queryRunner.manager.delete(User, userId);
  }

  private resolveImageUrls(images: any[] | undefined) {
    if (!images) return;
    for (const img of images) {
      img.url = this.storageService.resolveUrl(img.url) || img.url;
      img.mobileUrl = this.storageService.resolveUrl(img.mobileUrl);
      img.thumbnailUrl = this.storageService.resolveUrl(img.thumbnailUrl);
    }
  }
}

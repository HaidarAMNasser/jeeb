import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Merchant } from '../../database/entities/merchant.entity';
import { User } from '../../database/entities/user.entity';
import { Image } from '../../database/entities/image.entity';
import { UserRole } from '../../common/enums/user-role.enum';
import { MerchantType } from '../../common/enums/merchant-type.enum';
import { ErrorCodes } from '../../common/constants/error-codes';
import { SearchService, CaseSensitivity } from '../../common/search';
import { ImageEntityType } from '../../common/enums/image-entity-type.enum';
import { GoogleDirectionsService } from '../distance/google-directions.service';
import { SettingsService } from '../settings/settings.service';

@Injectable()
export class MerchantsService {
  private readonly logger = new Logger(MerchantsService.name);

  constructor(
    @InjectRepository(Merchant)
    private readonly merchantRepository: Repository<Merchant>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
    private readonly searchService: SearchService,
    private readonly googleDirectionsService: GoogleDirectionsService,
    private readonly settingsService: SettingsService,
  ) {}

  async createMerchantProfile(
    userId: number,
    data: {
      restaurantName?: string;
      description?: string;
      isOpen?: boolean;
      type?: MerchantType;
    },
  ): Promise<Merchant> {
    this.logger.log('='.repeat(60));
    this.logger.log('🏪 [MERCHANTS] Creating merchant profile...');
    this.logger.log(`👤 [MERCHANTS] User ID: ${userId}`);
    this.logger.log(
      `📋 [MERCHANTS] Data: ${JSON.stringify({
        restaurantName: data.restaurantName,
        description: data.description,
        isOpen: data.isOpen,
        type: data.type,
      })}`,
    );

    const merchant = this.merchantRepository.create({
      userId,
      restaurantName: data.restaurantName || null,
      description: data.description || '',
      isOpen: data.isOpen ?? false,
      type: data.type || MerchantType.RESTAURANT,
    });

    const savedMerchant = await this.merchantRepository.save(merchant);

    this.logger.log(`✅ [MERCHANTS] Merchant profile created successfully`);
    this.logger.log(`🆔 [MERCHANTS] Merchant ID: ${savedMerchant.id}`);
    this.logger.log(`👤 [MERCHANTS] User ID: ${savedMerchant.userId}`);
    this.logger.log('='.repeat(60));

    return savedMerchant;
  }

  async findByUserId(userId: number): Promise<Merchant | null> {
    this.logger.log(`🔍 [MERCHANTS] Finding merchant by userId: ${userId}`);

    const merchant = await this.merchantRepository.findOne({
      where: { userId },
      relations: ['user', 'user.country', 'user.city'],
    });

    if (!merchant) {
      this.logger.warn(
        `⚠️ [MERCHANTS] Merchant not found for userId: ${userId}`,
      );
      return null;
    }

    this.logger.log(`✅ [MERCHANTS] Merchant found: ${merchant.id}`);

    if (merchant && merchant.user) {
      const images = await this.imageRepository.find({
        where: {
          entityType: ImageEntityType.USER,
          entityId: merchant.user.id,
        },
        order: { isMain: 'DESC', displayOrder: 'ASC' },
      });
      merchant.user.images = images;
      this.logger.log(`🖼️ [MERCHANTS] Loaded ${images.length} image(s)`);
    }

    return merchant;
  }

  async findById(id: number): Promise<Merchant> {
    this.logger.log(`🔍 [MERCHANTS] Finding merchant by id: ${id}`);

    const merchant = await this.merchantRepository.findOne({
      where: { id },
      relations: ['user', 'user.country', 'user.city'],
    });

    if (!merchant) {
      this.logger.error(`❌ [MERCHANTS] Merchant not found with id: ${id}`);
      throw new NotFoundException(`Merchant with ID ${id} not found`);
    }

    this.logger.log(
      `✅ [MERCHANTS] Merchant found for userId: ${merchant.userId}`,
    );

    if (merchant && merchant.user) {
      const images = await this.imageRepository.find({
        where: {
          entityType: ImageEntityType.USER,
          entityId: merchant.user.id,
        },
        order: { isMain: 'DESC', displayOrder: 'ASC' },
      });
      merchant.user.images = images;
      this.logger.log(`🖼️ [MERCHANTS] Loaded ${images.length} image(s)`);
    }

    return merchant;
  }

  async findAllMerchants(
    query: {
      page?: number;
      limit?: number;
      search?: string;
      isOpen?: boolean;
      isActive?: boolean;
      type?: MerchantType;
      sortByDistance?: boolean;
    },
    currentUser?: any,
  ): Promise<{ data: any[]; pagination: any }> {
    const page = query.page || 1;
    const limit = query.limit || 10;
    const skip = (page - 1) * limit;

    const queryBuilder = this.merchantRepository
      .createQueryBuilder('merchant')
      .leftJoinAndSelect('merchant.user', 'user')
      .leftJoinAndSelect('user.country', 'country')
      .leftJoinAndSelect('user.city', 'city');

    queryBuilder.andWhere('user.role = :role', { role: UserRole.MERCHANT });

    if (query.search) {
      const searchResult = this.searchService.buildSearchConditions(
        [
          'merchant.restaurantName',
          'user.firstName',
          'user.lastName',
          'user.email',
        ],
        query.search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    if (query.isOpen !== undefined) {
      queryBuilder.andWhere('merchant.isOpen = :isOpen', {
        isOpen: query.isOpen,
      });
    }

    if (query.isActive !== undefined) {
      queryBuilder.andWhere('user.isActive = :isActive', {
        isActive: query.isActive,
      });
    }

    if (query.type) {
      queryBuilder.andWhere('merchant.type = :type', {
        type: query.type,
      });
    }

    const customerLocation = await this.getCustomerLocation(currentUser);
    const isCustomer = !!(
      currentUser && currentUser.role === UserRole.CUSTOMER
    );
    const sortByDistance = isCustomer && customerLocation;

    if (sortByDistance) {
      queryBuilder.andWhere('user.location IS NOT NULL');
    }

    const [merchants, total] = await queryBuilder
      .skip(skip)
      .take(limit)
      .orderBy(sortByDistance ? 'merchant.id' : 'merchant.createdAt', 'DESC')
      .getManyAndCount();

    let sortedMerchants = merchants;
    if (sortByDistance && customerLocation) {
      sortedMerchants = await this.sortMerchantsByDistance(
        merchants,
        customerLocation,
      );
    } else {
      sortedMerchants = sortedMerchants.slice(skip, skip + limit);
    }

    const formattedMerchants = await Promise.all(
      sortedMerchants.map(async (merchant) => {
        if (merchant.user) {
          const images = await this.imageRepository.find({
            where: {
              entityType: ImageEntityType.USER,
              entityId: merchant.user.id,
            },
            order: { isMain: 'DESC', displayOrder: 'ASC' },
          });
          merchant.user.images = images;
        }
        return merchant;
      }),
    );

    return {
      data: formattedMerchants,
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

  async update(id: number, data: Partial<Merchant>): Promise<Merchant> {
    this.logger.log('='.repeat(60));
    this.logger.log(`✏️ [MERCHANTS] Updating merchant id: ${id}`);
    this.logger.log(`📋 [MERCHANTS] Update data: ${JSON.stringify(data)}`);

    const merchant = await this.findById(id);

    Object.assign(merchant, data);
    const updatedMerchant = await this.merchantRepository.save(merchant);

    this.logger.log(`✅ [MERCHANTS] Merchant updated successfully`);
    this.logger.log(`🆔 [MERCHANTS] Merchant ID: ${updatedMerchant.id}`);
    this.logger.log('='.repeat(60));

    return updatedMerchant;
  }

  async updateMerchant(
    userId: number,
    data: {
      restaurantName?: string;
      isOpen?: boolean;
      description?: string;
      hidePhoneNumber?: boolean;
      isActive?: boolean;
      type?: MerchantType;
    },
    role?: UserRole,
  ): Promise<Merchant> {
    const merchant = await this.findByUserId(userId);

    if (!merchant) {
      throw new NotFoundException({
        statusCode: 404,
        message: ErrorCodes.MERCHANT_PROFILE_NOT_FOUND.message,
        code: ErrorCodes.MERCHANT_PROFILE_NOT_FOUND.code,
      });
    }

    const updates: string[] = [];

    // Handle User entity updates (isActive)
    if (data.isActive !== undefined) {
      if (role === UserRole.ADMIN) {
        await this.userRepository.update(userId, { isActive: data.isActive });
        updates.push(`User.isActive: ${data.isActive}`);
      } else {
        throw new ForbiddenException('Only ADMIN can update isActive field');
      }
    }

    if (data.restaurantName !== undefined) {
      merchant.restaurantName = data.restaurantName;
      updates.push(`restaurantName: "${data.restaurantName}"`);
    }
    if (data.isOpen !== undefined) {
      merchant.isOpen = data.isOpen;
      updates.push(`isOpen: ${data.isOpen}`);
    }
    if (data.description !== undefined) {
      merchant.description = data.description;
      updates.push('description updated');
    }

    if (data.hidePhoneNumber !== undefined) {
      if (role === UserRole.ADMIN) {
        merchant.hidePhoneNumber = data.hidePhoneNumber;
        updates.push(`hidePhoneNumber: ${data.hidePhoneNumber}`);
      } else {
        throw new ForbiddenException(
          'Only ADMIN can update hidePhoneNumber field',
        );
      }
    }

    if (data.type !== undefined) {
      merchant.type = data.type;
      updates.push(`type: ${data.type}`);
    }

    const updatedMerchant = await this.merchantRepository.save(merchant);

    return updatedMerchant;
  }

  async toggleOpenStatus(userId: number): Promise<Merchant> {
    this.logger.log('='.repeat(60));
    this.logger.log(
      `🔄 [MERCHANTS] Toggling open status for userId: ${userId}`,
    );

    const merchant = await this.findByUserId(userId);

    if (!merchant) {
      this.logger.error(
        `❌ [MERCHANTS] Merchant profile not found for userId: ${userId}`,
      );
      throw new NotFoundException({
        statusCode: 404,
        message: ErrorCodes.MERCHANT_PROFILE_NOT_FOUND.message,
        code: ErrorCodes.MERCHANT_PROFILE_NOT_FOUND.code,
      });
    }

    const previousStatus = merchant.isOpen;
    merchant.isOpen = !merchant.isOpen;
    const updatedMerchant = await this.merchantRepository.save(merchant);

    this.logger.log(`✅ [MERCHANTS] Open status toggled`);
    this.logger.log(
      `🔄 [MERCHANTS] ${previousStatus ? 'CLOSED → OPEN' : 'OPEN → CLOSED'}`,
    );
    this.logger.log(`🆔 [MERCHANTS] Merchant ID: ${updatedMerchant.id}`);
    this.logger.log('='.repeat(60));

    return updatedMerchant;
  }

  async deleteMerchant(userId: number): Promise<void> {
    this.logger.log('='.repeat(60));
    this.logger.warn(`🗑️ [MERCHANTS] Deleting merchant for userId: ${userId}`);

    const merchant = await this.findByUserId(userId);

    if (!merchant) {
      this.logger.error(
        `❌ [MERCHANTS] Merchant profile not found for userId: ${userId}`,
      );
      throw new NotFoundException({
        statusCode: 404,
        message: ErrorCodes.MERCHANT_PROFILE_NOT_FOUND.message,
        code: ErrorCodes.MERCHANT_PROFILE_NOT_FOUND.code,
      });
    }

    this.logger.log(`⚠️ [MERCHANTS] Merchant ID to delete: ${merchant.id}`);
    this.logger.log(
      `👤 [MERCHANTS] Restaurant: ${merchant.restaurantName || 'N/A'}`,
    );

    await this.merchantRepository.remove(merchant);

    this.logger.log(`✅ [MERCHANTS] Merchant deleted successfully`);
    this.logger.log(`🆔 [MERCHANTS] Deleted merchant ID: ${merchant.id}`);
    this.logger.log('='.repeat(60));
  }

  private async getCustomerLocation(
    currentUser: any,
  ): Promise<{ lat: number; lng: number } | null> {
    if (!currentUser || !currentUser.id) {
      return null;
    }

    if (currentUser.role === UserRole.CUSTOMER) {
      const user = await this.userRepository.findOne({
        where: { id: currentUser.id },
        select: ['location', 'currentLat', 'currentLng'],
      });

      if (user) {
        if (user.location?.lat && user.location?.lng) {
          return { lat: user.location.lat, lng: user.location.lng };
        }
        if (user.currentLat && user.currentLng) {
          return { lat: user.currentLat, lng: user.currentLng };
        }
      }
    }

    return null;
  }

  private async sortMerchantsByDistance(
    merchants: Merchant[],
    customerLocation: { lat: number; lng: number },
  ): Promise<Merchant[]> {
    try {
      const radius = await this.getNearbyRadius();

      const merchantsWithLocation = merchants.filter(
        (m) => m.user?.location?.lat && m.user?.location?.lng,
      );

      if (merchantsWithLocation.length === 0) {
        return merchants;
      }

      const destinations = merchantsWithLocation.map((m) => ({
        id: m.id,
        coordinate: {
          lat: m.user.location!.lat,
          lng: m.user.location!.lng,
        },
      }));

      const routeResults = await this.googleDirectionsService.getMultipleRoutes(
        customerLocation,
        destinations,
      );

      const merchantsWithDistance = merchantsWithLocation.map((merchant) => {
        const route = routeResults.get(merchant.id);
        const distanceKm = route?.distanceKm || 0;
        return { merchant, distanceKm };
      });

      merchantsWithDistance.sort((a, b) => a.distanceKm - b.distanceKm);

      const sortedMerchants = merchantsWithDistance.map((m) => m.merchant);

      const merchantsWithoutLocation = merchants.filter(
        (m) => !m.user?.location?.lat || !m.user?.location?.lng,
      );

      return [...sortedMerchants, ...merchantsWithoutLocation];
    } catch (error) {
      this.logger.error(
        'Failed to sort by distance, returning unsorted',
        error,
      );
      return merchants;
    }
  }

  private async getNearbyRadius(): Promise<number> {
    try {
      const setting = await this.settingsService.getSettingByKey(
        'nearbyMerchantRadius',
      );
      return Number(setting?.value) || 10;
    } catch {
      return 10;
    }
  }
}

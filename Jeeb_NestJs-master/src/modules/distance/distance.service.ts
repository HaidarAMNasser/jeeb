import {
  Injectable,
  OnModuleInit,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { SettingsService } from '../settings/settings.service';
import { HaversineDistanceStrategy } from './strategies/haversine-distance.strategy';
import { GoogleMapsDistanceStrategy } from './strategies/google-maps-distance.strategy';
import { Coordinate } from './interfaces/distance-strategy.interface';
import { User } from '../../database/entities/user.entity';
import { Product } from '../../database/entities/product.entity';
import { Image } from '../../database/entities/image.entity';
import { ProductItemDto } from './dto/calculate-distance.dto';
import { DiscountType } from '../../common/enums/discount-type.enum';
import { ImageEntityType } from '../../common/enums/image-entity-type.enum';

export interface DistanceCalculationResult {
  distance: number;
  distanceUnit: string;
  distanceKm: number;
  calculationMethod: string;
  estimatedTip: number;
  tipCalculation: {
    tipPerKilometer: number;
    distanceKm: number;
    calculatedTip: number;
  };
}

export interface ProductWithCalculation {
  id: number;
  name: string;
  categoryId: number | null;
  merchantId: number | null;
  price: number;
  discount: number | null;
  discountType: DiscountType | null;
  priceAfterDiscount: number;
  finalPrice: number;
  quantity: number;
  itemTotal: number;
  images: any[];
}

export interface MerchantBasicInfo {
  id: number;
  firstName: string;
  lastName: string;
  restaurantName: string | null;
  phone: string | null;
  location: { lat: number; lng: number };
}

@Injectable()
export class DistanceService implements OnModuleInit {
  private readonly logger = new Logger(DistanceService.name);
  private tipPerKilometer: number = 500;
  private mediatorCommissionRate: number = 10.0;

  constructor(
    private readonly settingsService: SettingsService,
    private readonly haversineStrategy: HaversineDistanceStrategy,
    private readonly googleMapsStrategy: GoogleMapsDistanceStrategy,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
    @InjectRepository(Image)
    private readonly imageRepository: Repository<Image>,
  ) {}

  async onModuleInit() {
    await this.loadSettings();
  }

  private async loadSettings() {
    try {
      const tipSetting = await this.settingsService.getSettingByKey(
        'deliveryTipPerKilometer',
      );
      if (tipSetting && tipSetting.value) {
        this.tipPerKilometer = Number(tipSetting.value);
      }

      const commissionSetting = await this.settingsService.getSettingByKey(
        'defaultProductCommissionRate',
      );
      if (commissionSetting && commissionSetting.value) {
        this.mediatorCommissionRate = Number(commissionSetting.value);
      }

      this.logger.log(
        `Loaded settings: deliveryTipPerKilometer=${this.tipPerKilometer}, mediatorCommissionRate=${this.mediatorCommissionRate}`,
      );
    } catch (error) {
      this.logger.warn(
        'Could not load settings, using defaults: tipPerKilometer=500, mediatorCommissionRate=10.0',
      );
    }
  }

  async calculateDistanceWithTip(
    source: Coordinate,
    destination: Coordinate,
  ): Promise<DistanceCalculationResult> {
    const distanceInMeters = this.haversineStrategy.calculateDistance(
      source,
      destination,
    );
    const distanceInKm = distanceInMeters / 1000;
    const estimatedTip = Math.round(distanceInKm * this.tipPerKilometer);

    return {
      distance: distanceInMeters,
      distanceUnit: 'meters',
      distanceKm: Math.round(distanceInKm * 100) / 100,
      calculationMethod: this.haversineStrategy.getMethodName(),
      estimatedTip,
      tipCalculation: {
        tipPerKilometer: this.tipPerKilometer,
        distanceKm: Math.round(distanceInKm * 100) / 100,
        calculatedTip: estimatedTip,
      },
    };
  }

  calculateDistance(source: Coordinate, destination: Coordinate): number {
    return this.haversineStrategy.calculateDistance(source, destination);
  }

  /**
   * Filter items by radius from a source point using Haversine (fast pre-filter).
   * Returns items within the given radius in km, sorted by distance ascending.
   */
  filterByRadius<T>(
    source: Coordinate,
    items: T[],
    getCoordinate: (item: T) => Coordinate,
    radiusKm: number,
  ): Array<{ item: T; distanceMeters: number }> {
    const radiusMeters = radiusKm * 1000;

    return items
      .map((item) => {
        const coord = getCoordinate(item);
        const distanceMeters = this.haversineStrategy.calculateDistance(
          source,
          coord,
        );
        return { item, distanceMeters };
      })
      .filter((entry) => entry.distanceMeters <= radiusMeters)
      .sort((a, b) => a.distanceMeters - b.distanceMeters);
  }

  getTipPerKilometer(): number {
    return this.tipPerKilometer;
  }

  async calculateDeliveryCost(
    merchantId: number,
    destination: Coordinate,
  ): Promise<{
    distance: number;
    distanceKm: number;
    deliveryCost: number;
    merchantLocation: { lat: number; lng: number };
    destination: { lat: number; lng: number };
    tipPerKilometer: number;
  }> {
    const merchant = await this.userRepository.findOne({
      where: { id: merchantId },
    });

    if (!merchant) {
      throw new NotFoundException(`Merchant with ID ${merchantId} not found`);
    }

    if (!merchant.location) {
      throw new NotFoundException(
        `Merchant location not found for ID ${merchantId}`,
      );
    }

    const distance = this.calculateDistance(merchant.location, destination);
    const distanceKm = distance / 1000;
    const deliveryCost = Math.round(distanceKm * this.tipPerKilometer);

    return {
      distance,
      distanceKm: Math.round(distanceKm * 100) / 100,
      deliveryCost,
      merchantLocation: merchant.location,
      destination,
      tipPerKilometer: this.tipPerKilometer,
    };
  }

  async calculateDeliveryCostWithProducts(
    merchantId: number,
    destination: Coordinate,
    products?: ProductItemDto[],
  ): Promise<{
    tipPerKilometer: number;
    mediatorCommissionRate: number;
    merchant: MerchantBasicInfo;
    products: ProductWithCalculation[];
    productsTotal: number;
    distance: number;
    distanceKm: number;
    deliveryCost: number;
    mediatorCommission: number;
    deliveryCostWithCommission: number;
    grandTotal: number;
    destination: { lat: number; lng: number };
  }> {
    const merchant = await this.userRepository.findOne({
      where: { id: merchantId },
      relations: ['merchant'],
    });

    if (!merchant) {
      throw new NotFoundException(`Merchant with ID ${merchantId} not found`);
    }

    if (!merchant.location) {
      throw new NotFoundException(
        `Merchant location not found for ID ${merchantId}`,
      );
    }

    const distance = this.calculateDistance(merchant.location, destination);
    const distanceKm = distance / 1000;
    const originalDeliveryCost = Math.round(distanceKm * this.tipPerKilometer);
    const mediatorCommission = Math.round(
      (originalDeliveryCost * this.mediatorCommissionRate) / 100,
    );
    const deliveryCost = originalDeliveryCost - mediatorCommission;

    let productsTotal = 0;
    let calculatedProducts: ProductWithCalculation[] = [];

    if (products && products.length > 0) {
      const productIds = products.map((p) => p.productId);
      const dbProducts = await this.productRepository.find({
        where: { id: In(productIds) },
      });

      const dbImages = await this.imageRepository.find({
        where: {
          entityType: ImageEntityType.PRODUCT,
          entityId: In(productIds),
        },
        order: { displayOrder: 'ASC', createdAt: 'ASC' },
      });

      const imagesMap = new Map<number, any[]>();
      dbImages.forEach((img) => {
        const arr = imagesMap.get(img.entityId) || [];
        arr.push({
          id: img.id,
          url: img.url,
          mobileUrl: img.mobileUrl,
          thumbnailUrl: img.thumbnailUrl,
          isMain: img.isMain,
        });
        imagesMap.set(img.entityId, arr);
      });

      const productsMap = new Map(dbProducts.map((p) => [p.id, p]));

      calculatedProducts = products.map((item) => {
        const product = productsMap.get(item.productId);
        if (!product) {
          throw new NotFoundException(
            `Product with ID ${item.productId} not found`,
          );
        }

        const quantity = item.quantity || 1;

        const priceAfterDiscount = this.computePriceAfterDiscount(
          product.price,
          product.discount ?? undefined,
          product.discountType ?? undefined,
        );

        const finalPrice = priceAfterDiscount;
        const itemTotal = finalPrice * quantity;

        productsTotal += itemTotal;

        return {
          id: product.id,
          name: product.name,
          categoryId: product.categoryId,
          merchantId: product.merchantId,
          price: product.price,
          discount: product.discount,
          discountType: product.discountType,
          priceAfterDiscount,
          finalPrice,
          quantity,
          itemTotal: Math.round(itemTotal),
          images: imagesMap.get(product.id) || [],
        };
      });
    }

    const grandTotal = productsTotal + originalDeliveryCost;

    return {
      tipPerKilometer: this.tipPerKilometer,
      mediatorCommissionRate: this.mediatorCommissionRate,
      merchant: {
        id: merchant.id,
        firstName: merchant.firstName,
        lastName: merchant.lastName,
        restaurantName: merchant.merchant?.restaurantName || null,
        phone: merchant.phone,
        location: merchant.location,
      },
      products: calculatedProducts,
      productsTotal: Math.round(productsTotal),
      distance,
      distanceKm: Math.round(distanceKm * 100) / 100,
      deliveryCost,
      mediatorCommission,
      deliveryCostWithCommission: originalDeliveryCost,
      grandTotal: Math.round(grandTotal),
      destination,
    };
  }

  private computePriceAfterDiscount(
    price: number,
    discount?: number,
    discountType?: DiscountType,
  ): number {
    if (!discount || discount <= 0) {
      return price;
    }

    let discountValue = 0;
    if (discountType === DiscountType.PERCENTAGE) {
      discountValue = Math.floor((price * discount) / 100);
    } else {
      discountValue = discount;
    }

    return Math.max(0, price - discountValue);
  }
}

import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Offer } from '../../database/entities/offer.entity';
import { Product } from '../../database/entities/product.entity';
import { Image } from '../../database/entities/image.entity';
import { OfferProduct } from '../../database/entities/offer-product.entity';
import { CreateOfferDto } from './dto/create-offer.dto';
import { UpdateOfferDto } from './dto/update-offer.dto';
import { GetOffersQueryDto } from './dto/get-offers-query.dto';
import {
  UserRole,
  ImageEntityType,
  DiscountType,
  MerchantType,
} from '../../common/enums';
import { PaginatedResult } from '../../common/interfaces/paginated-result.interface';
import { StorageService } from '../../common/storage/storage.service';
import { SearchService, CaseSensitivity } from '../../common/search';

@Injectable()
export class OffersService {
  constructor(
    @InjectRepository(Offer)
    private readonly offerRepo: Repository<Offer>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(Image)
    private readonly imageRepo: Repository<Image>,
    @InjectRepository(OfferProduct)
    private readonly offerProductRepo: Repository<OfferProduct>,
    private readonly storageService: StorageService,
    private readonly searchService: SearchService,
  ) {}

  async create(
    createOfferDto: CreateOfferDto,
    userId: number,
    role: UserRole,
  ): Promise<Offer> {
    const {
      products: productInputs,
      productIds,
      ...offerData
    } = createOfferDto;

    let finalProductInputs = productInputs;

    if (!finalProductInputs || finalProductInputs.length === 0) {
      if (productIds && productIds.length > 0) {
        finalProductInputs = productIds.map((id: number) => ({
          productId: id,
          quantity: 1,
          isActive: true,
        }));
      }
    }

    if (!finalProductInputs || finalProductInputs.length === 0) {
      throw new BadRequestException(
        'Products are required for creating an offer',
      );
    }

    const productIdsArr = finalProductInputs.map((p) => p.productId);

    const products = await this.productRepo.find({
      where: { id: In(productIdsArr) },
    });

    if (products.length !== productIdsArr.length) {
      const foundIds = products.map((p) => p.id);
      const missingIds = productIdsArr.filter(
        (id: number) => !foundIds.includes(id),
      );
      throw new NotFoundException(
        `Products with IDs [${missingIds.join(', ')}] not found`,
      );
    }

    if (role === UserRole.MERCHANT) {
      const notOwned = products.filter((p) => p.merchantId !== userId);
      if (notOwned.length > 0) {
        throw new ForbiddenException(
          `You do not own products with IDs [${notOwned.map((p) => p.id).join(', ')}]`,
        );
      }
    }

    const merchantId =
      role === UserRole.MERCHANT
        ? userId
        : (createOfferDto as any).merchantId || userId;

    const offer = this.offerRepo.create({
      ...offerData,
      merchantId,
    });

    const savedOffer = await this.offerRepo.save(offer);

    const offerProducts = finalProductInputs.map((input) => {
      const product = products.find((p) => p.id === input.productId)!;
      return this.offerProductRepo.create({
        offerId: savedOffer.id,
        productId: input.productId,
        quantity: input.quantity || 1,
        isActive: input.isActive !== false,
        product: product,
      });
    });

    await this.offerProductRepo.save(offerProducts);

    return this.findOne(savedOffer.id);
  }

  async findAll(
    query: GetOffersQueryDto,
    userId?: number,
    role?: UserRole,
  ): Promise<PaginatedResult<any>> {
    const { page, limit } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.offerRepo
      .createQueryBuilder('offer')
      .leftJoinAndSelect('offer.offerProducts', 'offerProduct')
      .leftJoinAndSelect('offerProduct.product', 'product')
      .leftJoinAndSelect('offer.merchant', 'merchant');

    if (role === UserRole.MERCHANT && userId) {
      queryBuilder.andWhere('offer.merchantId = :userId', { userId });
    }

    if (role === UserRole.CUSTOMER || (!role && !userId)) {
      queryBuilder.andWhere(
        `NOT EXISTS (
          SELECT 1 FROM offer_products op
          INNER JOIN products p ON p.id = op."productId"
          WHERE op."offerId" = offer.id
          AND p."commissionConfirmed" = false
        )`,
      );
      queryBuilder.andWhere('offer.isActive = :active', { active: true });
    }

    if (query.isActive !== undefined) {
      const activeBool = query.isActive === 'true';
      queryBuilder.andWhere('offer.isActive = :isActive', {
        isActive: activeBool,
      });
    }

    if (query.merchantId) {
      queryBuilder.andWhere('offer.merchantId = :merchantId', {
        merchantId: query.merchantId,
      });
    }

    if (query.search) {
      const searchResult = this.searchService.buildSearchConditions(
        ["offer.name->>'ar'", "offer.name->>'en'"],
        query.search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    const [data, total] = await queryBuilder
      .skip(skip)
      .take(limit)
      .orderBy('offer.createdAt', 'DESC')
      .getManyAndCount();

    for (const offer of data) {
      if (offer.offerProducts) {
        for (const offerProduct of offer.offerProducts) {
          if (offerProduct.product && offerProduct.isActive) {
            await this.loadProductImages([offerProduct.product]);
            this.resolveProductImageUrls([offerProduct.product]);
            this.resolveComputedFields([offerProduct.product]);
          }
        }
      }
    }

    await this.loadOfferImages(data);
    this.resolveOfferImageUrls(data);

    for (const offer of data) {
      this.applyOfferDiscountToProducts(offer);
      offer.merchant = this.simplifyMerchant(offer.merchant);
      this.simplifyOfferProducts(offer);
    }

    return {
      data,
      total,
      page,
      limit,
    };
  }

  async findOne(id: number): Promise<any> {
    const offer = await this.offerRepo.findOne({
      where: { id },
      relations: ['offerProducts', 'offerProducts.product', 'merchant'],
    });

    if (!offer) {
      throw new NotFoundException(`Offer with ID ${id} not found`);
    }

    if (offer.offerProducts) {
      for (const offerProduct of offer.offerProducts) {
        if (offerProduct.product && offerProduct.isActive) {
          await this.loadProductImages([offerProduct.product]);
          this.resolveProductImageUrls([offerProduct.product]);
          this.resolveComputedFields([offerProduct.product]);
        }
      }
    }

    await this.loadOfferImages([offer]);
    this.resolveOfferImageUrls([offer]);
    this.applyOfferDiscountToProducts(offer);
    offer.merchant = this.simplifyMerchant(offer.merchant);

    return offer;
  }

  async update(
    id: number,
    updateOfferDto: UpdateOfferDto,
    userId: number,
    role: UserRole,
  ): Promise<Offer> {
    const offer = await this.offerRepo.findOne({
      where: { id },
      relations: ['offerProducts'],
    });

    if (!offer) {
      throw new NotFoundException(`Offer with ID ${id} not found`);
    }

    this.checkOfferOwnership(offer, userId, role);

    const {
      products: productInputs,
      removeProductIds,
      ...updateData
    } = updateOfferDto as any;

    if (removeProductIds && removeProductIds.length > 0) {
      await this.offerProductRepo.delete({
        offerId: id,
        productId: In(removeProductIds),
      });
    }

    if (productInputs && productInputs.length > 0) {
      const productIds = productInputs.map((p: any) => p.productId);

      const products = await this.productRepo.find({
        where: { id: In(productIds) },
      });

      if (products.length !== productIds.length) {
        const foundIds = products.map((p) => p.id);
        const missingIds = productIds.filter(
          (id: number) => !foundIds.includes(id),
        );
        throw new NotFoundException(
          `Products with IDs [${missingIds.join(', ')}] not found`,
        );
      }

      if (role === UserRole.MERCHANT) {
        const notOwned = products.filter((p) => p.merchantId !== userId);
        if (notOwned.length > 0) {
          throw new ForbiddenException(
            `You do not own products with IDs [${notOwned.map((p) => p.id).join(', ')}]`,
          );
        }
      }

      const existingProducts = await this.offerProductRepo.find({
        where: { offerId: id },
      });

      const existingProductIds = existingProducts.map((p) => p.productId);
      const toUpdate = productInputs.filter((input: any) =>
        existingProductIds.includes(input.productId),
      );
      const toAdd = productInputs.filter(
        (input: any) => !existingProductIds.includes(input.productId),
      );

      if (toUpdate.length > 0) {
        for (const input of toUpdate) {
          const existing = existingProducts.find(
            (p) => p.productId === input.productId,
          );
          if (existing) {
            if (input.quantity !== undefined) {
              existing.quantity = input.quantity;
            }
            if (input.isActive !== undefined) {
              existing.isActive = input.isActive;
            }
            await this.offerProductRepo.save(existing);
          }
        }
      }

      if (toAdd.length > 0) {
        const offerProducts = toAdd.map((input: any) => {
          const product = products.find((p) => p.id === input.productId)!;
          return this.offerProductRepo.create({
            offerId: id,
            productId: input.productId,
            quantity: input.quantity || 1,
            isActive: input.isActive !== false,
            product: product,
          });
        });
        await this.offerProductRepo.save(offerProducts);
      }
    }

    this.offerRepo.merge(offer, updateData);
    await this.offerRepo.save(offer);
    return this.findOne(id);
  }

  async remove(id: number, userId: number, role: UserRole): Promise<void> {
    const offer = await this.offerRepo.findOne({
      where: { id },
    });

    if (!offer) {
      throw new NotFoundException(`Offer with ID ${id} not found`);
    }

    this.checkOfferOwnership(offer, userId, role);

    await this.offerProductRepo.delete({ offerId: id });
    await this.offerRepo.remove(offer);
  }

  private checkOfferOwnership(
    offer: Offer,
    userId: number,
    role: UserRole,
  ): void {
    if (role === UserRole.MERCHANT) {
      if (offer.merchantId !== userId) {
        throw new ForbiddenException('You do not own this offer');
      }
    }
  }

  private async loadProductImages(products: any[]): Promise<void> {
    if (!products || products.length === 0) return;

    const productIds = products.map((p) => p.id);
    const images = await this.imageRepo.find({
      where: {
        entityType: ImageEntityType.PRODUCT,
        entityId: In(productIds),
      },
      order: {
        isMain: 'DESC',
        displayOrder: 'ASC',
      },
    });

    const imageMap = new Map<number, Image[]>();
    for (const img of images) {
      if (!imageMap.has(img.entityId)) {
        imageMap.set(img.entityId, []);
      }
      imageMap.get(img.entityId)!.push(img);
    }

    for (const product of products) {
      product.images = imageMap.get(product.id) || [];
    }
  }

  private resolveProductImageUrls(products: any[]): void {
    for (const product of products) {
      if (product.images) {
        product.images.forEach((img: Image) => {
          img.url = this.storageService.resolveUrl(img.url) || img.url;
          img.mobileUrl = this.storageService.resolveUrl(img.mobileUrl);
          img.thumbnailUrl = this.storageService.resolveUrl(img.thumbnailUrl);
        });
      }
    }
  }

  private resolveComputedFields(products: any[]): void {
    for (const product of products) {
      const priceAfterDiscount = this.computePriceAfterDiscount(
        product.price,
        product.discount ?? undefined,
        product.discountType ?? undefined,
      );
      product.priceAfterDiscount = priceAfterDiscount;
    }
  }

  private async loadOfferImages(offers: any[]): Promise<void> {
    if (!offers || offers.length === 0) return;

    const offerIds = offers.map((o) => o.id);

    const images = await this.imageRepo.find({
      where: {
        entityType: ImageEntityType.OFFER,
        entityId: In(offerIds),
      },
      order: {
        isMain: 'DESC',
        displayOrder: 'ASC',
      },
    });

    const imageMap = new Map<number, Image[]>();
    for (const img of images) {
      if (!imageMap.has(img.entityId)) {
        imageMap.set(img.entityId, []);
      }
      imageMap.get(img.entityId)!.push(img);
    }

    for (const offer of offers) {
      offer.images = imageMap.get(offer.id) || [];
    }
  }

  private resolveOfferImageUrls(offers: any[]): void {
    for (const offer of offers) {
      if (offer.images) {
        offer.images.forEach((img: Image) => {
          img.url = this.storageService.resolveUrl(img.url) || img.url;
          img.mobileUrl = this.storageService.resolveUrl(img.mobileUrl);
          img.thumbnailUrl = this.storageService.resolveUrl(img.thumbnailUrl);
        });
      }
    }
  }

  private computePriceAfterDiscount(
    price: number,
    discount?: number | null,
    discountType?: DiscountType | null,
  ): number {
    if (!discount || !discountType) return price;
    if (discountType === DiscountType.PERCENTAGE) {
      const amount = Math.floor((price * discount) / 100);
      return Math.max(0, price - amount);
    }
    if (discountType === DiscountType.FIXED) {
      return Math.max(0, price - discount);
    }
    return price;
  }

  private applyOfferDiscountToProducts(offer: any): void {
    if (!offer.offerProducts) return;

    let totalQuantity = 0;
    let subtotal = 0;
    let totalPrice = 0;

    for (const offerProduct of offer.offerProducts) {
      const product = offerProduct.product;
      if (!product || !offerProduct.isActive) continue;

      const quantity = offerProduct.quantity || 1;
      const originalPrice = product.price;
      const productDiscount = product.discount || 0;

      const commissionRate = 0;
      const commissionAmount = 0;

      let productDiscountValue = 0;
      if (productDiscount > 0) {
        if (product.discountType === DiscountType.PERCENTAGE) {
          productDiscountValue = Math.floor(
            (originalPrice * productDiscount) / 100,
          );
        } else {
          productDiscountValue = productDiscount;
        }
      }

      const priceAfterProductDiscount = originalPrice - productDiscountValue;
      const itemTotal = priceAfterProductDiscount * quantity;

      product.offerQuantity = quantity;
      product.commissionAmount = 0;
      product.commissionRate = 0;
      product.finalPrice = itemTotal;

      totalQuantity += quantity;
      subtotal += itemTotal;
      totalPrice += itemTotal;
    }

    let offerDiscountTotal = 0;
    if (offer.discountValue && offer.discountType) {
      if (offer.discountType === DiscountType.PERCENTAGE) {
        offerDiscountTotal = Math.floor((subtotal * offer.discountValue) / 100);
      } else {
        offerDiscountTotal = offer.discountValue;
      }
    }

    offer.totalQuantity = totalQuantity;
    offer.subtotal = subtotal;
    offer.productDiscountTotal = offerDiscountTotal;
    offer.totalPrice = Math.max(0, subtotal - offerDiscountTotal);
  }

  private simplifyMerchant(merchant: any): any {
    if (!merchant) return null;
    return {
      id: merchant.id,
      firstName: merchant.firstName,
      lastName: merchant.lastName,
      restaurantName: merchant.merchant?.restaurantName || null,
      type: merchant.merchant?.type || MerchantType.RESTAURANT,
    };
  }

  private simplifyProduct(product: any): any {
    if (!product) return null;
    return {
      id: product.id,
      name: product.name,
      price: product.price,
      commissionRate: 0,
      commissionAmount: 0,
      offerQuantity: product.offerQuantity,
      finalPrice: product.finalPrice,
      images: (product.images || []).map((img: any) => ({
        id: img.id,
        entityType: img.entityType,
        entityId: img.entityId,
        url: img.url,
        mobileUrl: img.mobileUrl,
        thumbnailUrl: img.thumbnailUrl,
        isMain: img.isMain,
        displayOrder: img.displayOrder,
        createdAt: img.createdAt,
        updatedAt: img.updatedAt,
      })),
    };
  }

  private simplifyOfferProducts(offer: any): void {
    if (!offer.offerProducts) return;
    offer.offerProducts = offer.offerProducts.map((op: any) => ({
      id: op.id,
      offerId: op.offerId,
      productId: op.productId,
      quantity: op.quantity,
      isActive: op.isActive,
      product: this.simplifyProduct(op.product),
      createdAt: op.createdAt,
      updatedAt: op.updatedAt,
    }));
  }
}

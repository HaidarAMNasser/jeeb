import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from '../../database/entities/product.entity';
import { Image } from '../../database/entities/image.entity';
import { Review } from '../../database/entities/review.entity';
import { OrderItem } from '../../database/entities/order-item.entity';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { GetProductsQueryDto } from './dto/get-products-query.dto';
import { CategoriesService } from '../categories/categories.service';
import { SettingsService } from '../settings/settings.service';
import {
  UserRole,
  ImageEntityType,
  ReviewEntityType,
  OrderStatus,
} from '../../common/enums';
import { PaginatedResult } from '../../common/interfaces/paginated-result.interface';
import { ImageProcessingService } from '../../common/image-processing/image-processing.service';
import {
  ErrorCodes,
  createErrorResponse,
} from '../../common/constants/error-codes';

import { ProductImagesService } from './services/product-images.service';
import { ProductQueryService } from './services/product-query.service';
import { ProductPricingService } from './services/product-pricing.service';
import { ProductEnrichmentService } from './services/product-enrichment.service';
import { ProductResponseMapper } from './mappers/product-response.mapper';
import { ProductAccessValidator } from './validators/product-access.validator';
import { ProductStockValidator } from './validators/product-stock.validator';

@Injectable()
export class ProductsService {
  private readonly logger = new Logger(ProductsService.name);

  constructor(
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(Image)
    private readonly imageRepo: Repository<Image>,
    @InjectRepository(Review)
    private readonly reviewRepo: Repository<Review>,
    @InjectRepository(OrderItem)
    private readonly orderItemRepo: Repository<OrderItem>,
    private readonly categoriesService: CategoriesService,
    private readonly settingsService: SettingsService,
    private readonly imageProcessingService: ImageProcessingService,

    // Injected specialized services
    private readonly productImagesService: ProductImagesService,
    private readonly productQueryService: ProductQueryService,
    private readonly productPricingService: ProductPricingService,
    private readonly productEnrichmentService: ProductEnrichmentService,
    private readonly productResponseMapper: ProductResponseMapper,
  ) {}

  async create(
    createProductDto: CreateProductDto,
    files: Array<Express.Multer.File>,
    userId: number,
    role: UserRole,
  ): Promise<any> {
    this.logger.log(
      `🚀 [PRODUCTS] Starting product creation for user ${userId}...`,
    );

    // Prevent merchants from setting commission fields
    if (role === UserRole.MERCHANT) {
      if (
        createProductDto.commissionRate !== undefined ||
        createProductDto.commissionConfirmed !== undefined
      ) {
        throw new ForbiddenException(
          createErrorResponse(
            'MERCHANT_CANNOT_UPDATE_COMMISSION',
            403,
            'Merchants cannot set commission fields',
          ),
        );
      }
    }

    await this.categoriesService.findOne(createProductDto.categoryId);
    ProductStockValidator.validateStockForCreate(createProductDto);

    const merchantId = createProductDto.merchantId || userId;
    if (role === UserRole.MERCHANT && merchantId !== userId) {
      throw new ForbiddenException(
        createErrorResponse(
          'PRODUCT_ACCESS_DENIED',
          403,
          'You can only create products for yourself',
        ),
      );
    }

    const product = this.productRepo.create({
      ...createProductDto,
      merchantId,
      stockQuantity: createProductDto.hasStock
        ? (createProductDto.stockQuantity ?? null)
        : null,
      isExternal: !!createProductDto.isExternal,
      externalProvider: createProductDto.isExternal
        ? (createProductDto.externalProvider ?? null)
        : null,
      externalId: createProductDto.isExternal
        ? (createProductDto.externalId ?? null)
        : null,
      commissionRate:
        role === UserRole.ADMIN && createProductDto.commissionRate !== undefined
          ? createProductDto.commissionRate
          : (await this.settingsService.getSettings())
              .defaultProductCommissionRate,
      commissionConfirmed:
        role === UserRole.ADMIN
          ? (createProductDto.commissionConfirmed ?? true)
          : true,
    });

    const savedProduct = await this.productRepo.save(product);

    if (files && files.length > 0) {
      await this.productImagesService.processAndSaveImages(
        savedProduct.id,
        files,
        0,
      );
    }

    return this.findOne(savedProduct.id);
  }

  async findAll(
    query: GetProductsQueryDto,
    userId?: number,
    role?: UserRole,
  ): Promise<PaginatedResult<any>> {
    return this.productQueryService.findAll(query, userId, role);
  }

  async findOne(
    id: number,
    userId?: number,
    role?: UserRole,
    resolveImages = true,
  ): Promise<any> {
    const product = await this.productRepo.findOne({
      where: { id },
      relations: ['merchant', 'category'],
    });

    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }

    ProductAccessValidator.checkProductReadAccess(
      product,
      userId ?? 0,
      role ?? UserRole.CUSTOMER,
    );

    if (
      (role === UserRole.CUSTOMER || (!role && !userId)) &&
      !product.commissionConfirmed
    ) {
      throw new ForbiddenException({
        message: ErrorCodes.PRODUCT_NOT_AVAILABLE.message,
        code: ErrorCodes.PRODUCT_NOT_AVAILABLE.code,
      });
    }

    const images = await this.imageRepo.find({
      where: { entityType: ImageEntityType.PRODUCT, entityId: id },
      order: { isMain: 'DESC', displayOrder: 'ASC' },
    });
    product.images = images;

    if (resolveImages) {
      this.productImagesService.resolveImageUrls(product);
    }

    this.productPricingService.resolveComputedFields(product);

    const reviewsMap = await this.productEnrichmentService.getProductReviews([
      id,
    ]);
    const reviews = reviewsMap.get(id) || [];
    const isFavorite = await this.productEnrichmentService.checkIsFavorite(
      userId,
      id,
    );
    const cartQuantity = (
      await this.productEnrichmentService.getProductsInCart(userId, [id])
    ).get(id);

    return this.productResponseMapper.formatProductResponse(
      product,
      reviews,
      isFavorite,
      cartQuantity,
    );
  }

  async update(
    id: number,
    updateProductDto: UpdateProductDto,
    files: Array<Express.Multer.File>,
    userId: number,
    role: UserRole,
  ): Promise<any> {
    const product = await this.productRepo.findOne({
      where: { id },
      relations: ['merchant'],
    });
    if (!product) {
      throw new NotFoundException(`Product with ID ${id} not found`);
    }
    ProductAccessValidator.checkProductOwnership(product, userId, role);

    if (role === UserRole.MERCHANT) {
      if (
        updateProductDto.commissionRate !== undefined ||
        updateProductDto.commissionConfirmed !== undefined
      ) {
        throw new ForbiddenException(
          createErrorResponse(
            'MERCHANT_CANNOT_UPDATE_COMMISSION',
            403,
            'Merchants cannot update commission fields',
          ),
        );
      }
    }

    if (updateProductDto.categoryId) {
      await this.categoriesService.findOne(updateProductDto.categoryId);
    }

    const {
      deleteImageIds,
      imagesMetadata,
      commissionRate,
      commissionConfirmed,
    } = updateProductDto as any;

    let imageIdsToDelete: number[] = [];
    if (deleteImageIds) {
      imageIdsToDelete = Array.isArray(deleteImageIds)
        ? deleteImageIds
        : typeof deleteImageIds === 'string'
          ? JSON.parse(deleteImageIds)
          : [];
    }

    for (const imageId of imageIdsToDelete) {
      await this.productImagesService.deleteProductImage(
        imageId,
        id,
        userId,
        role,
      );
    }

    if (files && files.length > 0) {
      const maxOrderImage = await this.imageRepo.findOne({
        where: { entityType: ImageEntityType.PRODUCT, entityId: id },
        order: { displayOrder: 'DESC' },
      });
      const startOrder = maxOrderImage ? maxOrderImage.displayOrder + 1 : 0;
      await this.productImagesService.processAndSaveImages(
        product.id,
        files,
        startOrder,
      );
    }

    const updateData = {
      name: updateProductDto.name,
      shortDescription: updateProductDto.shortDescription,
      description: updateProductDto.description,
      personCount: updateProductDto.personCount,
      price: updateProductDto.price,
      discount: updateProductDto.discount,
      discountType: updateProductDto.discountType,
      isAvailable: updateProductDto.isAvailable,
      hasStock: updateProductDto.hasStock,
      stockQuantity: updateProductDto.stockQuantity,
      categoryId: updateProductDto.categoryId,
      isExternal: updateProductDto.isExternal,
      externalProvider: updateProductDto.externalProvider,
      externalId: updateProductDto.externalId,
    };

    if (role === UserRole.ADMIN) {
      if (commissionRate !== undefined) product.commissionRate = commissionRate;
      if (commissionConfirmed !== undefined)
        product.commissionConfirmed = commissionConfirmed;
    }

    this.productRepo.merge(product, updateData);

    if (imagesMetadata) {
      await this.productImagesService.updateImagesMetadata(id, imagesMetadata);
    }

    ProductStockValidator.validateStockForUpdate(product, updateProductDto);

    if (!product.hasStock) product.stockQuantity = null;

    if (updateProductDto.isExternal === false) {
      product.isExternal = false;
      product.externalProvider = null;
      product.externalId = null;
    } else if (updateProductDto.isExternal === true) {
      product.isExternal = true;
      if (updateProductDto.externalProvider !== undefined)
        product.externalProvider = updateProductDto.externalProvider ?? null;
      if (updateProductDto.externalId !== undefined)
        product.externalId = updateProductDto.externalId ?? null;
    }

    const savedProduct = await this.productRepo.save(product);
    return this.findOne(savedProduct.id);
  }

  async remove(id: number, userId: number, role: UserRole): Promise<void> {
    const product = await this.findOne(id, undefined, undefined, false);
    ProductAccessValidator.checkProductOwnership(product, userId, role);

    const orderItems = await this.orderItemRepo.find({
      where: { productId: id },
      relations: ['order'],
    });

    const pendingOrderIds = orderItems
      .filter((item) => item.order?.status === OrderStatus.PENDING)
      .map((item) => item.id);
    if (pendingOrderIds.length > 0)
      await this.orderItemRepo.delete(pendingOrderIds);

    const otherOrderItemIds = orderItems
      .filter((item) => item.order && item.order.status !== OrderStatus.PENDING)
      .map((item) => item.id);
    if (otherOrderItemIds.length > 0)
      await this.orderItemRepo.update(otherOrderItemIds, { productId: null });

    if (product.images && product.images.length > 0) {
      for (const img of product.images) {
        await this.imageProcessingService.deleteImages({
          original: img.url,
          mobile: img.mobileUrl || undefined,
          thumbnail: img.thumbnailUrl || undefined,
        });
      }
      await this.imageRepo.delete({
        entityType: ImageEntityType.PRODUCT,
        entityId: id,
      });
    }

    await this.reviewRepo.delete({
      entityType: ReviewEntityType.PRODUCT,
      entityId: id,
    });
    await this.productRepo.remove(product);
  }

  async deleteImage(
    imageId: number,
    userId: number,
    role: UserRole,
  ): Promise<void> {
    return this.productImagesService.deleteImage(imageId, userId, role);
  }
}

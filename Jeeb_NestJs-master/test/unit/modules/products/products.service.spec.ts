import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { ProductsService } from '../../../../src/modules/products/products.service';
import { Product } from '../../../../src/database/entities/product.entity';
import { Image } from '../../../../src/database/entities/image.entity';
import { Review } from '../../../../src/database/entities/review.entity';
import { OrderItem } from '../../../../src/database/entities/order-item.entity';
import { CategoriesService } from '../../../../src/modules/categories/categories.service';
import { SettingsService } from '../../../../src/modules/settings/settings.service';
import { ImageProcessingService } from '../../../../src/common/image-processing/image-processing.service';
import { ProductImagesService } from '../../../../src/modules/products/services/product-images.service';
import { ProductQueryService } from '../../../../src/modules/products/services/product-query.service';
import { ProductPricingService } from '../../../../src/modules/products/services/product-pricing.service';
import { ProductEnrichmentService } from '../../../../src/modules/products/services/product-enrichment.service';
import { ProductResponseMapper } from '../../../../src/modules/products/mappers/product-response.mapper';
import { UserRole } from '../../../../src/common/enums/user-role.enum';

describe('ProductsService', () => {
  let service: ProductsService;
  let productRepo: jest.Mocked<typeof jest.fn>;
  let settingsService: jest.Mocked<SettingsService>;
  let productQueryService: jest.Mocked<ProductQueryService>;
  let categoriesService: jest.Mocked<CategoriesService>;
  let moduleRef: TestingModule;

  const mockProduct: any = {
    id: 1,
    name: 'Test Product',
    price: 100,
    userId: 1,
    commissionConfirmed: true,
    commissionRate: 10,
    isExternal: false,
    hasStock: false,
  };

  beforeEach(async () => {
    moduleRef = await Test.createTestingModule({
      providers: [
        ProductsService,
        { provide: getRepositoryToken(Product), useValue: {
          create: jest.fn(),
          save: jest.fn(),
          findOne: jest.fn(),
          merge: jest.fn(),
          remove: jest.fn(),
        }},
        { provide: getRepositoryToken(Image), useValue: {
          find: jest.fn().mockResolvedValue([]),
          save: jest.fn(),
        }},
        { provide: getRepositoryToken(Review), useValue: {} },
        { provide: getRepositoryToken(OrderItem), useValue: {} },
        { provide: CategoriesService, useValue: { findOne: jest.fn() }},
        { provide: SettingsService, useValue: { getSettings: jest.fn().mockResolvedValue({ defaultProductCommissionRate: 5 }) }},
        { provide: ImageProcessingService, useValue: { processAndUpload: jest.fn(), deleteImages: jest.fn() }},
        { provide: ProductImagesService, useValue: { uploadImages: jest.fn(), deleteProductImages: jest.fn(), processAndSaveImages: jest.fn(), resolveImageUrls: jest.fn() }},
        { provide: ProductQueryService, useValue: { findAll: jest.fn() }},
        { provide: ProductPricingService, useValue: { resolveComputedFields: jest.fn() }},
        { provide: ProductEnrichmentService, useValue: { getProductReviews: jest.fn().mockResolvedValue(new Map()), checkIsFavorite: jest.fn().mockResolvedValue(false), getProductsInCart: jest.fn().mockResolvedValue(new Map()) }},
        { provide: ProductResponseMapper, useValue: { mapProductResponse: jest.fn((p) => p), formatProductResponse: jest.fn((p) => p) }},
      ],
    }).compile();

    service = moduleRef.get<ProductsService>(ProductsService);
    productRepo = moduleRef.get(getRepositoryToken(Product));
    settingsService = moduleRef.get(SettingsService);
    productQueryService = moduleRef.get(ProductQueryService);
    categoriesService = moduleRef.get(CategoriesService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    const dto = { name: 'New Product', price: 50, categoryIds: [1] } as any;

    it('should throw ForbiddenException when merchant sets commission', async () => {
      await expect(
        service.create({ ...dto, commissionRate: 10 }, [], 1, UserRole.MERCHANT),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should create product when ADMIN', async () => {
      categoriesService.findOne.mockResolvedValue({ id: 1, name: 'Test' } as any);
      productRepo.create.mockReturnValue(mockProduct);
      productRepo.save.mockResolvedValue(mockProduct);
      productRepo.findOne.mockResolvedValue(mockProduct);

      const result = await service.create({ ...dto, categoryId: 1 }, [], 1, UserRole.ADMIN);

      expect(productRepo.create).toHaveBeenCalled();
      expect(productRepo.save).toHaveBeenCalled();
      expect(result).toBeDefined();
    });
  });

  describe('findAll', () => {
    it('should delegate to productQueryService', async () => {
      const query = { page: 1, limit: 10 };
      const paginatedResult = { data: [mockProduct], total: 1, page: 1, limit: 10 };
      productQueryService.findAll.mockResolvedValue(paginatedResult);

      const result = await service.findAll(query);

      expect(productQueryService.findAll).toHaveBeenCalledWith(query, undefined, undefined);
      expect(result).toEqual(paginatedResult);
    });
  });

  describe('findOne', () => {
    it('should find product by id and enrich it', async () => {
      productRepo.findOne.mockResolvedValue(mockProduct);

      const result = await service.findOne(1, 1, UserRole.ADMIN);

      expect(productRepo.findOne).toHaveBeenCalledWith({
        where: { id: 1 },
        relations: ['merchant', 'category'],
      });
      expect(result).toBeDefined();
    });

    it('should throw NotFoundException when not found', async () => {
      productRepo.findOne.mockResolvedValue(null);
      await expect(service.findOne(999)).rejects.toThrow(NotFoundException);
    });
  });

  describe('update', () => {
    const dto = { name: 'Updated' } as any;

    it('should throw ForbiddenException when merchant sets commission', async () => {
      productRepo.findOne.mockResolvedValue(mockProduct);
      await expect(
        service.update(1, { ...dto, commissionRate: 10 }, [], 1, UserRole.MERCHANT),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should update product when found', async () => {
      productRepo.findOne.mockResolvedValue(mockProduct);
      productRepo.save.mockResolvedValue({ ...mockProduct, name: 'Updated' });

      const result = await service.update(1, dto, [], 1, UserRole.ADMIN);

      expect(productRepo.save).toHaveBeenCalled();
      expect(result).toBeDefined();
    });

    it('should throw NotFoundException when not found', async () => {
      productRepo.findOne.mockResolvedValue(null);
      await expect(service.update(999, dto, [], 1, UserRole.ADMIN)).rejects.toThrow(NotFoundException);
    });
  });
});

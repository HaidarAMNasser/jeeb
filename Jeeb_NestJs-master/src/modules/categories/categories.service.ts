import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Category } from '../../database/entities/category.entity';
import { Image } from '../../database/entities/image.entity';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { GetCategoriesQueryDto } from './dto/get-categories-query.dto';
import { PaginatedResult } from '../../common/interfaces/paginated-result.interface';
import { UserRole } from '../../common/enums/user-role.enum';
import { ImageEntityType } from '../../common/enums/image-entity-type.enum';
import { StorageService } from '../../common/storage/storage.service';
import { ImageProcessingService } from '../../common/image-processing/image-processing.service';
import { SearchService, CaseSensitivity } from '../../common/search';

@Injectable()
export class CategoriesService {
  constructor(
    @InjectRepository(Category)
    private readonly categoryRepo: Repository<Category>,
    @InjectRepository(Image)
    private readonly imageRepo: Repository<Image>,
    private readonly storageService: StorageService,
    private readonly imageProcessingService: ImageProcessingService,
    private readonly searchService: SearchService,
  ) {}

  async create(
    createCategoryDto: CreateCategoryDto,
    file: Express.Multer.File | undefined,
    userId: number,
    role: UserRole,
  ): Promise<Category> {
    // Permission Check - Only Admins can create categories
    if (role !== UserRole.ADMIN) {
      throw new ForbiddenException('Only Admins can create categories');
    }

    const category = this.categoryRepo.create(createCategoryDto);
    const savedCategory = await this.categoryRepo.save(category);

    if (file) {
      await this.processAndSaveImage(savedCategory.id, file);
    }

    return this.findOne(savedCategory.id);
  }

  async findAll(
    query: GetCategoriesQueryDto,
  ): Promise<PaginatedResult<Category>> {
    const { page = 1, limit = 10, search, isActive } = query;
    const skip = (page - 1) * limit;

    const queryBuilder = this.categoryRepo.createQueryBuilder('category');

    // Manually join images using the polymorphic relationship
    queryBuilder.leftJoinAndMapMany(
      'category.images',
      Image,
      'image',
      'image.entityId = category.id AND image.entityType = :imageType',
      { imageType: ImageEntityType.CATEGORY },
    );

    if (isActive !== undefined) {
      const activeBool = isActive === 'true';
      queryBuilder.andWhere('category.isActive = :isActive', {
        isActive: activeBool,
      });
    }

    if (search) {
      const searchResult = this.searchService.buildSearchConditions(
        ["category.name->>'ar'", "category.name->>'en'"],
        search,
        CaseSensitivity.INSENSITIVE,
      );
      queryBuilder.andWhere(searchResult.condition, {
        [searchResult.paramName]: searchResult.paramValue,
      });
    }

    const [data, total] = await queryBuilder
      .orderBy('category.displayOrder', 'ASC')
      .addOrderBy('category.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    // Resolve Image URLs
    this.resolveImageUrls(data);

    return {
      data,
      total,
      page,
      limit,
    };
  }

  async findOne(id: number): Promise<Category> {
    const category = await this.categoryRepo.findOne({ where: { id } });
    if (!category) {
      throw new NotFoundException(`Category with ID ${id} not found`);
    }

    // Manually load images
    const images = await this.imageRepo.find({
      where: {
        entityType: ImageEntityType.CATEGORY,
        entityId: id,
      },
      order: {
        isMain: 'DESC',
        displayOrder: 'ASC',
      },
    });
    category.images = images;

    this.resolveImageUrls(category);

    return category;
  }

  async update(
    id: number,
    updateCategoryDto: UpdateCategoryDto,
    file: Express.Multer.File | undefined,
    userId: number,
    role: UserRole,
  ): Promise<Category> {
    const category = await this.findOne(id);

    // Permission Check - Only Admins can update categories
    if (role !== UserRole.ADMIN) {
      throw new ForbiddenException('Only Admins can update categories');
    }

    if (file) {
      // Delete old images
      if (category.images && category.images.length > 0) {
        for (const img of category.images) {
          await this.imageProcessingService.deleteImages({
            original: img.url,
            mobile: img.mobileUrl || undefined,
            thumbnail: img.thumbnailUrl || undefined,
          });
          await this.imageRepo.remove(img);
        }
      }
      // Upload new image
      await this.processAndSaveImage(category.id, file);
    }

    this.categoryRepo.merge(category, updateCategoryDto);
    await this.categoryRepo.save(category);
    return this.findOne(category.id);
  }

  async remove(id: number, userId: number, role: UserRole): Promise<void> {
    const category = await this.findOne(id);

    // Permission Check - Only Admins can delete categories
    if (role !== UserRole.ADMIN) {
      throw new ForbiddenException('Only Admins can delete categories');
    }

    // Delete images
    if (category.images && category.images.length > 0) {
      for (const img of category.images) {
        await this.imageProcessingService.deleteImages({
          original: img.url,
          mobile: img.mobileUrl || undefined,
          thumbnail: img.thumbnailUrl || undefined,
        });
        await this.imageRepo.remove(img);
      }
    }

    await this.categoryRepo.remove(category);
  }

  private async processAndSaveImage(
    categoryId: number,
    file: Express.Multer.File,
  ): Promise<void> {
    const path = `categories/${categoryId}`;
    const processedImages = await this.imageProcessingService.processAndUpload(
      file,
      path,
    );

    const image = this.imageRepo.create({
      entityType: ImageEntityType.CATEGORY,
      entityId: categoryId,
      url: processedImages.original,
      mobileUrl: processedImages.mobile,
      thumbnailUrl: processedImages.thumbnail,
      isMain: true,
      displayOrder: 0,
    });

    await this.imageRepo.save(image);
  }

  private resolveImageUrls(categories: Category | Category[]): void {
    const items = Array.isArray(categories) ? categories : [categories];
    items.forEach((category) => {
      if (category.images) {
        category.images.forEach((img) => {
          img.url = this.storageService.resolveUrl(img.url) || img.url;
          img.mobileUrl = this.storageService.resolveUrl(img.mobileUrl);
          img.thumbnailUrl = this.storageService.resolveUrl(img.thumbnailUrl);
        });
      }
    });
  }
}

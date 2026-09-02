import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Image } from '../../../database/entities/image.entity';
import { Product } from '../../../database/entities/product.entity';
import { ImageEntityType, UserRole } from '../../../common/enums';
import { StorageService } from '../../../common/storage/storage.service';
import { ImageProcessingService } from '../../../common/image-processing/image-processing.service';
import { ProductAccessValidator } from '../validators/product-access.validator';

export interface ImageMetadata {
  id: number;
  isMain?: boolean;
  displayOrder?: number;
}

@Injectable()
export class ProductImagesService {
  private readonly logger = new Logger(ProductImagesService.name);

  constructor(
    @InjectRepository(Image)
    private readonly imageRepo: Repository<Image>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    private readonly storageService: StorageService,
    private readonly imageProcessingService: ImageProcessingService,
  ) {}

  async processAndSaveImages(
    productId: number,
    files: Array<Express.Multer.File>,
    startDisplayOrder: number,
  ): Promise<void> {
    this.logger.log(
      `📁 [IMAGES] Starting image processing for product ID: ${productId}`,
    );

    const images: Image[] = [];

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const path = `products/${productId}`;

      try {
        const processedImages =
          await this.imageProcessingService.processAndUpload(file, path);

        const image = this.imageRepo.create({
          entityType: ImageEntityType.PRODUCT,
          entityId: productId,
          url: processedImages.original,
          mobileUrl: processedImages.mobile,
          thumbnailUrl: processedImages.thumbnail,
          isMain: startDisplayOrder === 0 && i === 0,
          displayOrder: startDisplayOrder + i,
        });

        images.push(image);
      } catch (error) {
        this.logger.error(
          `❌ [IMAGES] Failed to process image ${file.originalname}: ${error.message}`,
        );
        throw error;
      }
    }

    if (images.length > 0) {
      await this.imageRepo.save(images);
    }
  }

  async updateImagesMetadata(
    productId: number,
    imagesMetadata: string | ImageMetadata[],
  ): Promise<void> {
    let metadata: ImageMetadata[];
    try {
      metadata =
        typeof imagesMetadata === 'string'
          ? (JSON.parse(imagesMetadata) as ImageMetadata[])
          : imagesMetadata;
    } catch {
      throw new BadRequestException('Invalid imagesMetadata JSON');
    }

    if (Array.isArray(metadata)) {
      const currentImages = await this.imageRepo.find({
        where: { entityType: ImageEntityType.PRODUCT, entityId: productId },
      });

      const hasMainUpdate = metadata.some((m) => m.isMain === true);

      if (hasMainUpdate) {
        for (const img of currentImages) {
          img.isMain = false;
        }
      }

      const updates: Image[] = [];
      for (const meta of metadata) {
        if (meta.id) {
          const image = currentImages.find((img) => img.id === meta.id);
          if (!image) {
            throw new BadRequestException(
              `Image with ID ${meta.id} not found for this product`,
            );
          }
          let changed = false;
          if (meta.isMain !== undefined && image.isMain !== meta.isMain) {
            image.isMain = meta.isMain;
            changed = true;
          }
          if (
            meta.displayOrder !== undefined &&
            image.displayOrder !== meta.displayOrder
          ) {
            image.displayOrder = meta.displayOrder;
            changed = true;
          }
          if (changed) {
            updates.push(image);
          }
        }
      }

      if (updates.length > 0) {
        if (hasMainUpdate) {
          await this.imageRepo.save(currentImages);
        } else {
          await this.imageRepo.save(updates);
        }
      }
    }
  }

  resolveImageUrls(products: Product | Product[]): void {
    const items = Array.isArray(products) ? products : [products];
    items.forEach((product) => {
      if (product.images) {
        product.images.forEach((img) => {
          img.url = this.storageService.resolveUrl(img.url) || img.url;
          img.mobileUrl = this.storageService.resolveUrl(img.mobileUrl);
          img.thumbnailUrl = this.storageService.resolveUrl(img.thumbnailUrl);
        });
      }
    });
  }

  async deleteProductImage(
    imageId: number,
    productId: number,
    userId: number,
    role: UserRole,
  ): Promise<void> {
    const image = await this.imageRepo.findOne({ where: { id: imageId } });

    if (!image) {
      throw new NotFoundException(`Image with ID ${imageId} not found`);
    }

    if (
      image.entityType !== ImageEntityType.PRODUCT ||
      image.entityId !== productId
    ) {
      throw new BadRequestException(
        `Image with ID ${imageId} does not belong to product with ID ${productId}`,
      );
    }

    const product = await this.productRepo.findOne({
      where: { id: productId },
    });
    if (product) {
      ProductAccessValidator.checkProductOwnership(product, userId, role);
    } else if (role !== UserRole.ADMIN) {
      throw new NotFoundException('Associated product not found');
    }

    await this.imageProcessingService.deleteImages({
      original: image.url,
      mobile: image.mobileUrl || undefined,
      thumbnail: image.thumbnailUrl || undefined,
    });

    await this.imageRepo.remove(image);
  }

  async deleteImage(
    imageId: number,
    userId: number,
    role: UserRole,
  ): Promise<void> {
    const image = await this.imageRepo.findOne({ where: { id: imageId } });

    if (!image) {
      throw new NotFoundException(`Image with ID ${imageId} not found`);
    }

    if (image.entityType !== ImageEntityType.PRODUCT) {
      throw new BadRequestException(
        `Image with ID ${imageId} is not a product image`,
      );
    }

    const product = await this.productRepo.findOne({
      where: { id: image.entityId },
      relations: ['merchant'],
    });

    if (product) {
      ProductAccessValidator.checkProductOwnership(product, userId, role);
    } else if (role !== UserRole.ADMIN) {
      throw new NotFoundException(
        `Product with ID ${image.entityId} not found`,
      );
    }

    await this.imageProcessingService.deleteImages({
      original: image.url,
      mobile: image.mobileUrl || undefined,
      thumbnail: image.thumbnailUrl || undefined,
    });

    await this.imageRepo.remove(image);
  }
}

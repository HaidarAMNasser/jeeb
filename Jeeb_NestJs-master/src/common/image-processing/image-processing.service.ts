import { Injectable, InternalServerErrorException } from '@nestjs/common';
import sharp from 'sharp';
import { StorageService } from '../storage/storage.service';
import 'multer';

export interface ProcessedImage {
  original: string;
  thumbnail: string;
  mobile: string;
}

@Injectable()
export class ImageProcessingService {
  constructor(private readonly storageService: StorageService) {}

  /**
   * Processes an image: converts to WebP, creates thumbnail and mobile versions, and uploads them.
   * @param file The original uploaded file
   * @param basePath The base path for storage (e.g. 'products/123')
   * @returns Object containing paths to original (optimized), thumbnail, and mobile versions
   */
  async processAndUpload(
    file: Express.Multer.File,
    basePath: string,
  ): Promise<ProcessedImage> {
    try {
      const uniqueId = Date.now();
      const originalName = file.originalname.split('.')[0];
      const filename = `${uniqueId}_${originalName}`;

      // 1. Optimize Original (Convert to WebP, quality 80)
      const originalBuffer = await sharp(file.buffer)
        .webp({ quality: 80 })
        .toBuffer();

      const originalPath = `${basePath}/${filename}.webp`;
      await this.storageService.upload(
        { ...file, buffer: originalBuffer, mimetype: 'image/webp' },
        originalPath,
      );

      // 2. Create Mobile Version (Resize to width 800px)
      const mobileBuffer = await sharp(file.buffer)
        .resize({ width: 800, withoutEnlargement: true })
        .webp({ quality: 75 })
        .toBuffer();

      const mobilePath = `${basePath}/${filename}_mobile.webp`;
      await this.storageService.upload(
        { ...file, buffer: mobileBuffer, mimetype: 'image/webp' },
        mobilePath,
      );

      // 3. Create Thumbnail (Resize to width 200px)
      const thumbnailBuffer = await sharp(file.buffer)
        .resize({ width: 200, height: 200, fit: 'cover' })
        .webp({ quality: 70 })
        .toBuffer();

      const thumbnailPath = `${basePath}/${filename}_thumb.webp`;
      await this.storageService.upload(
        { ...file, buffer: thumbnailBuffer, mimetype: 'image/webp' },
        thumbnailPath,
      );

      return {
        original: originalPath,
        mobile: mobilePath,
        thumbnail: thumbnailPath,
      };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      throw new InternalServerErrorException(
        `Failed to process image: ${errorMessage}`,
      );
    }
  }

  /**
   * Deletes all versions of an image
   * @param imagePaths Object containing paths to delete
   */
  async deleteImages(imagePaths: Partial<ProcessedImage>): Promise<void> {
    const tasks = Object.values(imagePaths).map((path) =>
      path ? this.storageService.delete(path) : Promise.resolve(),
    );
    await Promise.all(tasks);
  }
}

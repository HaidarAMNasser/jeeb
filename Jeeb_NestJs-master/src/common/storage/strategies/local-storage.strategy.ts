import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { StorageStrategy } from '../interfaces/storage-strategy.interface';
import * as fs from 'fs';
import * as path from 'path';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class LocalStorageStrategy implements StorageStrategy {
  private readonly uploadDir = 'uploads';

  constructor(private readonly configService: ConfigService) {
    // Ensure upload directory exists
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  async upload(
    file: Express.Multer.File,
    destinationPath: string,
  ): Promise<string> {
    try {
      const fullPath = path.join(this.uploadDir, destinationPath);
      const directory = path.dirname(fullPath);

      if (!fs.existsSync(directory)) {
        await fs.promises.mkdir(directory, { recursive: true });
      }

      await fs.promises.writeFile(fullPath, file.buffer);
      return destinationPath;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error';
      throw new InternalServerErrorException(
        `Failed to upload file: ${errorMessage}`,
      );
    }
  }

  async delete(destinationPath: string): Promise<void> {
    try {
      const fullPath = path.join(this.uploadDir, destinationPath);
      if (fs.existsSync(fullPath)) {
        await fs.promises.unlink(fullPath);
      }
    } catch (error) {}
  }

  getUrl(destinationPath: string): string {
    const imageBaseUrl = this.configService.get<string>('IMAGE_BASE_URL');
    if (imageBaseUrl) {
      const normalizedPath = destinationPath.split(path.sep).join('/');
      return `${imageBaseUrl}/${normalizedPath}`;
    }
    // Fallback to APP_URL
    const baseUrl =
      this.configService.get<string>('APP_URL') || 'http://localhost:3000';
    const normalizedPath = destinationPath.split(path.sep).join('/');
    return `${baseUrl}/${this.uploadDir}/${normalizedPath}`;
  }
}

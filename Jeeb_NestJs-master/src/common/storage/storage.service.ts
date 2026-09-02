import { Injectable, Inject } from '@nestjs/common';
import type { StorageStrategy } from './interfaces/storage-strategy.interface';

@Injectable()
export class StorageService {
  constructor(
    @Inject('StorageStrategy') private readonly strategy: StorageStrategy,
  ) {}

  async upload(file: Express.Multer.File, path: string): Promise<string> {
    return this.strategy.upload(file, path);
  }

  async delete(path: string): Promise<void> {
    return this.strategy.delete(path);
  }

  resolveUrl(path: string | null): string | null {
    if (!path) return null;
    // If it's already a full URL (external), return as is
    if (path.startsWith('http')) return path;
    return this.strategy.getUrl(path);
  }
}

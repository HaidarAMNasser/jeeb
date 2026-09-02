import { Module, Global } from '@nestjs/common';
import { StorageService } from './storage.service';
import { LocalStorageStrategy } from './strategies/local-storage.strategy';
import { ConfigModule } from '@nestjs/config';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [
    StorageService,
    {
      provide: 'StorageStrategy',
      useClass: LocalStorageStrategy, // Can be switched to CloudinaryStrategy later based on env
    },
  ],
  exports: [StorageService],
})
export class StorageModule {}

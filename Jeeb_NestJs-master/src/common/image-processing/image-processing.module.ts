import { Module, Global } from '@nestjs/common';
import { ImageProcessingService } from './image-processing.service';
import { StorageModule } from '../storage/storage.module';

@Global()
@Module({
  imports: [StorageModule],
  providers: [ImageProcessingService],
  exports: [ImageProcessingService],
})
export class ImageProcessingModule {}

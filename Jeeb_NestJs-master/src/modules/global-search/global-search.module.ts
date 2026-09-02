import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { GlobalSearchController } from './global-search.controller';
import { GlobalSearchService } from './global-search.service';
import { User } from '../../database/entities/user.entity';
import { Product } from '../../database/entities/product.entity';
import { Offer } from '../../database/entities/offer.entity';
import { Image } from '../../database/entities/image.entity';
import { SearchService } from '../../common/search';
import { StorageService } from '../../common/storage/storage.service';

@Module({
  imports: [TypeOrmModule.forFeature([User, Product, Offer, Image])],
  controllers: [GlobalSearchController],
  providers: [GlobalSearchService, SearchService],
})
export class GlobalSearchModule {}

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Product } from '../../database/entities/product.entity';
import { Image } from '../../database/entities/image.entity';
import { Review } from '../../database/entities/review.entity';
import { OrderItem } from '../../database/entities/order-item.entity';
import { Order } from '../../database/entities/order.entity';
import { Favorite } from '../../database/entities/favorite.entity';
import { Cart } from '../../database/entities/cart.entity';
import { CartItem } from '../../database/entities/cart-item.entity';
import { User } from '../../database/entities/user.entity';
import { ProductsService } from './products.service';
import { ProductsController } from './products.controller';
import { CategoriesModule } from '../categories/categories.module';
import { AuthModule } from '../auth/auth.module';
import { DistanceModule } from '../distance/distance.module';

// New specialized services
import { ProductImagesService } from './services/product-images.service';
import { ProductQueryService } from './services/product-query.service';
import { ProductPricingService } from './services/product-pricing.service';
import { ProductEnrichmentService } from './services/product-enrichment.service';
import { ProductResponseMapper } from './mappers/product-response.mapper';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Product,
      Image,
      Review,
      OrderItem,
      Order,
      Favorite,
      Cart,
      CartItem,
      User,
    ]),
    CategoriesModule,
    AuthModule,
    DistanceModule,
  ],
  controllers: [ProductsController],
  providers: [
    ProductsService,
    ProductImagesService,
    ProductQueryService,
    ProductPricingService,
    ProductEnrichmentService,
    ProductResponseMapper,
  ],
  exports: [
    ProductsService,
    ProductImagesService,
    ProductQueryService,
    ProductPricingService,
    ProductEnrichmentService,
  ],
})
export class ProductsModule {}

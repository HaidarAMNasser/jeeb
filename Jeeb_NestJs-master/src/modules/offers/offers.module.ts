import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Offer } from '../../database/entities/offer.entity';
import { Product } from '../../database/entities/product.entity';
import { Image } from '../../database/entities/image.entity';
import { OfferProduct } from '../../database/entities/offer-product.entity';
import { OffersService } from './offers.service';
import { OffersController } from './offers.controller';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Offer, Product, Image, OfferProduct]),
    AuthModule,
  ],
  controllers: [OffersController],
  providers: [OffersService],
  exports: [OffersService],
})
export class OffersModule {}

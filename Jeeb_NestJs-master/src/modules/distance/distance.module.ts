import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SettingsModule } from '../settings/settings.module';
import { DistanceService } from './distance.service';
import { DistanceController } from './distance.controller';
import { HaversineDistanceStrategy } from './strategies/haversine-distance.strategy';
import { GoogleMapsDistanceStrategy } from './strategies/google-maps-distance.strategy';
import { GoogleDirectionsService } from './google-directions.service';
import { User } from '../../database/entities/user.entity';
import { Product } from '../../database/entities/product.entity';
import { Image } from '../../database/entities/image.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, Product, Image])],
  controllers: [DistanceController],
  providers: [
    DistanceService,
    HaversineDistanceStrategy,
    GoogleMapsDistanceStrategy,
    GoogleDirectionsService,
  ],
  exports: [
    DistanceService,
    GoogleDirectionsService,
    HaversineDistanceStrategy,
  ],
})
export class DistanceModule {}

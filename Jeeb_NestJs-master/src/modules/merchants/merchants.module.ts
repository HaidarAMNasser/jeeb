import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Merchant } from '../../database/entities/merchant.entity';
import { User } from '../../database/entities/user.entity';
import { Image } from '../../database/entities/image.entity';
import { MerchantsService } from './merchants.service';
import { MerchantsController } from './merchants.controller';
import { GoogleDirectionsService } from '../distance/google-directions.service';
import { DistanceModule } from '../distance/distance.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Merchant, User, Image]),
    forwardRef(() => DistanceModule),
  ],
  controllers: [MerchantsController],
  providers: [MerchantsService, GoogleDirectionsService],
  exports: [MerchantsService, TypeOrmModule],
})
export class MerchantsModule {}

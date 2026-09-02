import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../../database/entities/user.entity';
import { City } from '../../database/entities/city.entity';
import { Country } from '../../database/entities/country.entity';
import { LocationService } from './location.service';
import { LocationController } from './location.controller';
import { FirebaseLocationStrategy } from './strategies/firebase-location.strategy';

@Module({
  imports: [TypeOrmModule.forFeature([User, City, Country])],
  controllers: [LocationController],
  providers: [
    LocationService,
    {
      provide: 'LocationTracker', // This token allows us to swap implementations (Strategy Pattern)
      useClass: FirebaseLocationStrategy, // Current implementation: Firebase
      // Future implementation: WebSocketLocationStrategy
    },
  ],
  exports: [LocationService],
})
export class LocationModule {}

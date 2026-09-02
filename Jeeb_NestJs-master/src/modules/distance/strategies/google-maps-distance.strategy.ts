import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  DistanceStrategy,
  Coordinate,
} from '../interfaces/distance-strategy.interface';

@Injectable()
export class GoogleMapsDistanceStrategy implements DistanceStrategy {
  private readonly logger = new Logger(GoogleMapsDistanceStrategy.name);
  private readonly apiKey: string;

  constructor(private configService: ConfigService) {
    this.apiKey = this.configService.get<string>('GOOGLE_MAPS_API_KEY') || '';
  }

  async calculateDistance(from: Coordinate, to: Coordinate): Promise<number> {
    if (!this.apiKey) {
      this.logger.warn(
        'Google Maps API key not configured. Falling back to Haversine.',
      );
      throw new Error('Google Maps API key not configured');
    }

    try {
      const url = `https://maps.googleapis.com/maps/api/distancematrix/json?origins=${from.lat},${from.lng}&destinations=${to.lat},${to.lng}&key=${this.apiKey}`;

      const response = await fetch(url);
      const data = await response.json();

      if (data.status === 'OK' && data.rows[0]?.elements[0]?.status === 'OK') {
        const distanceInMeters = data.rows[0].elements[0].distance.value;
        return distanceInMeters;
      }

      throw new Error(`Google Maps API error: ${data.status}`);
    } catch (error) {
      this.logger.error('Failed to calculate distance with Google Maps', error);
      throw error;
    }
  }

  getMethodName(): string {
    return 'GOOGLE_MAPS';
  }
}

import { Injectable } from '@nestjs/common';
import {
  DistanceStrategy,
  Coordinate,
} from '../interfaces/distance-strategy.interface';

@Injectable()
export class HaversineDistanceStrategy implements DistanceStrategy {
  private readonly EARTH_RADIUS_KM = 6371;
  private readonly EARTH_RADIUS_M = 6371 * 1000;

  calculateDistance(from: Coordinate, to: Coordinate): number {
    const fromLat = this.toRadians(from.lat);
    const fromLng = this.toRadians(from.lng);
    const toLat = this.toRadians(to.lat);
    const toLng = this.toRadians(to.lng);

    const dLat = toLat - fromLat;
    const dLng = toLng - fromLng;

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(fromLat) *
        Math.cos(toLat) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    const distanceInMeters = this.EARTH_RADIUS_M * c;

    return Math.round(distanceInMeters);
  }

  getMethodName(): string {
    return 'HAVERSINE';
  }

  private toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
  }
}

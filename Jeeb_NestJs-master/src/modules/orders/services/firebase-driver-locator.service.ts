import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ErrorCodes } from '../../../common/constants/error-codes';
import { DistanceService } from '../../distance/distance.service';

type DriverLocation = {
  id: number;
  lat: number;
  lon: number;
  status: 'AVAILABLE' | 'BUSY' | 'OFFLINE';
};

@Injectable()
export class FirebaseDriverLocatorService {
  private readonly logger = new Logger(FirebaseDriverLocatorService.name);

  private mode: 'MOCK' | 'FIREBASE';

  private static readonly MOCK_DRIVERS: DriverLocation[] = [
    { id: 101, lat: 37.7749, lon: -122.4194, status: 'AVAILABLE' },
    { id: 102, lat: 37.775, lon: -122.4183, status: 'AVAILABLE' },
    { id: 103, lat: 37.779, lon: -122.42, status: 'BUSY' },
    { id: 104, lat: 37.78, lon: -122.43, status: 'AVAILABLE' },
    { id: 105, lat: 37.77, lon: -122.41, status: 'AVAILABLE' },
  ];

  constructor(private readonly distanceService: DistanceService) {
    const mode = process.env.DRIVER_LOCATOR_MODE || 'MOCK';
    this.mode = mode as 'MOCK' | 'FIREBASE';

    if (this.mode === 'MOCK') {
      this.logger.warn(
        `${ErrorCodes.DRIVER_LOCATOR_MOCK_MODE.message}. Set DRIVER_LOCATOR_MODE=FIREBASE for production.`,
      );
    }
  }

  /**
   * Find nearest available delivery drivers
   */
  async getNearestDrivers(
    count: number,
    reference?: { lat: number; lon: number },
  ): Promise<number[]> {
    if (this.mode === 'MOCK') {
      this.logger.debug(
        `Getting ${count} nearest drivers from mock data${reference ? ` near (${reference.lat}, ${reference.lon})` : ''}`,
      );

      const available = FirebaseDriverLocatorService.MOCK_DRIVERS.filter(
        (d) => d.status === 'AVAILABLE',
      );

      if (!reference) {
        return available.slice(0, Math.max(0, count)).map((d) => d.id);
      }

      if (reference.lat == null || reference.lon == null) {
        throw new BadRequestException(
          ErrorCodes.DRIVER_LOCATOR_INVALID_COORDINATES.message,
        );
      }

      const sorted = available
        .map((d) => ({
          id: d.id,
          dist: this.distanceService.calculateDistance(
            { lat: reference.lat, lng: reference.lon },
            { lat: d.lat, lng: d.lon },
          ),
        }))
        .sort((a, b) => a.dist - b.dist)
        .slice(0, Math.max(0, count))
        .map((x) => x.id);

      return sorted;
    }

    // Firebase real-time mode - placeholder
    this.logger.warn(
      ErrorCodes.DRIVER_LOCATOR_FIREBASE_ERROR.message +
        ' - Firebase integration not implemented yet',
    );
    return [];
  }

  /**
   * Get current mode (MOCK or FIREBASE)
   */
  getMode(): string {
    return this.mode;
  }

  /**
   * Check if running in mock mode
   */
  isMockMode(): boolean {
    return this.mode === 'MOCK';
  }
}

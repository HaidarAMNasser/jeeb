import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { HaversineDistanceStrategy } from './strategies/haversine-distance.strategy';
import { Coordinate } from './interfaces/distance-strategy.interface';

export interface DirectionsResult {
  distanceMeters: number;
  distanceKm: number;
  durationSeconds: number;
  durationInTrafficSeconds: number | null;
  source: 'GOOGLE_DIRECTIONS' | 'HAVERSINE_FALLBACK';
}

interface GoogleDirectionsResponse {
  routes: Array<{
    legs: Array<{
      distance: { value: number; text: string };
      duration: { value: number; text: string };
      duration_in_traffic?: { value: number; text: string };
    }>;
  }>;
  status: string;
  error_message?: string;
}

@Injectable()
export class GoogleDirectionsService {
  private readonly logger = new Logger(GoogleDirectionsService.name);
  private readonly apiKey: string;
  private readonly isAvailable: boolean;

  constructor(
    private readonly configService: ConfigService,
    private readonly haversineStrategy: HaversineDistanceStrategy,
  ) {
    this.apiKey =
      this.configService.get<string>('GOOGLE_DIRECTIONS_API_KEY') || '';
    this.isAvailable = !!this.apiKey;

    if (!this.isAvailable) {
      this.logger.warn(
        'GOOGLE_DIRECTIONS_API_KEY not configured. Will use Haversine fallback only.',
      );
    } else {
      this.logger.log('Google Directions API initialized successfully.');
    }
  }

  /**
   * Get route details between two points using Google Directions API.
   * Falls back to Haversine if API is unavailable or fails.
   */
  async getRouteDetails(
    origin: Coordinate,
    destination: Coordinate,
  ): Promise<DirectionsResult> {
    // [COMMENTED] Google Directions API integration
    // To re-enable, uncomment the block below and set GOOGLE_DIRECTIONS_API_KEY in .env
    /*
    if (!this.isAvailable) {
      return this.buildHaversineFallback(origin, destination);
    }

    try {
      const url =
        `https://maps.googleapis.com/maps/api/directions/json` +
        `?origin=${origin.lat},${origin.lng}` +
        `&destination=${destination.lat},${destination.lng}` +
        `&departure_time=now` +
        `&traffic_model=best_guess` +
        `&key=${this.apiKey}`;

      const response = await fetch(url);
      const data: GoogleDirectionsResponse = await response.json();

      if (data.status !== 'OK' || !data.routes?.length) {
        this.logger.warn(
          `Google Directions API returned status: ${data.status}. ${data.error_message || ''}. Falling back to Haversine.`,
        );
        return this.buildHaversineFallback(origin, destination);
      }

      const leg = data.routes[0].legs[0];

      return {
        distanceMeters: leg.distance.value,
        distanceKm: Math.round((leg.distance.value / 1000) * 100) / 100,
        durationSeconds: leg.duration.value,
        durationInTrafficSeconds: leg.duration_in_traffic?.value ?? null,
        source: 'GOOGLE_DIRECTIONS',
      };
    } catch (error) {
      this.logger.error(
        'Google Directions API request failed. Falling back to Haversine.',
        error instanceof Error ? error.message : error,
      );
      return this.buildHaversineFallback(origin, destination);
    }
    */

    return this.buildHaversineFallback(origin, destination);
  }

  /**
   * Get route details for multiple destinations from a single origin.
   * Calls Google Directions API for each destination individually.
   * Falls back to Haversine per-destination if any call fails.
   */
  async getMultipleRoutes(
    origin: Coordinate,
    destinations: Array<{ id: number; coordinate: Coordinate }>,
  ): Promise<Map<number, DirectionsResult>> {
    const results = new Map<number, DirectionsResult>();

    // Process in parallel but with a concurrency limit to avoid rate limiting
    const CONCURRENCY_LIMIT = 5;
    const chunks: Array<{ id: number; coordinate: Coordinate }[]> = [];

    for (let i = 0; i < destinations.length; i += CONCURRENCY_LIMIT) {
      chunks.push(destinations.slice(i, i + CONCURRENCY_LIMIT));
    }

    for (const chunk of chunks) {
      const promises = chunk.map(async (dest) => {
        const result = await this.getRouteDetails(origin, dest.coordinate);
        results.set(dest.id, result);
      });
      await Promise.all(promises);
    }

    return results;
  }

  /**
   * Build a Haversine fallback result when Google Directions is unavailable.
   * Estimates duration based on an average urban driving speed of 30 km/h.
   */
  private buildHaversineFallback(
    origin: Coordinate,
    destination: Coordinate,
  ): DirectionsResult {
    const distanceMeters = this.haversineStrategy.calculateDistance(
      origin,
      destination,
    );
    const distanceKm = distanceMeters / 1000;

    // Estimate: 30 km/h average urban speed
    const estimatedDurationSeconds = Math.round((distanceKm / 30) * 3600);

    return {
      distanceMeters,
      distanceKm: Math.round(distanceKm * 100) / 100,
      durationSeconds: estimatedDurationSeconds,
      durationInTrafficSeconds: null,
      source: 'HAVERSINE_FALLBACK',
    };
  }

  /**
   * Check if Google Directions API is available
   */
  isApiAvailable(): boolean {
    return this.isAvailable;
  }
}

import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { DeliveryStatus } from '../../../common/enums/delivery-status.enum';
import { SettingsService } from '../../settings/settings.service';
import {
  GoogleDirectionsService,
  DirectionsResult,
} from '../../distance/google-directions.service';
import {
  DriverLocation,
  DriverScoreResult,
} from '../interfaces/delivery-assignment.interfaces';
import { Coordinate } from '../../distance/interfaces/distance-strategy.interface';

export interface ScoringWeights {
  distance: number;
  eta: number;
  acceptance: number;
}

const DEFAULT_WEIGHTS: ScoringWeights = {
  distance: 0.4,
  eta: 0.4,
  acceptance: 0.2,
};

@Injectable()
export class DriverScoringService {
  private readonly logger = new Logger(DriverScoringService.name);
  private weights: ScoringWeights = DEFAULT_WEIGHTS;

  constructor(
    @InjectRepository(DeliveryAssignment)
    private readonly assignmentRepo: Repository<DeliveryAssignment>,
    private readonly settingsService: SettingsService,
    private readonly googleDirectionsService: GoogleDirectionsService,
  ) {
    this.loadWeights();
  }

  private async loadWeights(): Promise<void> {
    try {
      const setting = await this.settingsService.getSettingByKey(
        'driverScoringWeights',
      );
      if (setting?.value) {
        const parsed =
          typeof setting.value === 'string'
            ? JSON.parse(setting.value)
            : setting.value;
        if (parsed.distance && parsed.eta && parsed.acceptance) {
          this.weights = parsed;
          this.logger.log(
            `Scoring weights loaded: distance=${this.weights.distance}, eta=${this.weights.eta}, acceptance=${this.weights.acceptance}`,
          );
        }
      }
    } catch {
      this.logger.debug(
        'Using default scoring weights (setting not found or invalid)',
      );
    }
  }

  /**
   * Score and rank drivers using multiple criteria:
   * - Real route distance (Google Directions) or Haversine fallback
   * - ETA (duration_in_traffic or estimated)
   * - Historical acceptance rate
   */
  async scoreDrivers(
    merchantLocation: Coordinate,
    drivers: DriverLocation[],
    haversineDistances: Map<number, number>,
  ): Promise<DriverScoreResult[]> {
    if (drivers.length === 0) return [];

    // 1. Get route details from Google Directions for these drivers
    const destinations = drivers.map((d) => ({
      id: d.id,
      coordinate: { lat: d.currentLat, lng: d.currentLng },
    }));

    const routeResults = await this.googleDirectionsService.getMultipleRoutes(
      merchantLocation,
      destinations,
    );

    // 2. Calculate acceptance rates for all drivers
    const acceptanceRates = await this.getAcceptanceRates(
      drivers.map((d) => d.id),
    );

    // 3. Normalize and score each driver
    const rawScores = drivers.map((driver) => {
      const route = routeResults.get(driver.id);
      const haversineDistance = haversineDistances.get(driver.id) ?? Infinity;
      const acceptanceRate = acceptanceRates.get(driver.id) ?? 0.5; // default 50% for new drivers

      // Use real distance if available, otherwise haversine
      const realDistanceMeters = route?.distanceMeters ?? haversineDistance;
      const etaSeconds =
        route?.durationInTrafficSeconds ?? route?.durationSeconds ?? Infinity;

      return {
        driver,
        realDistanceMeters,
        realDistanceKm: Math.round((realDistanceMeters / 1000) * 100) / 100,
        haversineDistanceMeters: haversineDistance,
        etaSeconds,
        etaMinutes: Math.round(etaSeconds / 60),
        acceptanceRate,
        routeSource: route?.source ?? 'HAVERSINE_FALLBACK',
      };
    });

    // 4. Find max values for normalization (avoid division by zero)
    const maxDistance = Math.max(
      ...rawScores.map((s) => s.realDistanceMeters),
      1,
    );
    const maxEta = Math.max(...rawScores.map((s) => s.etaSeconds), 1);

    // 5. Calculate final scores (lower is better)
    const scoredDrivers: DriverScoreResult[] = rawScores.map((raw) => {
      // Normalized scores: 0 = best, 1 = worst
      const normalizedDistance = raw.realDistanceMeters / maxDistance;
      const normalizedEta = raw.etaSeconds / maxEta;
      // Invert acceptance: higher rate = lower (better) score
      const normalizedAcceptance = 1 - raw.acceptanceRate;

      const finalScore =
        this.weights.distance * normalizedDistance +
        this.weights.eta * normalizedEta +
        this.weights.acceptance * normalizedAcceptance;

      return {
        driver: raw.driver,
        finalScore: Math.round(finalScore * 1000) / 1000,
        breakdown: {
          distanceScore: Math.round(normalizedDistance * 1000) / 1000,
          etaScore: Math.round(normalizedEta * 1000) / 1000,
          acceptanceScore: Math.round(normalizedAcceptance * 1000) / 1000,
          weights: this.weights,
        },
        routeDetails: {
          realDistanceKm: raw.realDistanceKm,
          haversineDistanceMeters: raw.haversineDistanceMeters,
          etaMinutes: raw.etaMinutes,
          routeSource: raw.routeSource,
        },
        acceptanceRate: raw.acceptanceRate,
      };
    });

    // 6. Sort by score (ascending — lower is better)
    scoredDrivers.sort((a, b) => a.finalScore - b.finalScore);

    this.logger.debug(
      `Scored ${scoredDrivers.length} drivers. Top: ${scoredDrivers[0]?.driver.firstName} (score: ${scoredDrivers[0]?.finalScore})`,
    );

    return scoredDrivers;
  }

  /**
   * Calculate acceptance rates for a list of drivers
   * based on their delivery_assignments history.
   *
   * Rate = ACCEPTED / (ACCEPTED + EXPIRED + REJECTED)
   * New drivers with no history get 0.5 (neutral)
   */
  async getAcceptanceRates(driverIds: number[]): Promise<Map<number, number>> {
    const rates = new Map<number, number>();

    if (driverIds.length === 0) return rates;

    try {
      // Get aggregated stats for all drivers in one query
      const stats = await this.assignmentRepo
        .createQueryBuilder('a')
        .select('a.deliveryId', 'deliveryId')
        .addSelect(
          `SUM(CASE WHEN a.status = '${DeliveryStatus.ACCEPTED}' THEN 1 ELSE 0 END)`,
          'accepted',
        )
        .addSelect(
          `SUM(CASE WHEN a.status IN ('${DeliveryStatus.EXPIRED}', '${DeliveryStatus.REJECTED}') THEN 1 ELSE 0 END)`,
          'declined',
        )
        .addSelect('COUNT(*)', 'total')
        .where('a.deliveryId IN (:...driverIds)', { driverIds })
        .groupBy('a.deliveryId')
        .getRawMany();

      for (const stat of stats) {
        const accepted = Number(stat.accepted) || 0;
        const declined = Number(stat.declined) || 0;
        const relevant = accepted + declined;

        if (relevant === 0) {
          rates.set(Number(stat.deliveryId), 0.5); // no relevant history
        } else {
          rates.set(
            Number(stat.deliveryId),
            Math.round((accepted / relevant) * 100) / 100,
          );
        }
      }

      // Set default for drivers with no assignments at all
      for (const id of driverIds) {
        if (!rates.has(id)) {
          rates.set(id, 0.5);
        }
      }
    } catch (error) {
      this.logger.error(
        'Failed to calculate acceptance rates, using defaults',
        error instanceof Error ? error.message : error,
      );
      for (const id of driverIds) {
        rates.set(id, 0.5);
      }
    }

    return rates;
  }
}

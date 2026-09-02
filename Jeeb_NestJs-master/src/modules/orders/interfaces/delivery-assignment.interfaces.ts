import { NotificationChannel } from '../../../common/enums/notification-channel.enum';
import { DeliveryAssignment } from '../../../database/entities/delivery-assignment.entity';
import { ScoringWeights } from '../services/driver-scoring.service';

export interface DriverLocation {
  id: number;
  firstName: string;
  lastName: string;
  phone: string;
  email: string | null;
  currentLat: number;
  currentLng: number;
  notificationChannel: NotificationChannel;
  fcmToken?: string;
}

export interface DeliveryNotificationData {
  orderId: number;
  driverIds: number[];
  attempt: number;
}

export interface DriverDistance {
  driver: DriverLocation;
  distance: number;
}

export interface DeliveryAssignmentResult {
  assignment: DeliveryAssignment;
  message: string;
}

export interface NotificationPayload {
  userId: number;
  recipient: string;
  channel: NotificationChannel;
  type: string;
  content: string;
  status: string;
  orderId?: number;
}

export interface QueueJobData {
  orderId: number;
  attempt: number;
  driverIds?: number[];
  currentRadius?: number;
}

// ──── Smart Search Interfaces ────

export interface SmartSearchConfig {
  initialSearchRadius: number; // km (default: 5)
  searchRadiusIncrement: number; // km (default: 2)
  maxSearchRadius: number; // km (default: 20)
  batchSize: number; // drivers per batch (default: 3)
  timeoutSeconds: number; // seconds to wait (default: 180)
}

export interface DriverScoreResult {
  driver: DriverLocation;
  finalScore: number;
  breakdown: {
    distanceScore: number;
    etaScore: number;
    acceptanceScore: number;
    weights: ScoringWeights;
  };
  routeDetails: {
    realDistanceKm: number;
    haversineDistanceMeters: number;
    etaMinutes: number;
    routeSource: string;
  };
  acceptanceRate: number;
}

export interface RouteDetails {
  distanceMeters: number;
  distanceKm: number;
  durationSeconds: number;
  durationInTrafficSeconds: number | null;
  source: 'GOOGLE_DIRECTIONS' | 'HAVERSINE_FALLBACK';
}

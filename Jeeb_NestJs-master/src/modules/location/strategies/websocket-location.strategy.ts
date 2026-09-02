import { Injectable, Logger } from '@nestjs/common';
import { LocationTracker } from '../interfaces/location-tracker.interface';

/**
 * Future implementation for WebSocket-based real-time location tracking.
 * To use this, simply change the provider in LocationModule:
 * { provide: 'LocationTracker', useClass: WebSocketLocationStrategy }
 */
@Injectable()
export class WebSocketLocationStrategy implements LocationTracker {
  private readonly logger = new Logger(WebSocketLocationStrategy.name);

  // In a real implementation, you would inject a WebSocketGateway here
  // constructor(private readonly gateway: LocationGateway) {}

  async updateLocation(
    driverId: number,
    lat: number,
    lng: number,
  ): Promise<void> {
    this.logger.log(
      `[WebSocket] Broadcasting location for driver ${driverId}: ${lat}, ${lng}`,
    );
    // await this.gateway.server.emit('locationUpdate', { driverId, lat, lng });
    return Promise.resolve();
  }

  async getDriverLocation(
    driverId: number,
  ): Promise<{ lat: number; lng: number } | null> {
    this.logger.warn(
      `[WebSocket] Cannot pull location for driver ${driverId} from WebSocket clients easily. Returning null or cached value.`,
    );
    // WebSockets are push-based. Usually we'd rely on the last pushed value cached in Redis/Memory.
    return Promise.resolve(null);
  }
}

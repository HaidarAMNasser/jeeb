import { DriverPresenceData } from './driver-presence.interface';

export interface IDriverPresenceProvider {
  getTrulyOnlineDrivers(): DriverPresenceData[];
  isDriverOnline(driverId: number): boolean;
}

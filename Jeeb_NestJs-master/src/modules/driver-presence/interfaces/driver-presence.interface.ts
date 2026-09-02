export interface DriverPresenceData {
  id: number;
  currentLat?: number;
  currentLng?: number;
  isOnline: boolean;
  lastSeen: number;
}

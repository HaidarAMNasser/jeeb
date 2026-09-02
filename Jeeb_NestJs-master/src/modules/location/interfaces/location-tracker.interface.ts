export interface LocationTracker {
  /**
   * Updates the real-time location of a driver.
   * @param driverId The ID of the driver.
   * @param lat Latitude.
   * @param lng Longitude.
   */
  updateLocation(driverId: number, lat: number, lng: number): Promise<void>;

  /**
   * Retrieves the current location of a driver.
   * @param driverId The ID of the driver.
   */
  getDriverLocation(
    driverId: number,
  ): Promise<{ lat: number; lng: number } | null>;
}

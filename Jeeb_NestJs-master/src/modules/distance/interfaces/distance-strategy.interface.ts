export interface Coordinate {
  lat: number;
  lng: number;
}

export interface DistanceStrategy {
  calculateDistance(from: Coordinate, to: Coordinate): number | Promise<number>;
  getMethodName(): string;
}

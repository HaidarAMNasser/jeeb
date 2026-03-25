/// In-memory coordinates for checkout until the app process is killed.
class BasketOrderLocationSession {
  BasketOrderLocationSession._();

  static double? latitude;
  static double? longitude;

  static bool get hasCoordinates => latitude != null && longitude != null;

  static void save(double lat, double lng) {
    latitude = lat;
    longitude = lng;
  }
}

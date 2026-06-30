import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Default map center when device coordinates are unavailable.
/// Ar-Raqqah (الرقة), Syria.
abstract final class MapDefaults {
  MapDefaults._();

  static const double latitude = 35.9594;
  static const double longitude = 39.0099;

  static const LatLng center = LatLng(latitude, longitude);
}

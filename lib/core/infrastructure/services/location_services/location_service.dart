import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_permission_helper.dart';

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  StreamSubscription<Position>? _positionStreamSubscription;

  /// Returns a stream of position updates.
  /// Automatically handles permission checking.
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) async* {
    final hasPermission = await LocationPermissionHelper.isLocationPermissionGranted();
    if (!hasPermission) {
      final granted = await LocationPermissionHelper.requestLocationPermission();
      if (!granted) {
        // Don't throw from a stream: callers won't catch it with try/catch around
        // `.listen()`. Instead, return an empty stream so screens can still load.
        return;
      }
    }

    yield* Geolocator.getPositionStream(
      locationSettings: locationSettings ??
          const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
    );
  }

  /// Gets the current position once.
  Future<Position?> getCurrentPosition() async {
    return await LocationPermissionHelper.getCurrentPosition();
  }

  /// Starts tracking location and calls [onLocationUpdate].
  Future<void> startTracking(Function(Position) onLocationUpdate) async {
    await stopTracking();
    _positionStreamSubscription = getPositionStream().listen(onLocationUpdate);
  }

  /// Stops the location tracking.
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}

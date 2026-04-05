import 'package:geolocator/geolocator.dart';

/// Permission and position helpers for map picker, registration, delivery, basket flows.
class LocationPermissionHelper {
  LocationPermissionHelper._();

  /// Request location permission (when in use).
  /// Re-asks for permission when denied; opens app settings when permanently denied.
  /// Returns true if granted, false otherwise.
  static Future<bool> requestLocationPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return true;
      }

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return true;
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if location permission is granted.
  static Future<bool> isLocationPermissionGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Get current position. Requires location permission.
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final hasPermission = await isLocationPermissionGranted();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// No permission dialog. Last known or current fix if already permitted and services on.
  static Future<Position?> trySilentPosition() async {
    try {
      if (!await isLocationPermissionGranted()) return null;
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Retries last-known and current position with backoff (cold GPS, first fix).
  /// Call when location permission is already granted (e.g. after [requestLocationPermission]).
  static Future<Position?> getCurrentPositionWithRetries() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    Position? position;
    for (var attempt = 0; attempt < 6; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: 350 + attempt * 250),
        );
      }

      position = await _tryCurrentPosition(accuracy: LocationAccuracy.low);
      if (position != null) break;

      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
      if (position != null) break;

      position = await _tryCurrentPosition(accuracy: LocationAccuracy.medium);
      if (position != null) break;
    }

    return position;
  }

  /// Result of requesting location: position may be null even when permission
  /// was granted (e.g. GPS off or first fix not yet available).
  static Future<({double? latitude, double? longitude, bool permissionGranted})>
      requestAndGetPosition() async {
    final granted = await requestLocationPermission();
    if (!granted) {
      return (latitude: null, longitude: null, permissionGranted: false);
    }

    final position = await getCurrentPositionWithRetries();

    if (position == null) {
      return (latitude: null, longitude: null, permissionGranted: true);
    }
    return (
      latitude: position.latitude,
      longitude: position.longitude,
      permissionGranted: true,
    );
  }

  static Future<Position?> _tryCurrentPosition({
    required LocationAccuracy accuracy,
  }) async {
    try {
      if (!await isLocationPermissionGranted()) return null;
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: accuracy),
      );
    } catch (_) {
      return null;
    }
  }
}

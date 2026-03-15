import 'package:geolocator/geolocator.dart';

/// Helper for location permission and fetching current position.
/// Used when merchant chooses "Use my location" during registration.
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

      // Re-ask for permission (works for denied; for deniedForever the system
      // may show "open settings" or we open settings below)
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
  /// Returns null on failure (permission denied, service disabled, or error).
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

  /// Result of requesting location: position may be null even when permission
  /// was granted (e.g. GPS off or first fix not yet available).
  static Future<({double? latitude, double? longitude, bool permissionGranted})>
      requestAndGetPosition() async {
    final granted = await requestLocationPermission();
    if (!granted) {
      return (latitude: null, longitude: null, permissionGranted: false);
    }

    // Give the system a moment to apply permission (fixes "still denied" on some devices)
    await Future<void>.delayed(const Duration(milliseconds: 400));

    Position? position = await getCurrentPosition();
    if (position == null) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }
    if (position == null) {
      return (latitude: null, longitude: null, permissionGranted: true);
    }
    return (
      latitude: position.latitude,
      longitude: position.longitude,
      permissionGranted: true,
    );
  }
}

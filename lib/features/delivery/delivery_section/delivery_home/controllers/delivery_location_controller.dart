import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_permission_helper.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_service.dart';

/// Owns the delivery home map's live GPS stream and exposes current coordinates.
class DeliveryLocationController extends ChangeNotifier {
  double? _currentLat;
  double? _currentLng;
  StreamSubscription<Position>? _locationSubscription;

  double? get currentLat => _currentLat;
  double? get currentLng => _currentLng;

  /// Home map stream; also forwarded to [DeliveryOrderLocationReporter] when tracking.
  void Function(Position position)? onPositionUpdate;

  /// Requests permission if needed, resolves a fix immediately (last known → current), then
  /// subscribes to live updates so the map pins the user without waiting on the stream alone.
  Future<void> start() async {
    try {
      await _primeImmediateLocation();
      _locationSubscription = LocationService.instance
          .getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            ),
          )
          .listen(
            _emitPosition,
            onError: (_) {},
          );
    } catch (_) {}
  }

  void _emitPosition(Position position) {
    _currentLat = position.latitude;
    _currentLng = position.longitude;
    notifyListeners();
    onPositionUpdate?.call(position);
  }

  Future<void> _primeImmediateLocation() async {
    try {
      final p = await _resolvePositionWithPermission();
      if (p != null) _emitPosition(p);
    } catch (_) {}
  }

  /// Fresh fix + [notifyListeners] (e.g. map "my location" control).
  Future<void> recenterOnCurrentLocation() async {
    try {
      final p = await _resolvePositionWithPermission();
      if (p != null) _emitPosition(p);
    } catch (_) {}
  }

  Future<Position?> _resolvePositionWithPermission() async {
    Position? p = await LocationPermissionHelper.trySilentPosition();
    if (p == null) {
      var granted = await LocationPermissionHelper.isLocationPermissionGranted();
      if (!granted) {
        granted = await LocationPermissionHelper.requestLocationPermission();
      }
      if (!granted) return null;
      p = await LocationPermissionHelper.getCurrentPositionWithRetries();
    }
    return p;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

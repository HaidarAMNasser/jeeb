import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

/// Dev/demo: simulates driver movement starting at **real GPS**, then toward pickup,
/// then ping-pong restaurant ↔ drop-off. Feeds the same [Position] stream as real GPS.
class FakeDeliveryTrackingController extends ChangeNotifier {
  FakeDeliveryTrackingController();

  bool _simulating = false;
  bool get simulating => _simulating;

  /// Map marker while simulating (driver position each tick).
  final ValueNotifier<LatLng?> simulatedMapPosition = ValueNotifier<LatLng?>(
    null,
  );

  void setSimulating(bool value) {
    if (_simulating == value) return;
    _simulating = value;
    if (!value) {
      simulatedMapPosition.value = null;
    }
    notifyListeners();
  }

  /// Single-subscription stream; cancel when [DeliveryOrderLocationReporter] disposes.
  Stream<Position> movementStreamFor(OrderEntity order) async* {
    final (rLat, rLng, dLat, dLng) = _endpoints(order);

    double curLat;
    double curLng;
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      curLat = p.latitude;
      curLng = p.longitude;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FakeDeliveryTracking: GPS fallback (${rLat},${rLng}): $e');
      }
      curLat = rLat;
      curLng = rLng;
    }

    simulatedMapPosition.value = LatLng(curLat, curLng);
    yield _positionAt(curLat, curLng);

    const introSteps = 5;
    for (var step = 1; step <= introSteps; step++) {
      await Future<void>.delayed(const Duration(seconds: 8));
      final u = step / introSteps;
      final lat = curLat + (rLat - curLat) * u;
      final lng = curLng + (rLng - curLng) * u;
      final pos = _positionAt(lat, lng);
      simulatedMapPosition.value = LatLng(lat, lng);
      yield pos;
    }

    const cycleTicks = 14;
    var tick = 0;
    while (true) {
      await Future<void>.delayed(const Duration(seconds: 8));
      final pos = _tickToPosition(
        tick++,
        rLat,
        rLng,
        dLat,
        dLng,
        cycleTicks,
      );
      simulatedMapPosition.value = LatLng(pos.latitude, pos.longitude);
      yield pos;
    }
  }

  (double, double, double, double) _endpoints(OrderEntity o) {
    final rLat = o.restaurantLatitude;
    final rLng = o.restaurantLongitude;
    final dLat = o.dropoffLatitude;
    final dLng = o.dropoffLongitude;
    if (rLat != null &&
        rLng != null &&
        dLat != null &&
        dLng != null &&
        (rLat - dLat).abs() + (rLng - dLng).abs() > 1e-6) {
      return (rLat, rLng, dLat, dLng);
    }
    const cLat = 30.0444;
    const cLng = 31.2357;
    return (cLat - 0.015, cLng - 0.015, cLat + 0.015, cLng + 0.015);
  }

  static Position _positionAt(double lat, double lng) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 9,
      speedAccuracy: 1,
      floor: null,
      isMocked: true,
    );
  }

  static Position _tickToPosition(
    int tick,
    double aLat,
    double aLng,
    double bLat,
    double bLng,
    int cycleTicks,
  ) {
    final phase = tick % cycleTicks;
    final half = cycleTicks ~/ 2;
    double u;
    if (half <= 1) {
      u = 0.5;
    } else if (phase < half) {
      u = phase / (half - 1);
    } else {
      u = 1.0 - (phase - half) / (half - 1);
    }
    u = u.clamp(0.0, 1.0);
    final lat = aLat + (bLat - aLat) * u;
    final lng = aLng + (bLng - aLng) * u;
    return _positionAt(lat, lng);
  }
}

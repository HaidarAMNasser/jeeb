import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_service.dart';

/// Throttled GPS → RTDB `/drivers/{driverId}` only.
///
/// Used while the driver does **not** have an active order in [OrderStatus.onTheWay]
/// (searching, assigned, picked up, etc.). Stops when the order reporter takes over.
class DriverIdlePresenceReporter {
  DriverIdlePresenceReporter({
    required this.driverId,
    required OrderStatusRtdbService rtdb,
    this.positionStream,
  }) : _rtdb = rtdb;

  final int driverId;
  final OrderStatusRtdbService _rtdb;
  final Stream<Position>? positionStream;

  StreamSubscription<Position>? _sub;
  Timer? _fixedIntervalTimer;
  DateTime? _lastSentAt;
  Position? _lastSentPosition;
  bool _publishedOnline = false;
  bool _publishInFlight = false;
  bool _started = false;

  static const Duration _minInterval = Duration(seconds: 8);
  static const double _minDistanceMeters = 12;

  bool get _usesRealGpsStream => positionStream == null;

  void ensureStarted() {
    if (_started) return;
    _started = true;

    if (_sub != null) return;
    final Stream<Position> stream = positionStream ??
        LocationService.instance.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        );
    _sub = stream.listen(
      (p) => unawaited(_handlePosition(p, requireMovement: false)),
      onError: (_) {},
    );

    if (_usesRealGpsStream) {
      unawaited(_pollCurrentLocation());
      _fixedIntervalTimer = Timer.periodic(_minInterval, (_) {
        unawaited(_pollCurrentLocation());
      });
    }
  }

  void reportPosition(Position p) {
    if (!_started) return;
    unawaited(_handlePosition(p, requireMovement: true));
  }

  Future<void> _pollCurrentLocation() async {
    if (!_usesRealGpsStream || _publishInFlight) return;
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      await _handlePosition(p, requireMovement: false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DriverIdlePresenceReporter: getCurrentPosition failed: $e');
      }
    }
  }

  Future<void> _handlePosition(Position p, {required bool requireMovement}) async {
    if (driverId <= 0 || _publishInFlight) return;
    final now = DateTime.now();
    if (_lastSentAt != null && now.difference(_lastSentAt!) < _minInterval) {
      return;
    }
    final prev = _lastSentPosition;
    if (requireMovement && prev != null) {
      final d = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        p.latitude,
        p.longitude,
      );
      if (d < _minDistanceMeters) return;
    }

    _publishInFlight = true;
    try {
      _lastSentAt = now;
      _lastSentPosition = p;

      try {
        await _rtdb.updateDriverPresence(
          driverId,
          lat: p.latitude,
          lng: p.longitude,
          isOnline: true,
        );
        _publishedOnline = true;
        if (kDebugMode) {
          debugPrint(
            '[DriverIdlePresenceReporter] RTDB /drivers/$driverId '
            'lat=${p.latitude.toStringAsFixed(6)} '
            'lng=${p.longitude.toStringAsFixed(6)} isOnline=true',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('DriverIdlePresenceReporter: RTDB failed: $e');
        }
      }
    } finally {
      _publishInFlight = false;
    }
  }

  void dispose() {
    _started = false;
    _fixedIntervalTimer?.cancel();
    _fixedIntervalTimer = null;
    _sub?.cancel();
    _sub = null;
    _lastSentAt = null;
    _lastSentPosition = null;
    if (_publishedOnline && driverId > 0) {
      unawaited(
        _rtdb.updateDriverOnlineStatus(driverId, false).catchError((_) {}),
      );
    }
    _publishedOnline = false;
  }
}

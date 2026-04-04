import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_service.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/tracking/domain/repositories/delivery_tracking_repository.dart';

/// Throttled GPS → [DeliveryTrackingRepository] (order route) + RTDB `/drivers/{driverId}`
/// (`currentLat` / `currentLng` / `isOnline`).
///
/// Order route points use movement-aware throttling. Driver presence on RTDB is also refreshed
/// on a fixed interval so [isOnline] and coordinates still update when the device is stationary
/// (Geolocator `distanceFilter` alone may not emit).
class DeliveryOrderLocationReporter {
  DeliveryOrderLocationReporter({
    required this.orderId,
    required this.driverId,
    required DeliveryTrackingRepository repository,
    required OrderStatusRtdbService rtdb,
    this.positionStream,
  }) : _repository = repository,
       _rtdb = rtdb;

  /// When set, used instead of real GPS (demo / QA).
  final Stream<Position>? positionStream;

  final int orderId;
  /// Logged-in delivery user id (same as Firebase `drivers/{id}` key).
  final int driverId;
  final DeliveryTrackingRepository _repository;
  final OrderStatusRtdbService _rtdb;

  StreamSubscription<Position>? _sub;
  Timer? _fixedIntervalTimer;
  DateTime? _lastSentAt;
  Position? _lastSentPosition;
  bool _publishedOnline = false;
  bool _publishInFlight = false;

  /// Minimum time between publishes (order API + driver RTDB).
  static const Duration _minInterval = Duration(seconds: 10);
  static const double _minDistanceMeters = 12;

  /// Live GPS → API + RTDB only after the driver marks the order [OrderStatus.onTheWay].
  static bool shouldTrack(OrderStatus status) {
    return status == OrderStatus.onTheWay;
  }

  bool get _usesRealGpsStream => positionStream == null;

  void ensureStarted() {
    if (_sub != null) return;
    final Stream<Position> stream = positionStream ??
        LocationService.instance.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 8,
          ),
        );
    _sub = stream.listen(
      (p) => unawaited(_handlePosition(p, requireMovement: true)),
      onError: (_) {},
    );

    // Real GPS: periodic poll so we still publish every [_minInterval] when not moving.
    if (_usesRealGpsStream) {
      _fixedIntervalTimer = Timer.periodic(_minInterval, (_) {
        unawaited(_pollCurrentLocation());
      });
      unawaited(_pollCurrentLocation());
    }
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
        debugPrint('DeliveryOrderLocationReporter: getCurrentPosition failed: $e');
      }
    }
  }

  Future<void> _handlePosition(Position p, {required bool requireMovement}) async {
    if (_publishInFlight) return;
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

      final speedKmh = (p.speed.isFinite ? p.speed : 0) * 3.6;
      final clampedSpeed = speedKmh.clamp(0.0, 200.0);

      await _repository.pushLocationUpdate(
        orderId: orderId,
        lat: p.latitude,
        lng: p.longitude,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        speedKmh: clampedSpeed,
      );

      if (driverId > 0) {
        try {
          await _rtdb.updateDriverLocation(driverId, p.latitude, p.longitude);
          await _rtdb.updateDriverOnlineStatus(driverId, true);
          _publishedOnline = true;
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'DeliveryOrderLocationReporter: RTDB driver presence failed (rules/auth?): $e',
            );
          }
        }
      }
    } finally {
      _publishInFlight = false;
    }
  }

  void dispose() {
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

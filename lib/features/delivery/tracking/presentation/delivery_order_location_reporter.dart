import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_service.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/tracking/domain/repositories/delivery_tracking_repository.dart';

/// Throttled GPS → [DeliveryTrackingRepository] + RTDB `/drivers/{driverId}` while delivering.
class DeliveryOrderLocationReporter {
  DeliveryOrderLocationReporter({
    required this.orderId,
    required this.driverId,
    required DeliveryTrackingRepository repository,
    required OrderStatusRtdbService rtdb,
  }) : _repository = repository,
       _rtdb = rtdb;

  final int orderId;
  /// Logged-in delivery user id (same as Firebase `drivers/{id}` key).
  final int driverId;
  final DeliveryTrackingRepository _repository;
  final OrderStatusRtdbService _rtdb;

  StreamSubscription<Position>? _sub;
  DateTime? _lastSentAt;
  Position? _lastSentPosition;
  bool _publishedOnline = false;

  static const Duration _minInterval = Duration(seconds: 8);
  static const double _minDistanceMeters = 12;

  static bool shouldTrack(OrderStatus status) {
    switch (status) {
      case OrderStatus.assigned:
      case OrderStatus.readyForPickup:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return true;
      default:
        return false;
    }
  }

  void ensureStarted() {
    if (_sub != null) return;
    _sub = LocationService.instance
        .getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 8,
          ),
        )
        .listen(_onPosition, onError: (_) {});
  }

  Future<void> _onPosition(Position p) async {
    final now = DateTime.now();
    if (_lastSentAt != null && now.difference(_lastSentAt!) < _minInterval) {
      return;
    }
    final prev = _lastSentPosition;
    if (prev != null) {
      final d = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        p.latitude,
        p.longitude,
      );
      if (d < _minDistanceMeters) return;
    }

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
      } catch (_) {}
    }
  }

  void dispose() {
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

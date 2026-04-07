import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/google_directions_service.dart';
import 'package:jeeb_app/core/presentation/maps/route_history_polyline_builder.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/bloc/delivery_home_bloc.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/tracking/presentation/delivery_order_location_reporter.dart';

/// RTDB walked path + Directions API: driver→pickup (dashed blue) + pickup→drop (dashed amber).
class DeliveryRouteManager extends ChangeNotifier {
  bool _disposed = false;
  StreamSubscription<List<RouteHistoryPoint>>? _assignedRouteHistorySub;
  Set<Polyline> _assignedRoutePolylines = {};
  String? _subscribedAssignedOrderId;

  Polyline? _plannedDropoffPolyline;
  Polyline? _plannedPickupPolyline;
  String? _dropoffGeoKey;

  DateTime? _lastPickupFetchAt;
  double? _lastPickupDriverLat;
  double? _lastPickupDriverLng;

  Set<Polyline> get combinedRoutePolylines => {
        if (_plannedPickupPolyline != null) _plannedPickupPolyline!,
        if (_plannedDropoffPolyline != null) _plannedDropoffPolyline!,
        ..._assignedRoutePolylines,
      };

  String? _assignedOrderIdFromState(DeliveryHomeState state) {
    if (state is DeliveryHomeLoaded && state.assignedOrder != null) {
      final order = state.assignedOrder!;
      final status = OrderStatus.fromString(order.status);
      if (!DeliveryOrderLocationReporter.shouldTrack(status)) {
        return null;
      }
      return order.id;
    }
    return null;
  }

  void syncAssignedRouteHistorySubscription(DeliveryHomeState state) {
    final key = _assignedOrderIdFromState(state);
    if (key == _subscribedAssignedOrderId) return;
    _subscribedAssignedOrderId = key;

    _assignedRouteHistorySub?.cancel();
    _assignedRouteHistorySub = null;
    _assignedRoutePolylines = {};
    notifyListeners();

    if (key == null || key.isEmpty) return;

    _assignedRouteHistorySub =
        di.sl<OrderStatusRtdbService>().watchOrderRouteHistory(key).listen(
      (points) {
        final latLngs = RouteHistoryPolylineBuilder.toLatLngs(points);
        _assignedRoutePolylines = RouteHistoryPolylineBuilder.walkedPath(
          orderId: key,
          points: latLngs,
        );
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  void _clearPlannedDrivingRoutes() {
    _plannedDropoffPolyline = null;
    _plannedPickupPolyline = null;
    _dropoffGeoKey = null;
    _lastPickupFetchAt = null;
    _lastPickupDriverLat = null;
    _lastPickupDriverLng = null;
  }

  Future<void> syncPlannedDrivingRoute(
    DeliveryHomeState state, {
    double? driverLat,
    double? driverLng,
  }) async {
    if (state is! DeliveryHomeLoaded || state.assignedOrder == null) {
      if (_plannedDropoffPolyline != null ||
          _plannedPickupPolyline != null ||
          _dropoffGeoKey != null) {
        _clearPlannedDrivingRoutes();
        notifyListeners();
      }
      return;
    }
    final o = state.assignedOrder!;
    final rLat = o.restaurantLatitude;
    final rLng = o.restaurantLongitude;
    final dLat = o.dropoffLatitude;
    final dLng = o.dropoffLongitude;

    if (rLat == null || rLng == null || dLat == null || dLng == null) {
      if (_plannedDropoffPolyline != null ||
          _plannedPickupPolyline != null ||
          _dropoffGeoKey != null) {
        _clearPlannedDrivingRoutes();
        notifyListeners();
      }
      return;
    }

    final dropKey = '${o.id}_drop_${rLat}_${rLng}_${dLat}_$dLng';

    if (_dropoffGeoKey != dropKey) {
      _dropoffGeoKey = dropKey;
      final pts = await GoogleDirectionsService.getDrivingPolyline(
        originLat: rLat,
        originLng: rLng,
        destinationLat: dLat,
        destinationLng: dLng,
      );
      if (_disposed) return;
      if (_dropoffGeoKey != dropKey) return;
      _plannedDropoffPolyline = pts == null || pts.isEmpty
          ? null
          : RouteHistoryPolylineBuilder.plannedDropoffLeg(
              orderId: o.id,
              points: pts,
            );
      notifyListeners();
    }

    if (driverLat == null || driverLng == null) {
      if (_plannedPickupPolyline != null ||
          _lastPickupFetchAt != null ||
          _lastPickupDriverLat != null) {
        _plannedPickupPolyline = null;
        _lastPickupFetchAt = null;
        _lastPickupDriverLat = null;
        _lastPickupDriverLng = null;
        notifyListeners();
      }
      return;
    }

    final needPickup = _plannedPickupPolyline == null ||
        _lastPickupFetchAt == null ||
        _lastPickupDriverLat == null ||
        _lastPickupDriverLng == null ||
        DateTime.now().difference(_lastPickupFetchAt!) >
            const Duration(seconds: 40) ||
        Geolocator.distanceBetween(
              _lastPickupDriverLat!,
              _lastPickupDriverLng!,
              driverLat,
              driverLng,
            ) >
            120;

    if (!needPickup) return;

    final pts = await GoogleDirectionsService.getDrivingPolyline(
      originLat: driverLat,
      originLng: driverLng,
      destinationLat: rLat,
      destinationLng: rLng,
    );
    if (_disposed) return;
    if (state.assignedOrder?.id != o.id) {
      return;
    }
    if (pts == null || pts.isEmpty) {
      _plannedPickupPolyline = null;
    } else {
      _plannedPickupPolyline = RouteHistoryPolylineBuilder.plannedPickupLeg(
        orderId: o.id,
        points: pts,
      );
    }
    _lastPickupFetchAt = DateTime.now();
    _lastPickupDriverLat = driverLat;
    _lastPickupDriverLng = driverLng;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _assignedRouteHistorySub?.cancel();
    super.dispose();
  }
}

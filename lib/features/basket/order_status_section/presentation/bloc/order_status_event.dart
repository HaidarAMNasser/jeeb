part of 'order_status_bloc.dart';

sealed class OrderStatusEvent extends Equatable {
  const OrderStatusEvent();
}

class OrderStatusToggleDemo extends OrderStatusEvent {
  const OrderStatusToggleDemo();

  @override
  List<Object?> get props => [];
}

class OrderStatusDemoTick extends OrderStatusEvent {
  const OrderStatusDemoTick();

  @override
  List<Object?> get props => [];
}

/// Internal: snapshot from Firebase RTDB `/orders/{id}/status`.
class OrderStatusRealtimeSnapshot extends OrderStatusEvent {
  const OrderStatusRealtimeSnapshot(this.statusWire);

  final String? statusWire;

  @override
  List<Object?> get props => [statusWire];
}

/// Internal: new driver coordinates from Firebase RTDB `/drivers/{deliveryId}`.
class OrderStatusDriverLocationUpdated extends OrderStatusEvent {
  const OrderStatusDriverLocationUpdated({
    required this.latitude,
    required this.longitude,
    required this.isOnline,
  });

  final double latitude;
  final double longitude;
  final bool isOnline;

  @override
  List<Object?> get props => [latitude, longitude, isOnline];
}

/// Internal: clear current driver marker.
class OrderStatusDriverLocationCleared extends OrderStatusEvent {
  const OrderStatusDriverLocationCleared();

  @override
  List<Object?> get props => [];
}

/// Internal: points from Firebase RTDB `/orders/{id}/routeHistory`.
class OrderStatusRouteHistorySnapshot extends OrderStatusEvent {
  const OrderStatusRouteHistorySnapshot(this.points);

  final List<RouteHistoryPoint> points;

  @override
  List<Object?> get props => [points];
}

/// Load driver name/phone from REST when missing from route args (same source as order details).
class OrderStatusHydrateDriverFromOrder extends OrderStatusEvent {
  const OrderStatusHydrateDriverFromOrder();

  @override
  List<Object?> get props => [];
}

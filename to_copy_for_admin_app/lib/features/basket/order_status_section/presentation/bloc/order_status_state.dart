part of 'order_status_bloc.dart';

class OrderStatusState extends Equatable {
  const OrderStatusState({
    required this.orderId,
    required this.routeStatus,
    required this.demoRunning,
    required this.liveStepIndex,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.driverLatitude,
    this.driverLongitude,
    this.driverOnline = false,
  });

  final String orderId;
  final OrderStatus routeStatus;
  final bool demoRunning;
  final int liveStepIndex;
  /// Customer drop-off from order `deliveryCoordinates` (map centers here first).
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? driverLatitude;
  final double? driverLongitude;
  final bool driverOnline;

  static int _staticTimelineIndex(OrderStatus status) {
    var idx = orderStatusToTimelineIndex(status);
    if (idx < 0) idx = 0;
    return idx.clamp(0, 6);
  }

  int get displayIndex =>
      demoRunning ? liveStepIndex.clamp(0, 6) : _staticTimelineIndex(routeStatus);

  bool get showProblemBanner => orderStatusToTimelineIndex(routeStatus) < 0;

  factory OrderStatusState.initial(
    String orderId,
    OrderStatus routeStatus, {
    double? deliveryLatitude,
    double? deliveryLongitude,
  }) {
    return OrderStatusState(
      orderId: orderId,
      routeStatus: routeStatus,
      demoRunning: false,
      liveStepIndex: _staticTimelineIndex(routeStatus),
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
    );
  }

  OrderStatusState copyWith({
    String? orderId,
    OrderStatus? routeStatus,
    bool? demoRunning,
    int? liveStepIndex,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? driverLatitude,
    double? driverLongitude,
    bool? driverOnline,
    bool clearDriverLocation = false,
  }) {
    return OrderStatusState(
      orderId: orderId ?? this.orderId,
      routeStatus: routeStatus ?? this.routeStatus,
      demoRunning: demoRunning ?? this.demoRunning,
      liveStepIndex: liveStepIndex ?? this.liveStepIndex,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      driverLatitude: clearDriverLocation
          ? null
          : (driverLatitude ?? this.driverLatitude),
      driverLongitude: clearDriverLocation
          ? null
          : (driverLongitude ?? this.driverLongitude),
      driverOnline: driverOnline ?? this.driverOnline,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        routeStatus,
        demoRunning,
        liveStepIndex,
        deliveryLatitude,
        deliveryLongitude,
        driverLatitude,
        driverLongitude,
        driverOnline,
      ];
}

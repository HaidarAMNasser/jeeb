part of 'order_status_bloc.dart';

class OrderStatusState extends Equatable {
  const OrderStatusState({
    required this.orderId,
    required this.routeStatus,
    required this.demoRunning,
    required this.liveStepIndex,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryManName,
    this.deliveryManPhone,
    this.driverLatitude,
    this.driverLongitude,
    this.driverOnline = false,
    this.routeHistoryPoints = const [],
  });

  final String orderId;
  final OrderStatus routeStatus;
  final bool demoRunning;
  final int liveStepIndex;
  /// Customer drop-off from order `deliveryCoordinates` (map centers here first).
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  /// Shown on the assigned step when provided (from order details / list).
  final String? deliveryManName;
  final String? deliveryManPhone;
  final double? driverLatitude;
  final double? driverLongitude;
  final bool driverOnline;
  /// Walked path from RTDB `routeHistory` (same source as delivery route map).
  final List<RouteHistoryPoint> routeHistoryPoints;

  static int _staticTimelineIndex(OrderStatus status) {
    var idx = orderStatusToTimelineIndex(status);
    if (idx < 0) idx = 0;
    return idx.clamp(0, kOrderTimelineStepMax);
  }

  int get displayIndex =>
      demoRunning
          ? liveStepIndex.clamp(0, kOrderTimelineStepMax)
          : _staticTimelineIndex(routeStatus);

  bool get showProblemBanner => orderStatusToTimelineIndex(routeStatus) < 0;

  factory OrderStatusState.initial(
    String orderId,
    OrderStatus routeStatus, {
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryManName,
    String? deliveryManPhone,
  }) {
    return OrderStatusState(
      orderId: orderId,
      routeStatus: routeStatus,
      demoRunning: false,
      liveStepIndex: _staticTimelineIndex(routeStatus),
      deliveryLatitude: deliveryLatitude,
      deliveryLongitude: deliveryLongitude,
      deliveryManName: deliveryManName,
      deliveryManPhone: deliveryManPhone,
    );
  }

  OrderStatusState copyWith({
    String? orderId,
    OrderStatus? routeStatus,
    bool? demoRunning,
    int? liveStepIndex,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryManName,
    String? deliveryManPhone,
    double? driverLatitude,
    double? driverLongitude,
    bool? driverOnline,
    bool clearDriverLocation = false,
    List<RouteHistoryPoint>? routeHistoryPoints,
    bool clearRouteHistory = false,
  }) {
    return OrderStatusState(
      orderId: orderId ?? this.orderId,
      routeStatus: routeStatus ?? this.routeStatus,
      demoRunning: demoRunning ?? this.demoRunning,
      liveStepIndex: liveStepIndex ?? this.liveStepIndex,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryManName: deliveryManName ?? this.deliveryManName,
      deliveryManPhone: deliveryManPhone ?? this.deliveryManPhone,
      driverLatitude: clearDriverLocation
          ? null
          : (driverLatitude ?? this.driverLatitude),
      driverLongitude: clearDriverLocation
          ? null
          : (driverLongitude ?? this.driverLongitude),
      driverOnline: driverOnline ?? this.driverOnline,
      routeHistoryPoints: clearRouteHistory
          ? const []
          : (routeHistoryPoints ?? this.routeHistoryPoints),
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
        deliveryManName,
        deliveryManPhone,
        driverLatitude,
        driverLongitude,
        driverOnline,
        routeHistoryPoints,
      ];
}

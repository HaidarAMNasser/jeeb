part of 'order_status_bloc.dart';

class OrderStatusState extends Equatable {
  const OrderStatusState({
    required this.orderId,
    required this.routeStatus,
    required this.demoRunning,
    required this.liveStepIndex,
  });

  final String orderId;
  final OrderStatus routeStatus;
  final bool demoRunning;
  final int liveStepIndex;

  static int _staticTimelineIndex(OrderStatus status) {
    var idx = orderStatusToTimelineIndex(status);
    if (idx < 0) idx = 0;
    return idx.clamp(0, 6);
  }

  int get displayIndex =>
      demoRunning ? liveStepIndex.clamp(0, 6) : _staticTimelineIndex(routeStatus);

  bool get showProblemBanner => orderStatusToTimelineIndex(routeStatus) < 0;

  factory OrderStatusState.initial(String orderId, OrderStatus routeStatus) {
    return OrderStatusState(
      orderId: orderId,
      routeStatus: routeStatus,
      demoRunning: false,
      liveStepIndex: _staticTimelineIndex(routeStatus),
    );
  }

  OrderStatusState copyWith({
    String? orderId,
    OrderStatus? routeStatus,
    bool? demoRunning,
    int? liveStepIndex,
  }) {
    return OrderStatusState(
      orderId: orderId ?? this.orderId,
      routeStatus: routeStatus ?? this.routeStatus,
      demoRunning: demoRunning ?? this.demoRunning,
      liveStepIndex: liveStepIndex ?? this.liveStepIndex,
    );
  }

  @override
  List<Object?> get props => [orderId, routeStatus, demoRunning, liveStepIndex];
}

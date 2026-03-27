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

/// Internal: timer-driven refetch of order status from REST.
class OrderStatusPollTick extends OrderStatusEvent {
  const OrderStatusPollTick();

  @override
  List<Object?> get props => [];
}

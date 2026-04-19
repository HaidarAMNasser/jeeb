part of 'order_details_bloc.dart';

abstract class OrderDetailsEvent extends Equatable {
  const OrderDetailsEvent();

  @override
  List<Object> get props => [];
}

class GetOrderDetailsEvent extends OrderDetailsEvent {
  final String id;

  const GetOrderDetailsEvent(this.id);

  @override
  List<Object> get props => [id];
}

class OrderDetailsRtdbStatusChanged extends OrderDetailsEvent {
  final String statusWire;

  const OrderDetailsRtdbStatusChanged(this.statusWire);

  @override
  List<Object> get props => [statusWire];
}

class CancelOrderEvent extends OrderDetailsEvent {
  const CancelOrderEvent();
}

class ClearOrderDetailsTransientEvent extends OrderDetailsEvent {
  const ClearOrderDetailsTransientEvent();
}


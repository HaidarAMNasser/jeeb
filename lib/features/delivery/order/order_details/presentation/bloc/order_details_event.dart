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


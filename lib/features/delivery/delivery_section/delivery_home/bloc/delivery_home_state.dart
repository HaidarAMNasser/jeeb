part of 'delivery_home_bloc.dart';

abstract class DeliveryHomeState extends Equatable {
  const DeliveryHomeState();

  @override
  List<Object?> get props => [];
}

class DeliveryHomeInitial extends DeliveryHomeState {
  const DeliveryHomeInitial();
}

class DeliveryHomeLoading extends DeliveryHomeState {
  const DeliveryHomeLoading();
}

class DeliveryHomeLoaded extends DeliveryHomeState {
  final List<OrderEntity> availableOrders;
  final OrderEntity? assignedOrder;
  final String? errorMessage;

  const DeliveryHomeLoaded({
    required this.availableOrders,
    this.assignedOrder,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [availableOrders, assignedOrder, errorMessage];

  DeliveryHomeLoaded copyWith({
    List<OrderEntity>? availableOrders,
    OrderEntity? assignedOrder,
    String? errorMessage,
  }) {
    return DeliveryHomeLoaded(
      availableOrders: availableOrders ?? this.availableOrders,
      assignedOrder: assignedOrder ?? this.assignedOrder,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DeliveryHomeError extends DeliveryHomeState {
  final String message;

  const DeliveryHomeError({required this.message});

  @override
  List<Object?> get props => [message];
}

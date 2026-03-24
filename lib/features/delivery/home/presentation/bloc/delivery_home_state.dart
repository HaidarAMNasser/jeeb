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
  final List<OrderEntity> orders;
  final String? errorMessage;

  const DeliveryHomeLoaded({
    required this.orders,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [orders, errorMessage];

  DeliveryHomeLoaded copyWith({
    List<OrderEntity>? orders,
    String? errorMessage,
  }) {
    return DeliveryHomeLoaded(
      orders: orders ?? this.orders,
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

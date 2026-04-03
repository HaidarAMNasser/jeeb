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

  /// Set on pull-to-refresh completion so identical payloads still emit (await + UI).
  final DateTime? refreshedAt;

  const DeliveryHomeLoaded({
    required this.availableOrders,
    this.assignedOrder,
    this.errorMessage,
    this.refreshedAt,
  });

  @override
  List<Object?> get props =>
      [availableOrders, assignedOrder, errorMessage, refreshedAt];

  DeliveryHomeLoaded copyWith({
    List<OrderEntity>? availableOrders,
    OrderEntity? assignedOrder,
    String? errorMessage,
    DateTime? refreshedAt,
  }) {
    return DeliveryHomeLoaded(
      availableOrders: availableOrders ?? this.availableOrders,
      assignedOrder: assignedOrder ?? this.assignedOrder,
      errorMessage: errorMessage ?? this.errorMessage,
      refreshedAt: refreshedAt ?? this.refreshedAt,
    );
  }
}

class DeliveryHomeError extends DeliveryHomeState {
  final String message;

  /// Distinguishes otherwise-identical errors so refresh can emit and listeners complete.
  final DateTime emittedAt;

  DeliveryHomeError({required this.message, DateTime? emittedAt})
      : emittedAt = emittedAt ?? DateTime.now();

  @override
  List<Object?> get props => [message, emittedAt];
}

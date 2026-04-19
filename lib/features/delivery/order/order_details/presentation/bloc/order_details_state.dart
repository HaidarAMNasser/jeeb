import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

abstract class OrderDetailsState extends Equatable {
  const OrderDetailsState();

  @override
  List<Object?> get props => [];
}

class OrderDetailsInitial extends OrderDetailsState {
  const OrderDetailsInitial();
}

class OrderDetailsLoading extends OrderDetailsState {
  const OrderDetailsLoading();
}

class OrderDetailsLoaded extends OrderDetailsState {
  final OrderEntity order;
  final bool isCancelling;
  final String? actionError;

  const OrderDetailsLoaded({
    required this.order,
    this.isCancelling = false,
    this.actionError,
  });

  OrderDetailsLoaded copyWith({
    OrderEntity? order,
    bool? isCancelling,
    String? actionError,
    bool clearActionError = false,
  }) {
    return OrderDetailsLoaded(
      order: order ?? this.order,
      isCancelling: isCancelling ?? this.isCancelling,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [order, isCancelling, actionError];
}

class OrderDetailsError extends OrderDetailsState {
  final String message;

  const OrderDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

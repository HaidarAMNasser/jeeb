part of 'manage_order_bloc.dart';

/// Which manage-order action succeeded (used for localized snackbars).
enum ManageOrderSuccessKind {
  acceptDelivery,
  confirmPickup,
  markOnTheWay,
  markDelivered,
  rejectDelivery,
}

abstract class ManageOrderState extends Equatable {
  const ManageOrderState();

  @override
  List<Object?> get props => [];
}

class ManageOrderInitial extends ManageOrderState {
  const ManageOrderInitial();
}

class ManageOrderLoading extends ManageOrderState {
  const ManageOrderLoading();
}

class ManageOrderSuccess extends ManageOrderState {
  final ManageOrderSuccessKind kind;

  const ManageOrderSuccess({required this.kind});

  @override
  List<Object?> get props => [kind];
}

class ManageOrderError extends ManageOrderState {
  final String message;

  const ManageOrderError({required this.message});

  @override
  List<Object?> get props => [message];
}

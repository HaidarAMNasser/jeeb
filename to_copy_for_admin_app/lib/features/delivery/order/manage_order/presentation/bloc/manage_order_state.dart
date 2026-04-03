part of 'manage_order_bloc.dart';

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
  final String message;

  const ManageOrderSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class ManageOrderError extends ManageOrderState {
  final String message;

  const ManageOrderError({required this.message});

  @override
  List<Object?> get props => [message];
}

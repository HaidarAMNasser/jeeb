part of 'manage_cart_bloc.dart';

abstract class ManageCartState extends Equatable {
  const ManageCartState();

  @override
  List<Object?> get props => [];
}

class ManageCartInitial extends ManageCartState {
  const ManageCartInitial();
}

class ManageCartLoading extends ManageCartState {
  const ManageCartLoading();
}

class ManageCartSuccess extends ManageCartState {
  final BasketEntity? basket;

  const ManageCartSuccess(this.basket);

  @override
  List<Object?> get props => [basket];
}

class ManageCartCleared extends ManageCartState {
  const ManageCartCleared();
}

class ManageCartError extends ManageCartState {
  final String message;

  const ManageCartError(this.message);

  @override
  List<Object?> get props => [message];
}

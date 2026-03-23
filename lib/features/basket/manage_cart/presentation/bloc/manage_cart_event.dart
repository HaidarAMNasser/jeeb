part of 'manage_cart_bloc.dart';

abstract class ManageCartEvent extends Equatable {
  const ManageCartEvent();

  @override
  List<Object?> get props => [];
}

class AddProductToCartEvent extends ManageCartEvent {
  final String productId;
  final int quantity;

  const AddProductToCartEvent(this.productId, {this.quantity = 1});

  @override
  List<Object?> get props => [productId, quantity];
}

class UpdateCartItemQuantityEvent extends ManageCartEvent {
  final String productId;
  final int quantity;

  const UpdateCartItemQuantityEvent(this.productId, this.quantity);

  @override
  List<Object?> get props => [productId, quantity];
}

class RemoveCartItemEvent extends ManageCartEvent {
  final String productId;

  const RemoveCartItemEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ClearCartEvent extends ManageCartEvent {
  const ClearCartEvent();
}

class ReplaceCartItemsEvent extends ManageCartEvent {
  final List<Map<String, dynamic>> items;

  const ReplaceCartItemsEvent(this.items);

  @override
  List<Object?> get props => [items];
}

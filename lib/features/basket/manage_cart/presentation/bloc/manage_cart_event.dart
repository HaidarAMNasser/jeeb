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
  final List<Map<String, dynamic>> offers;

  const ReplaceCartItemsEvent(this.items, {this.offers = const []});

  @override
  List<Object?> get props => [items, offers];
}

class AddOfferToCartEvent extends ManageCartEvent {
  final String offerId;
  final int quantity;

  const AddOfferToCartEvent(this.offerId, {this.quantity = 1});

  @override
  List<Object?> get props => [offerId, quantity];
}

part of 'list_cart_bloc.dart';

abstract class ListCartEvent extends Equatable {
  const ListCartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCartEvent extends ListCartEvent {
  const LoadCartEvent();
}

class IncreaseCartItemEvent extends ListCartEvent {
  final String productId;

  const IncreaseCartItemEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class DecreaseCartItemEvent extends ListCartEvent {
  final String productId;

  const DecreaseCartItemEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class SaveCartChangesEvent extends ListCartEvent {
  const SaveCartChangesEvent();
}

class ClearCartNoticeEvent extends ListCartEvent {
  const ClearCartNoticeEvent();
}

class ClearEntireCartEvent extends ListCartEvent {
  const ClearEntireCartEvent();
}

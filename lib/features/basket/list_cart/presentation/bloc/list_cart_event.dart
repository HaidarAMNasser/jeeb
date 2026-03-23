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
  final String itemId;
  final bool isOffer;

  const IncreaseCartItemEvent(this.itemId, {this.isOffer = false});

  @override
  List<Object?> get props => [itemId, isOffer];
}

class DecreaseCartItemEvent extends ListCartEvent {
  final String itemId;
  final bool isOffer;

  const DecreaseCartItemEvent(this.itemId, {this.isOffer = false});

  @override
  List<Object?> get props => [itemId, isOffer];
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

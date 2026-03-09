part of 'list_product_bloc.dart';

abstract class ListProductEvent extends Equatable {
  const ListProductEvent();

  @override
  List<Object> get props => [];
}

class GetProductsEvent extends ListProductEvent {
  final bool loadMore;
  final String? merchantId;

  const GetProductsEvent({this.loadMore = false, this.merchantId});

  @override
  List<Object> get props => [loadMore, merchantId ?? ''];
}

class ToggleFavoriteProductEvent extends ListProductEvent {
  final String productId;

  const ToggleFavoriteProductEvent(this.productId);

  @override
  List<Object> get props => [productId];
}


part of 'list_merchant_bloc.dart';

abstract class ListMerchantEvent extends Equatable {
  const ListMerchantEvent();

  @override
  List<Object> get props => [];
}

class GetMerchantsEvent extends ListMerchantEvent {
  final bool loadMore;
  final String? search;

  const GetMerchantsEvent({
    this.loadMore = false,
    this.search,
  });

  @override
  List<Object> get props => [loadMore, search ?? ''];
}

class ToggleFavoriteMerchantEvent extends ListMerchantEvent {
  final String merchantId;

  const ToggleFavoriteMerchantEvent(this.merchantId);

  @override
  List<Object> get props => [merchantId];
}


part of 'list_order_bloc.dart';

abstract class ListOrderEvent extends Equatable {
  const ListOrderEvent();

  @override
  List<Object> get props => [];
}

class GetOrdersEvent extends ListOrderEvent {
  final bool loadMore;
  final String? search;
  final String? status;
  final String? merchantId;

  const GetOrdersEvent({
    this.loadMore = false,
    this.search,
    this.status,
    this.merchantId,
  });

  @override
  List<Object> get props => [
    loadMore,
    search ?? '',
    status ?? '',
    merchantId ?? '',
  ];
}


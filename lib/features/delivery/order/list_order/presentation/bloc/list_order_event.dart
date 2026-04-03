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

class ListOrderRtdbStatusChanged extends ListOrderEvent {
  final String orderId;
  final String statusWire;

  const ListOrderRtdbStatusChanged({
    required this.orderId,
    required this.statusWire,
  });

  @override
  List<Object> get props => [orderId, statusWire];
}


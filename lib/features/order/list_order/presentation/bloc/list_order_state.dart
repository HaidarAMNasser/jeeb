part of 'list_order_bloc.dart';

abstract class ListOrderState extends Equatable {
  const ListOrderState();

  @override
  List<Object?> get props => [];
}

class ListOrderInitial extends ListOrderState {
  const ListOrderInitial();
}

class ListOrderLoading extends ListOrderState {
  const ListOrderLoading();
}

class ListOrderLoaded extends ListOrderState {
  final List<OrderEntity> orders;
  final bool hasMore;
  final int currentPage;
  final String? search;
  final String? merchantId;

  const ListOrderLoaded({
    required this.orders,
    this.hasMore = true,
    this.currentPage = 1,
    this.search,
    this.merchantId,
  });

  @override
  List<Object?> get props => [orders, hasMore, currentPage, search, merchantId];
}

class ListOrderError extends ListOrderState {
  final String message;

  const ListOrderError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ListOrderLoadingMore extends ListOrderState {
  final List<OrderEntity> orders;
  final int currentPage;
  final String? search;
  final String? merchantId;

  const ListOrderLoadingMore({
    required this.orders,
    required this.currentPage,
    this.search,
    this.merchantId,
  });

  @override
  List<Object?> get props => [orders, currentPage, search, merchantId];
}


import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/delivery/order/list_order/data/repositories/list_order_repository.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

part 'list_order_event.dart';
part 'list_order_state.dart';

class ListOrderBloc extends Bloc<ListOrderEvent, ListOrderState> {
  final ListOrderRepository _repository;
  static const int _pageSize = 20;

  ListOrderBloc(this._repository) : super(const ListOrderInitial()) {
    on<ListOrderEvent>((event, emit) async {
      if (event is GetOrdersEvent) {
        if (event.loadMore) {
          // Load more orders
          final currentState = state;
          if (currentState is ListOrderLoaded) {
            emit(
              ListOrderLoadingMore(
                orders: currentState.orders,
                currentPage: currentState.currentPage,
                search: currentState.search,
                status: currentState.status,
                merchantId: currentState.merchantId,
              ),
            );

            final nextPage = currentState.currentPage + 1;
            final searchQuery = event.search ?? currentState.search;
            final status = event.status ?? currentState.status;
            final ownerId = event.merchantId ?? currentState.merchantId;
            final result = await _repository.getOrders(
              page: nextPage,
              limit: _pageSize,
              search: searchQuery,
              status: status,
              ownerId: ownerId,
            );

            result.fold((l) => emit(ListOrderError(message: l.message)), (
              newOrders,
            ) {
              final updatedOrders = [...currentState.orders, ...newOrders];
              emit(
                ListOrderLoaded(
                  orders: updatedOrders,
                  hasMore: newOrders.length == _pageSize,
                  currentPage: nextPage,
                  search: searchQuery,
                  status: status,
                  merchantId: ownerId,
                ),
              );
            });
          }
        } else {
          // Initial load or refresh
          emit(const ListOrderLoading());
          final result = await _repository.getOrders(
            page: 1,
            limit: _pageSize,
            search: event.search,
            status: event.status,
            ownerId: event.merchantId,
          );

          result.fold(
            (l) => emit(ListOrderError(message: l.message)),
            (orders) => emit(
              ListOrderLoaded(
                orders: orders,
                hasMore: orders.length == _pageSize,
                currentPage: 1,
                search: event.search,
                status: event.status,
                merchantId: event.merchantId,
              ),
            ),
          );
        }
      }
    });
  }
}

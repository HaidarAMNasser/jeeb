import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/features/delivery/order/list_order/data/repositories/list_order_repository.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

part 'list_order_event.dart';
part 'list_order_state.dart';

class ListOrderBloc extends Bloc<ListOrderEvent, ListOrderState> {
  ListOrderBloc(this._repository, this._rtdb) : super(const ListOrderInitial()) {
    on<GetOrdersEvent>(_onGetOrders);
    on<ListOrderRtdbStatusChanged>(_onRtdbStatus);
  }

  final ListOrderRepository _repository;
  final OrderStatusRtdbService _rtdb;
  static const int _pageSize = 20;
  final List<StreamSubscription<String?>> _rtdbSubs = [];

  void _detachRtdb() {
    for (final s in _rtdbSubs) {
      s.cancel();
    }
    _rtdbSubs.clear();
  }

  void _attachRtdb(List<OrderEntity> orders) {
    _detachRtdb();
    final seen = <String>{};
    for (final o in orders) {
      final id = o.id.trim();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      _rtdbSubs.add(
        _rtdb.watchOrderStatusWire(id).listen(
          (wire) {
            final w = wire?.trim();
            if (w == null || w.isEmpty) return;
            add(ListOrderRtdbStatusChanged(orderId: id, statusWire: w));
          },
          onError: (_) {},
        ),
      );
    }
  }

  List<OrderEntity>? _patchOrderStatus(
    List<OrderEntity> orders,
    String orderId,
    String wire,
  ) {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return null;
    final o = orders[idx];
    if (wire.toUpperCase() == (o.status ?? '').toUpperCase()) return null;
    final next = List<OrderEntity>.from(orders);
    next[idx] = o.copyWith(status: wire);
    return next;
  }

  Future<void> _onGetOrders(
    GetOrdersEvent event,
    Emitter<ListOrderState> emit,
  ) async {
    if (event.loadMore) {
      final currentState = state;
      if (currentState is! ListOrderLoaded) return;

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

      result.fold(
        (l) {
          _detachRtdb();
          emit(ListOrderError(message: l.message));
        },
        (newOrders) {
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
          _attachRtdb(updatedOrders);
        },
      );
      return;
    }

    _detachRtdb();
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
      (orders) {
        emit(
          ListOrderLoaded(
            orders: orders,
            hasMore: orders.length == _pageSize,
            currentPage: 1,
            search: event.search,
            status: event.status,
            merchantId: event.merchantId,
          ),
        );
        _attachRtdb(orders);
      },
    );
  }

  void _onRtdbStatus(
    ListOrderRtdbStatusChanged event,
    Emitter<ListOrderState> emit,
  ) {
    final wire = event.statusWire.trim();
    if (wire.isEmpty) return;

    final s = state;
    if (s is ListOrderLoaded) {
      final updated = _patchOrderStatus(s.orders, event.orderId, wire);
      if (updated == null) return;
      emit(
        ListOrderLoaded(
          orders: updated,
          hasMore: s.hasMore,
          currentPage: s.currentPage,
          search: s.search,
          status: s.status,
          merchantId: s.merchantId,
        ),
      );
    } else if (s is ListOrderLoadingMore) {
      final updated = _patchOrderStatus(s.orders, event.orderId, wire);
      if (updated == null) return;
      emit(
        ListOrderLoadingMore(
          orders: updated,
          currentPage: s.currentPage,
          search: s.search,
          status: s.status,
          merchantId: s.merchantId,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _detachRtdb();
    return super.close();
  }
}

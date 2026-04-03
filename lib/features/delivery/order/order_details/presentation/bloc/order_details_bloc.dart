import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/features/delivery/order/order_details/data/repositories/order_details_repository.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

part 'order_details_event.dart';
part 'order_details_state.dart';

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  OrderDetailsBloc(this._repository, this._rtdb)
      : super(const OrderDetailsInitial()) {
    on<GetOrderDetailsEvent>(_onGetDetails);
    on<OrderDetailsRtdbStatusChanged>(_onRtdbStatus);
  }

  final OrderDetailsRepository _repository;
  final OrderStatusRtdbService _rtdb;
  StreamSubscription<String?>? _statusSub;

  Future<void> _onGetDetails(
    GetOrderDetailsEvent event,
    Emitter<OrderDetailsState> emit,
  ) async {
    await _statusSub?.cancel();
    _statusSub = null;
    emit(const OrderDetailsLoading());
    final result = await _repository.getOrderDetails(event.id);

    result.fold(
      (failure) => emit(OrderDetailsError(message: failure.message)),
      (order) {
        emit(OrderDetailsLoaded(order: order));
        _listenStatus(order.id);
      },
    );
  }

  void _listenStatus(String orderId) {
    _statusSub?.cancel();
    final id = orderId.trim();
    if (id.isEmpty) return;
    _statusSub = _rtdb.watchOrderStatusWire(id).listen(
      (wire) {
        final w = wire?.trim();
        if (w == null || w.isEmpty) return;
        add(OrderDetailsRtdbStatusChanged(w));
      },
      onError: (_) {},
    );
  }

  void _onRtdbStatus(
    OrderDetailsRtdbStatusChanged event,
    Emitter<OrderDetailsState> emit,
  ) {
    final s = state;
    if (s is! OrderDetailsLoaded) return;
    final w = event.statusWire.trim();
    if (w.isEmpty) return;
    final current = s.order.status ?? '';
    if (w.toUpperCase() == current.toUpperCase()) return;
    emit(OrderDetailsLoaded(order: s.order.copyWith(status: w)));
  }

  @override
  Future<void> close() {
    _statusSub?.cancel();
    return super.close();
  }
}

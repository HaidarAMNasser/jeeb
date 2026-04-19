import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/features/delivery/order/order_details/data/repositories/order_details_repository.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';
import 'package:jeeb_app/features/delivery/order/order_details/presentation/bloc/order_details_state.dart';

export 'order_details_state.dart';

part 'order_details_event.dart';

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  OrderDetailsBloc(this._repository, this._rtdb)
      : super(const OrderDetailsInitial()) {
    on<GetOrderDetailsEvent>(_onGetDetails);
    on<OrderDetailsRtdbStatusChanged>(_onRtdbStatus);
    on<CancelOrderEvent>(_onCancelOrder);
    on<ClearOrderDetailsTransientEvent>(_onClearTransient);
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

  Future<void> _onCancelOrder(
    CancelOrderEvent event,
    Emitter<OrderDetailsState> emit,
  ) async {
    final s = state;
    if (s is! OrderDetailsLoaded) return;
    final order = s.order;
    final status = OrderStatus.fromString(order.status);
    if (!status.canClientCancelOrder || s.isCancelling) return;

    emit(s.copyWith(isCancelling: true, clearActionError: true));

    final result = await _repository.cancelOrder(order.id);
    if (emit.isDone) return;

    final after = state;
    if (after is! OrderDetailsLoaded) return;

    result.fold(
      (failure) => emit(
        after.copyWith(isCancelling: false, actionError: failure.message),
      ),
      (_) => emit(
        after.copyWith(
          isCancelling: false,
          clearActionError: true,
          order: after.order.copyWith(
            status: OrderStatus.cancelled.apiWireValue,
          ),
        ),
      ),
    );
  }

  void _onClearTransient(
    ClearOrderDetailsTransientEvent event,
    Emitter<OrderDetailsState> emit,
  ) {
    final s = state;
    if (s is! OrderDetailsLoaded) return;
    if (s.actionError == null) return;
    emit(s.copyWith(clearActionError: true));
  }

  void _listenStatus(String orderId) {
    _statusSub?.cancel();
    final id = orderId.trim();
    if (id.isEmpty) return;
    _statusSub = _rtdb.watchOrderStatusWire(id).listen(
      (wire) {
        if (isClosed) return;
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
    emit(
      OrderDetailsLoaded(
        order: s.order.copyWith(status: w),
        isCancelling: s.isCancelling,
        actionError: s.actionError,
      ),
    );
  }

  @override
  Future<void> close() {
    _statusSub?.cancel();
    _statusSub = null;
    return super.close();
  }
}

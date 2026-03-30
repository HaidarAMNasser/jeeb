import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/order_status_step_index.dart';
import 'package:jeeb_app/features/basket/order_status_section/presentation/config/order_status_poll_config.dart';
import 'package:jeeb_app/features/delivery/order/order_details/data/repositories/order_details_repository.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

part 'order_status_event.dart';
part 'order_status_state.dart';

class OrderStatusBloc extends Bloc<OrderStatusEvent, OrderStatusState> {
  OrderStatusBloc({
    required String orderId,
    required OrderStatus initialStatus,
    required OrderDetailsRepository orderDetailsRepository,
  }) : _orderDetailsRepository = orderDetailsRepository,
       _lastPolledStatusWire = initialStatus.apiWireValue,
       super(OrderStatusState.initial(orderId, initialStatus)) {
    on<OrderStatusToggleDemo>(_onToggleDemo);
    on<OrderStatusDemoTick>(_onDemoTick);
    on<OrderStatusPollTick>(_onPollTick);
    _startStatusPolling();
  }

  final OrderDetailsRepository _orderDetailsRepository;

  /// Last `status` string from GET /orders/:id (uppercase). Detects changes [OrderStatus] might collapse.
  String _lastPolledStatusWire;

  Timer? _demoTimer;
  Timer? _pollTimer;

  static bool _isTerminalStatus(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
      case OrderStatus.completed:
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return true;
      default:
        return false;
    }
  }

  void _startStatusPolling() {
    if (_isTerminalStatus(state.routeStatus)) return;
    add(const OrderStatusPollTick());
    _pollTimer = Timer.periodic(OrderStatusPollConfig.interval, (_) {
      if (isClosed) return;
      add(const OrderStatusPollTick());
    });
  }

  void _stopStatusPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _onPollTick(
    OrderStatusPollTick event,
    Emitter<OrderStatusState> emit,
  ) async {
    if (_isTerminalStatus(state.routeStatus)) {
      _stopStatusPolling();
      return;
    }

    final result = await _orderDetailsRepository.getOrderDetails(state.orderId);
    if (isClosed) return;

    final order = result.fold<OrderEntity?>((_) => null, (r) => r);
    if (order == null) return;

    final wire = order.status?.trim();
    if (wire == null || wire.isEmpty) return;

    final normalized = wire.toUpperCase();
    if (normalized == _lastPolledStatusWire) {
      if (_isTerminalStatus(OrderStatus.fromString(wire))) {
        _stopStatusPolling();
      }
      return;
    }

    _lastPolledStatusWire = normalized;
    final next = OrderStatus.fromString(wire);

    emit(
      state.copyWith(
        routeStatus: next,
        liveStepIndex: OrderStatusState._staticTimelineIndex(next),
        demoRunning: false,
      ),
    );

    if (_isTerminalStatus(next)) {
      _stopStatusPolling();
    }
  }

  void _onToggleDemo(
    OrderStatusToggleDemo event,
    Emitter<OrderStatusState> emit,
  ) {
    if (state.demoRunning) {
      _demoTimer?.cancel();
      _demoTimer = null;
      emit(state.copyWith(demoRunning: false));
      return;
    }

    final start = OrderStatusState._staticTimelineIndex(state.routeStatus);
    _demoTimer?.cancel();
    emit(state.copyWith(demoRunning: true, liveStepIndex: start));
    _demoTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isClosed) return;
      add(const OrderStatusDemoTick());
    });
  }

  void _onDemoTick(OrderStatusDemoTick event, Emitter<OrderStatusState> emit) {
    if (!state.demoRunning) return;
    emit(state.copyWith(liveStepIndex: (state.liveStepIndex + 1) % 7));
  }

  @override
  Future<void> close() {
    _demoTimer?.cancel();
    _stopStatusPolling();
    return super.close();
  }
}

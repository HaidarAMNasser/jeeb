import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/common/utils/order_status_step_index.dart';
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';
import 'package:jeeb_app/features/delivery/order/order_details/data/repositories/order_details_repository.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

part 'order_status_event.dart';
part 'order_status_state.dart';

class OrderStatusBloc extends Bloc<OrderStatusEvent, OrderStatusState> {
  OrderStatusBloc({
    required String orderId,
    required OrderStatus initialStatus,
    required OrderStatusRtdbService orderStatusRtdb,
    required OrderDetailsRepository orderDetailsRepository,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryManName,
    String? deliveryManPhone,
  }) : _orderStatusRtdb = orderStatusRtdb,
       _orderDetailsRepository = orderDetailsRepository,
       _lastStatusWire = initialStatus.apiWireValue,
       super(
         OrderStatusState.initial(
           orderId,
           initialStatus,
           deliveryLatitude: deliveryLatitude,
           deliveryLongitude: deliveryLongitude,
           deliveryManName: deliveryManName,
           deliveryManPhone: deliveryManPhone,
         ),
       ) {
    on<OrderStatusToggleDemo>(_onToggleDemo);
    on<OrderStatusDemoTick>(_onDemoTick);
    on<OrderStatusRealtimeSnapshot>(_onRealtimeSnapshot);
    on<OrderStatusDriverLocationUpdated>(_onDriverLocationUpdated);
    on<OrderStatusDriverLocationCleared>(_onDriverLocationCleared);
    on<OrderStatusRouteHistorySnapshot>(_onRouteHistorySnapshot);
    on<OrderStatusHydrateDriverFromOrder>(_onHydrateDriverFromOrder);
    _startRealtimeListener();
    Future.microtask(() => add(const OrderStatusHydrateDriverFromOrder()));
  }

  final OrderStatusRtdbService _orderStatusRtdb;
  final OrderDetailsRepository _orderDetailsRepository;

  String _lastStatusWire;

  Timer? _demoTimer;
  StreamSubscription<String?>? _rtdbSub;
  StreamSubscription<int?>? _deliveryIdSub;
  StreamSubscription<DriverLiveLocation?>? _driverLocationSub;
  StreamSubscription<List<RouteHistoryPoint>>? _routeHistorySub;
  int? _lastDeliveryId;
  bool _driverHydrateInFlight = false;

  static bool _isTerminalStatus(OrderStatus s) {
    switch (s) {
      case OrderStatus.delivered:
      case OrderStatus.paid:
      case OrderStatus.completed:
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return true;
      default:
        return false;
    }
  }

  void _startRealtimeListener() {
    if (_isTerminalStatus(state.routeStatus)) return;
    _rtdbSub?.cancel();
    _rtdbSub = _orderStatusRtdb
        .watchOrderStatusWire(state.orderId)
        .listen(
          (wire) {
            if (isClosed) return;
            add(OrderStatusRealtimeSnapshot(wire));
          },
          onError: (_) {
            // RTDB errors are ignored; UI keeps last known status from route / previous events.
          },
        );

    _deliveryIdSub?.cancel();
    _deliveryIdSub = _orderStatusRtdb
        .watchOrderDeliveryId(state.orderId)
        .listen((deliveryId) {
          if (isClosed) return;
          _listenToDriverLocation(deliveryId);
        }, onError: (_) {});

    _routeHistorySub?.cancel();
    _routeHistorySub = _orderStatusRtdb
        .watchOrderRouteHistory(state.orderId)
        .listen(
          (points) {
            if (isClosed) return;
            add(OrderStatusRouteHistorySnapshot(points));
          },
          onError: (_) {},
        );
  }

  void _stopRealtimeListener() {
    _rtdbSub?.cancel();
    _rtdbSub = null;
    _deliveryIdSub?.cancel();
    _deliveryIdSub = null;
    _driverLocationSub?.cancel();
    _driverLocationSub = null;
    _routeHistorySub?.cancel();
    _routeHistorySub = null;
    _lastDeliveryId = null;
  }

  void _listenToDriverLocation(int? deliveryId) {
    if (deliveryId == null || deliveryId <= 0) {
      _driverLocationSub?.cancel();
      _driverLocationSub = null;
      _lastDeliveryId = null;
      if (!isClosed) add(const OrderStatusDriverLocationCleared());
      return;
    }
    if (_lastDeliveryId == deliveryId && _driverLocationSub != null) {
      return;
    }
    _lastDeliveryId = deliveryId;
    _driverLocationSub?.cancel();
    _driverLocationSub = _orderStatusRtdb
        .watchDriverLiveLocation(deliveryId)
        .listen((location) {
          if (isClosed || location == null) return;
          add(
            OrderStatusDriverLocationUpdated(
              latitude: location.latitude,
              longitude: location.longitude,
              isOnline: location.isOnline,
            ),
          );
        }, onError: (_) {});
  }

  void _onRealtimeSnapshot(
    OrderStatusRealtimeSnapshot event,
    Emitter<OrderStatusState> emit,
  ) {
    if (_isTerminalStatus(state.routeStatus)) {
      _stopRealtimeListener();
      return;
    }

    final wire = event.statusWire?.trim();
    if (wire == null || wire.isEmpty) return;

    final normalized = wire.toUpperCase();
    if (normalized == _lastStatusWire) {
      if (_isTerminalStatus(OrderStatus.fromString(wire))) {
        _stopRealtimeListener();
      }
      return;
    }

    _lastStatusWire = normalized;
    final next = OrderStatus.fromString(wire);

    emit(
      state.copyWith(
        routeStatus: next,
        liveStepIndex: OrderStatusState._staticTimelineIndex(next),
        demoRunning: false,
        clearDriverLocation: next != OrderStatus.onTheWay,
        clearRouteHistory: next != OrderStatus.onTheWay,
      ),
    );

    if (_isTerminalStatus(next)) {
      _stopRealtimeListener();
    } else if (orderStatusShowsDriverContact(next)) {
      Future.microtask(() => add(const OrderStatusHydrateDriverFromOrder()));
    }
  }

  Future<void> _onHydrateDriverFromOrder(
    OrderStatusHydrateDriverFromOrder event,
    Emitter<OrderStatusState> emit,
  ) async {
    if (_isTerminalStatus(state.routeStatus)) return;
    if (!orderStatusShowsDriverContact(state.routeStatus)) return;
    final needName = state.deliveryManName?.trim().isEmpty ?? true;
    final needPhone = state.deliveryManPhone?.trim().isEmpty ?? true;
    if (!needName && !needPhone) return;
    if (_driverHydrateInFlight) return;
    _driverHydrateInFlight = true;
    try {
      final result =
          await _orderDetailsRepository.getOrderDetails(state.orderId);
      if (isClosed) return;
      result.fold((_) {}, (order) {
        final dm = order.deliveryMan;
        if (dm == null) return;
        final n = dm.name.trim();
        final p = dm.phone.trim();
        var mergedName = state.deliveryManName;
        var mergedPhone = state.deliveryManPhone;
        if (needName && n.isNotEmpty) mergedName = n;
        if (needPhone && p.isNotEmpty) mergedPhone = p;
        if (mergedName == state.deliveryManName &&
            mergedPhone == state.deliveryManPhone) {
          return;
        }
        emit(
          state.copyWith(
            deliveryManName: mergedName,
            deliveryManPhone: mergedPhone,
          ),
        );
      });
    } finally {
      _driverHydrateInFlight = false;
    }
  }

  void _onDriverLocationUpdated(
    OrderStatusDriverLocationUpdated event,
    Emitter<OrderStatusState> emit,
  ) {
    emit(
      state.copyWith(
        driverLatitude: event.latitude,
        driverLongitude: event.longitude,
        driverOnline: event.isOnline,
      ),
    );
  }

  void _onDriverLocationCleared(
    OrderStatusDriverLocationCleared event,
    Emitter<OrderStatusState> emit,
  ) {
    emit(state.copyWith(clearDriverLocation: true));
  }

  void _onRouteHistorySnapshot(
    OrderStatusRouteHistorySnapshot event,
    Emitter<OrderStatusState> emit,
  ) {
    if (_isTerminalStatus(state.routeStatus)) return;
    emit(state.copyWith(routeHistoryPoints: event.points));
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
    emit(
      state.copyWith(
        liveStepIndex: (state.liveStepIndex + 1) % (kOrderTimelineStepMax + 1),
      ),
    );
  }

  @override
  Future<void> close() {
    _demoTimer?.cancel();
    _stopRealtimeListener();
    return super.close();
  }
}

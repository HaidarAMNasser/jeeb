import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/delivery/order/list_order/data/repositories/list_order_repository.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

part 'delivery_home_event.dart';
part 'delivery_home_state.dart';

/// Lower = more urgent for the driver's current run (map + primary card).
int _activeDeliveryPriority(OrderStatus s) {
  switch (s) {
    case OrderStatus.onTheWay:
      return 0;
    case OrderStatus.pickedUp:
      return 1;
    case OrderStatus.readyForPickup:
      return 2;
    case OrderStatus.assigned:
      return 3;
    case OrderStatus.preparing:
      return 4;
    case OrderStatus.delivered:
      return 5;
    case OrderStatus.paid:
      return 6;
    default:
      return 99;
  }
}

/// Pipeline pool: show PREPARING before SEARCHING when both exist.
int _pipelinePoolPriority(OrderStatus s) {
  switch (s) {
    case OrderStatus.preparing:
      return 0;
    case OrderStatus.searching:
      return 1;
    default:
      return 2;
  }
}

void _sortInPlaceBy<T>(
  List<T> items,
  int Function(T a) priority,
) {
  items.sort((a, b) => priority(a).compareTo(priority(b)));
}

class DeliveryHomeBloc extends Bloc<DeliveryHomeEvent, DeliveryHomeState> {
  final ListOrderRepository _repository;

  DeliveryHomeBloc(this._repository) : super(const DeliveryHomeInitial()) {
    on<LoadDeliveryHomeEvent>(_onLoadHome);
    on<RefreshDeliveryHomeEvent>(_onRefreshHome);
  }

  Future<void> _onLoadHome(
    LoadDeliveryHomeEvent event,
    Emitter<DeliveryHomeState> emit,
  ) async {
    emit(const DeliveryHomeLoading());
    await _fetchData(emit, markRefresh: false);
  }

  Future<void> _onRefreshHome(
    RefreshDeliveryHomeEvent event,
    Emitter<DeliveryHomeState> emit,
  ) async {
    await _fetchData(emit, markRefresh: true);
  }

  Future<void> _fetchData(
    Emitter<DeliveryHomeState> emit, {
    required bool markRefresh,
  }) async {
    // 1. Active delivery leg (driver run): assigned → onTheWay.
    final assignedResult = await _repository.getOrders(
      status: [
        OrderStatus.assigned,
        OrderStatus.preparing,
        OrderStatus.readyForPickup,
        OrderStatus.pickedUp,
        OrderStatus.onTheWay,
      ].map((s) => s.apiWireValue).join(','),
    );

    OrderEntity? assignedOrder;
    assignedResult.fold(
      (failure) => null, // Ignore failure for now, try available orders
      (orders) {
        if (orders.isNotEmpty) {
          final sorted = List<OrderEntity>.from(orders);
          _sortInPlaceBy(
            sorted,
            (o) => _activeDeliveryPriority(OrderStatus.fromString(o.status)),
          );
          assignedOrder = sorted.first;
        }
      },
    );

    // If assigned order exists, we don't need available orders according to requirements
    if (assignedOrder != null) {
      emit(DeliveryHomeLoaded(
        availableOrders: const [],
        assignedOrder: assignedOrder,
        refreshedAt: markRefresh ? DateTime.now() : null,
      ));
      return;
    }

    // 2. If no active run, show SEARCHING pool.
    final availableResult = await _repository.getOrders(
      status: [
        OrderStatus.searching,
      ].map((s) => s.apiWireValue).join(','),
    );

    availableResult.fold(
      (failure) => emit(DeliveryHomeError(message: failure.message)),
      (orders) {
        final sorted = List<OrderEntity>.from(orders);
        _sortInPlaceBy(
          sorted,
          (o) => _pipelinePoolPriority(OrderStatus.fromString(o.status)),
        );
        emit(DeliveryHomeLoaded(
          availableOrders: sorted,
          assignedOrder: null,
          refreshedAt: markRefresh ? DateTime.now() : null,
        ));
      },
    );
  }
}

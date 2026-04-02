import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/delivery/order/list_order/data/repositories/list_order_repository.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

part 'delivery_home_event.dart';
part 'delivery_home_state.dart';

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
    // 1. Fetch assigned orders (PICKED_UP or ASSIGNED)
    final assignedResult = await _repository.getOrders(
      status: '${OrderStatus.assigned.apiWireValue},${OrderStatus.pickedUp.apiWireValue}',
    );

    OrderEntity? assignedOrder;
    assignedResult.fold(
      (failure) => null, // Ignore failure for now, try available orders
      (orders) {
        if (orders.isNotEmpty) {
          assignedOrder = orders.first;
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

    // 2. Fetch available orders (SEARCHING)
    final availableResult = await _repository.getOrders(
      status: OrderStatus.searching.apiWireValue,
    );

    availableResult.fold(
      (failure) => emit(DeliveryHomeError(message: failure.message)),
      (orders) => emit(DeliveryHomeLoaded(
        availableOrders: orders,
        assignedOrder: null,
        refreshedAt: markRefresh ? DateTime.now() : null,
      )),
    );
  }
}

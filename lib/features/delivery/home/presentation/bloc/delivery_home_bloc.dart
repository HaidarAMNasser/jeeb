import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/order/list_order/data/repositories/list_order_repository.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

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
    final result = await _repository.getAvailableOrders();
    result.fold(
      (failure) => emit(DeliveryHomeError(message: failure.message)),
      (orders) => emit(DeliveryHomeLoaded(orders: orders)),
    );
  }

  Future<void> _onRefreshHome(
    RefreshDeliveryHomeEvent event,
    Emitter<DeliveryHomeState> emit,
  ) async {
    final result = await _repository.getAvailableOrders();
    result.fold(
      (failure) => emit(DeliveryHomeError(message: failure.message)),
      (orders) => emit(DeliveryHomeLoaded(orders: orders)),
    );
  }
}

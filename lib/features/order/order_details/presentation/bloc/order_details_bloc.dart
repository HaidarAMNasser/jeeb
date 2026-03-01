import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/order/order_details/data/repositories/order_details_repository.dart';

part 'order_details_event.dart';
part 'order_details_state.dart';

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  final OrderDetailsRepository _repository;

  OrderDetailsBloc(this._repository) : super(const OrderDetailsInitial()) {
    on<OrderDetailsEvent>((event, emit) async {
      if (event is GetOrderDetailsEvent) {
        emit(const OrderDetailsLoading());
        final result = await _repository.getOrderDetails(event.id);

        result.fold(
          (failure) => emit(OrderDetailsError(message: failure.message)),
          (order) => emit(OrderDetailsLoaded(order: order)),
        );
      }
    });
  }
}


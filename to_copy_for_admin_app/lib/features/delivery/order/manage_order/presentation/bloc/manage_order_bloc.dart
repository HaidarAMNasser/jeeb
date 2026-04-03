import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/data/repositories/manage_order_repository.dart';

part 'manage_order_event.dart';
part 'manage_order_state.dart';

class ManageOrderBloc extends Bloc<ManageOrderEvent, ManageOrderState> {
  final ManageOrderRepository _repository;

  ManageOrderBloc(this._repository) : super(const ManageOrderInitial()) {
    on<AcceptDeliveryEvent>(_onAcceptDelivery);
    on<ConfirmPickupEvent>(_onConfirmPickup);
    on<MarkAsDeliveredEvent>(_onMarkAsDelivered);
    on<RejectDeliveryEvent>(_onRejectDelivery);
  }

  Future<void> _onAcceptDelivery(
    AcceptDeliveryEvent event,
    Emitter<ManageOrderState> emit,
  ) async {
    emit(const ManageOrderLoading());
    final result = await _repository.acceptDelivery(
      event.id,
      event.deliveryTime,
    );
    result.fold(
      (failure) => emit(ManageOrderError(message: failure.message)),
      (_) => emit(
        const ManageOrderSuccess(message: 'Order assigned successfully'),
      ),
    );
  }

  Future<void> _onConfirmPickup(
    ConfirmPickupEvent event,
    Emitter<ManageOrderState> emit,
  ) async {
    emit(const ManageOrderLoading());
    final result = await _repository.confirmPickup(event.id, event.reason);
    result.fold(
      (failure) => emit(ManageOrderError(message: failure.message)),
      (_) => emit(
        const ManageOrderSuccess(message: 'Order picked up successfully'),
      ),
    );
  }

  Future<void> _onMarkAsDelivered(
    MarkAsDeliveredEvent event,
    Emitter<ManageOrderState> emit,
  ) async {
    emit(const ManageOrderLoading());
    final result = await _repository.markAsDelivered(
      id: event.id,
      reason: event.reason,
      lat: event.lat,
      lng: event.lng,
    );
    result.fold(
      (failure) => emit(ManageOrderError(message: failure.message)),
      (_) => emit(
        const ManageOrderSuccess(message: 'Order delivered successfully'),
      ),
    );
  }

  Future<void> _onRejectDelivery(
    RejectDeliveryEvent event,
    Emitter<ManageOrderState> emit,
  ) async {
    emit(const ManageOrderLoading());
    final result = await _repository.rejectDelivery(event.id, event.reason);
    result.fold(
      (failure) => emit(ManageOrderError(message: failure.message)),
      (_) => emit(
        const ManageOrderSuccess(message: 'Order released back to pool'),
      ),
    );
  }
}

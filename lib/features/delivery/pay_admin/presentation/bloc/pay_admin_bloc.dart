import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/delivery/pay_admin/data/repositories/pay_admin_repository.dart';

part 'pay_admin_event.dart';
part 'pay_admin_state.dart';

class PayAdminBloc extends Bloc<PayAdminEvent, PayAdminState> {
  PayAdminBloc(this._repository) : super(const PayAdminInitial()) {
    on<PayAdminSubmit>(_onSubmit);
    on<PayAdminReset>((_, emit) => emit(const PayAdminInitial()));
  }

  final PayAdminRepository _repository;

  Future<void> _onSubmit(
    PayAdminSubmit event,
    Emitter<PayAdminState> emit,
  ) async {
    emit(const PayAdminSubmitting());
    final result = await _repository.submitMediatorPaymentProof(
      orderIds: event.orderIds,
      receiptImagePath: event.receiptImagePath,
    );
    result.fold(
      (f) => emit(PayAdminFailureState(f.message)),
      (_) => emit(const PayAdminSuccess()),
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/auth/reset_password/data/repositories/reset_password_repository.dart';

part 'reset_password_event.dart';
part 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final ResetPasswordRepository _repository;

  ResetPasswordBloc(this._repository) : super(const ResetPasswordInitial()) {
    on<ResetPasswordEvent>(_onEvent);
  }

  Future<void> _onEvent(
      ResetPasswordEvent event, Emitter<ResetPasswordState> emit) async {
    if (event is ResetPasswordSubmitted) {
      emit(const ResetPasswordLoading());
      final result = await _repository.resetPassword(
        email: event.email,
        otp: event.otp,
        password: event.password,
      );
      result.fold(
        (f) => emit(ResetPasswordError(message: f.message)),
        (_) => emit(const ResetPasswordSuccess()),
      );
    }
  }
}

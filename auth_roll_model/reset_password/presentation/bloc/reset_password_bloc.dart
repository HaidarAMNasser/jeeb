import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/reset_password_repository.dart';

part 'reset_password_event.dart';
part 'reset_password_state.dart';

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  final ResetPasswordRepository _resetPasswordRepository;

  ResetPasswordBloc(this._resetPasswordRepository)
      : super(const ResetPasswordInitial()) {
    on<ResetPasswordEvent>((event, emit) async {
      if (event is ResetPasswordSubmitted) {
        emit(const ResetPasswordLoading());
        final result = await _resetPasswordRepository.resetPassword(
          email: event.email,
          otp: event.otp,
          password: event.password,
        );

        result.fold(
          (failure) => emit(ResetPasswordError(message: failure.message)),
          (_) => emit(const ResetPasswordSuccess()),
        );
      }
    });
  }
}


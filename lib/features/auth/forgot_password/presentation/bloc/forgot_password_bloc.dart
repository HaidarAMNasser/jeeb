import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/auth/forgot_password/data/repositories/forgot_password_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ForgotPasswordRepository _repository;

  ForgotPasswordBloc(this._repository) : super(const ForgotPasswordInitial()) {
    on<ForgotPasswordEvent>(_onEvent);
  }

  Future<void> _onEvent(
      ForgotPasswordEvent event, Emitter<ForgotPasswordState> emit) async {
    if (event is ForgotPasswordSubmitted) {
      emit(const ForgotPasswordLoading());
      final result =
          await _repository.forgotPassword(email: event.email);
      result.fold(
        (f) => emit(ForgotPasswordError(message: f.message)),
        (_) => emit(ForgotPasswordSuccess(email: event.email)),
      );
    }
  }
}

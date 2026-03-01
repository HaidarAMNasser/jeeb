import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/forgot_password_repository.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ForgotPasswordRepository _forgotPasswordRepository;

  ForgotPasswordBloc(this._forgotPasswordRepository)
      : super(const ForgotPasswordInitial()) {
    on<ForgotPasswordEvent>((event, emit) async {
      if (event is ForgotPasswordSubmitted) {
        emit(const ForgotPasswordLoading());
        final result =
            await _forgotPasswordRepository.forgotPassword(email: event.email);

        result.fold(
          (failure) => emit(ForgotPasswordError(message: failure.message)),
          (_) => emit(ForgotPasswordSuccess(email: event.email)),
        );
      }
    });
  }
}


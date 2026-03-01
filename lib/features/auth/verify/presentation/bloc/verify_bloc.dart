import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/verify_repository.dart';

part 'verify_event.dart';
part 'verify_state.dart';

class VerifyBloc extends Bloc<VerifyEvent, VerifyState> {
  final VerifyRepository _verifyRepository;

  VerifyBloc(this._verifyRepository) : super(const VerifyInitial()) {
    on<VerifyEvent>((event, emit) async {
      if (event is VerifySubmitted) {
        emit(const VerifyLoading());
        final result = await _verifyRepository.verify(
          email: event.email,
          otp: event.otp,
        );

        result.fold(
          (failure) => emit(VerifyError(message: failure.message)),
          (_) => emit(const VerifySuccess()),
        );
      } else if (event is ResendOtpSubmitted) {
        emit(const VerifyLoading());
        final result = await _verifyRepository.resendOtp(email: event.email);

        result.fold(
          (failure) => emit(VerifyError(message: failure.message)),
          (_) => emit(const VerifyOtpResent()),
        );
      }
    });
  }
}


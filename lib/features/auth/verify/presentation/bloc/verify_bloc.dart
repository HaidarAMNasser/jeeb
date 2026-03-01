import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/auth/verify/data/repositories/verify_repository.dart';

part 'verify_event.dart';
part 'verify_state.dart';

class VerifyBloc extends Bloc<VerifyEvent, VerifyState> {
  final VerifyRepository _repository;

  VerifyBloc(this._repository) : super(const VerifyInitial()) {
    on<VerifyEvent>(_onEvent);
  }

  Future<void> _onEvent(VerifyEvent event, Emitter<VerifyState> emit) async {
    if (event is VerifySubmitted) {
      emit(const VerifyLoading());
      final result =
          await _repository.verify(email: event.email, otp: event.otp);
      result.fold(
        (f) => emit(VerifyError(message: f.message)),
        (_) => emit(const VerifySuccess()),
      );
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/auth/register/data/repositories/register_repository.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterRepository _repository;

  RegisterBloc(this._repository) : super(const RegisterInitial()) {
    on<RegisterEvent>(_onEvent);
  }

  Future<void> _onEvent(RegisterEvent event, Emitter<RegisterState> emit) async {
    if (event is RegisterSubmitted) {
      emit(const RegisterLoading());
      final result = await _repository.register(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        password: event.password,
        phone: event.phone,
        role: event.role,
        countryId: event.countryId,
        cityId: event.cityId,
        address: event.address,
        notificationChannel: event.notificationChannel,
      );
      result.fold(
        (f) => emit(RegisterError(message: f.message)),
        (_) => emit(const RegisterSuccess()),
      );
    }
  }
}

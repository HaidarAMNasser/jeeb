import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/register_repository.dart';

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterRepository _registerRepository;

  RegisterBloc(this._registerRepository) : super(const RegisterInitial()) {
    on<RegisterEvent>((event, emit) async {
      if (event is RegisterSubmitted) {
        emit(const RegisterLoading());
        final result = await _registerRepository.register(
          firstName: event.firstName,
          lastName: event.lastName,
          email: event.email,
          password: event.password,
          phone: event.phone,
          role: event.role,
          countryId: event.countryId,
          cityId: event.cityId,
          notificationChannel: event.notificationChannel,
          address: event.address,
        );

        result.fold(
          (failure) => emit(RegisterError(message: failure.message)),
          (userId) => emit(RegisterSuccess(userId: userId, email: event.email)),
        );
      }
    });
  }
}


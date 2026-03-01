import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/features/auth/login/data/repositories/login_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository _loginRepository;
  final StorageService _storageService;

  LoginBloc(this._loginRepository, this._storageService)
      : super(const LoginInitial()) {
    on<LoginEvent>(_onEvent);
  }

  Future<void> _onEvent(LoginEvent event, Emitter<LoginState> emit) async {
    if (event is LoginSubmitted) {
      emit(const LoginLoading());
      final result = await _loginRepository.login(
        email: event.email,
        password: event.password,
      );

      result.fold(
        (failure) => emit(LoginError(message: failure.message)),
        (tokenEntity) async {
          await _storageService.clearStorage(clearAuthParams: true);
          await _storageService.setUserToken(tokenEntity.accessToken);
          await _storageService.setUserRole(tokenEntity.user.role.name);
          emit(const LoginSuccess());
        },
      );
    }
  }
}

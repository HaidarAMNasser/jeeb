import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/infrastructure/services/storage_service.dart';
import '../../data/repositories/login_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository _loginRepository;
  final StorageService _storageService;

  LoginBloc(
    this._loginRepository,
    this._storageService,
  ) : super(const LoginInitial()) {
    on<LoginEvent>((event, emit) async {
      if (event is LoginSubmitted) {
        emit(const LoginLoading());
        final result = await _loginRepository.login(
          email: event.email,
          password: event.password,
        );

        result.fold(
          (failure) => emit(LoginError(message: failure.message)),
          (tokenEntity) async {
            // Store token
            await _storageService.setUserToken(tokenEntity.accessToken);
            // Store user role
            await _storageService.setUserRole(tokenEntity.user.role.name);
            emit(const LoginSuccess());
          },
        );
      }
    });
  }
}


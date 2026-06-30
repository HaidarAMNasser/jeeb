import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/common/errors/failure.dart';
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
    on<LoginSubmitted>((event, emit) async {
      emit(const LoginLoading());

      final result = event.usePhone
          ? await _loginRepository.loginWithPhone(
              phone: event.phone!.trim(),
              password: event.password,
            )
          : await _loginRepository.login(
              email: event.email!.trim(),
              password: event.password,
            );

      await result.fold(
        (failure) async {
          if (emit.isDone) return;
          if (failure is UnauthorizedFailure &&
              failure.message.toLowerCase().contains('not verified')) {
            emit(
              LoginNeedsVerification(
                email: event.usePhone ? '' : event.email!.trim(),
                phone: event.usePhone ? event.phone!.trim() : '',
                isCustomerPhone: event.usePhone,
              ),
            );
            return;
          }
          emit(LoginError(message: failure.message));
        },
        (tokenEntity) async {
          await _storageService.setUserToken(tokenEntity.accessToken);
          await _storageService.setUserId(tokenEntity.user.id);
          await _storageService.setUserRole(tokenEntity.user.role.name);

          if (tokenEntity.user.isVerified) {
            await _storageService.setLoggedIn(true);
            await _storageService.setVerified(true);
            await _storageService.setPendingVerifyEmail(null);
            if (emit.isDone) return;
            emit(const LoginSuccess());
          } else {
            if (event.usePhone) {
              await _storageService.setPendingVerifyEmail(null);
              if (emit.isDone) return;
              emit(
                LoginNeedsVerification(
                  phone: event.phone!.trim(),
                  isCustomerPhone: true,
                ),
              );
            } else {
              await _storageService.setPendingVerifyEmail(
                tokenEntity.user.email,
              );
              if (emit.isDone) return;
              emit(LoginNeedsVerification(email: tokenEntity.user.email));
            }
          }
        },
      );
    });
  }
}


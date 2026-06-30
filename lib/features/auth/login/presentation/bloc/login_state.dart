part of 'login_bloc.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess();
}

class LoginNeedsVerification extends LoginState {
  final String email;
  final String phone;
  final bool isCustomerPhone;

  const LoginNeedsVerification({
    this.email = '',
    this.phone = '',
    this.isCustomerPhone = false,
  });

  @override
  List<Object?> get props => [email, phone, isCustomerPhone];
}

class LoginError extends LoginState {
  final String message;

  const LoginError({required this.message});

  @override
  List<Object> get props => [message];
}


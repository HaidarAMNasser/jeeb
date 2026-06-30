part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends LoginEvent {
  final String password;
  final String? email;
  final String? phone;
  final bool usePhone;

  const LoginSubmitted({
    required this.password,
    this.email,
    this.phone,
    this.usePhone = false,
  });

  @override
  List<Object?> get props => [password, email, phone, usePhone];
}


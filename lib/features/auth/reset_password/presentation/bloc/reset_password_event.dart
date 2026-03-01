part of 'reset_password_bloc.dart';

abstract class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();
  @override
  List<Object?> get props => [];
}

class ResetPasswordSubmitted extends ResetPasswordEvent {
  final String email;
  final String otp;
  final String password;
  const ResetPasswordSubmitted({
    required this.email,
    required this.otp,
    required this.password,
  });
  @override
  List<Object> get props => [email, otp, password];
}

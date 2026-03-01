part of 'verify_bloc.dart';

abstract class VerifyEvent extends Equatable {
  const VerifyEvent();

  @override
  List<Object?> get props => [];
}

class VerifySubmitted extends VerifyEvent {
  final String email;
  final String otp;

  const VerifySubmitted({
    required this.email,
    required this.otp,
  });

  @override
  List<Object> get props => [email, otp];
}

class ResendOtpSubmitted extends VerifyEvent {
  final String email;

  const ResendOtpSubmitted({required this.email});

  @override
  List<Object> get props => [email];
}


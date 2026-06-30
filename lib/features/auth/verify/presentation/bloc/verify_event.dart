part of 'verify_bloc.dart';

abstract class VerifyEvent extends Equatable {
  const VerifyEvent();

  @override
  List<Object?> get props => [];
}

class VerifySubmitted extends VerifyEvent {
  final String email;
  final String otp;

  /// When true (driver registration → OTP), go to delivery waiting without relying on the profile API.
  final bool expectDeliveryWaiting;

  const VerifySubmitted({
    required this.email,
    required this.otp,
    this.expectDeliveryWaiting = false,
  });

  @override
  List<Object> get props => [email, otp, expectDeliveryWaiting];
}

class ResendOtpSubmitted extends VerifyEvent {
  final String email;

  const ResendOtpSubmitted({required this.email});

  @override
  List<Object> get props => [email];
}

/// Client (customer) sign-up phone OTP verification.
class VerifyCustomerPhoneSubmitted extends VerifyEvent {
  final String phone;
  final String otp;

  const VerifyCustomerPhoneSubmitted({required this.phone, required this.otp});

  @override
  List<Object> get props => [phone, otp];
}


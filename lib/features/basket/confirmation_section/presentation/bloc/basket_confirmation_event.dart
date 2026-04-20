import 'package:equatable/equatable.dart';

abstract class BasketConfirmationEvent extends Equatable {
  const BasketConfirmationEvent();

  @override
  List<Object?> get props => [];
}

/// Kicks off parallel profile load + reverse geocode.
class BasketConfirmationStarted extends BasketConfirmationEvent {
  const BasketConfirmationStarted();
}

class BasketConfirmationNameChanged extends BasketConfirmationEvent {
  final String name;

  const BasketConfirmationNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

class BasketConfirmationStreetChanged extends BasketConfirmationEvent {
  final String street;

  const BasketConfirmationStreetChanged(this.street);

  @override
  List<Object?> get props => [street];
}

class BasketConfirmationAddressDetailsChanged extends BasketConfirmationEvent {
  final String addressDetails;

  const BasketConfirmationAddressDetailsChanged(this.addressDetails);

  @override
  List<Object?> get props => [addressDetails];
}

class BasketConfirmationPhoneChanged extends BasketConfirmationEvent {
  final String phone;

  const BasketConfirmationPhoneChanged(this.phone);

  @override
  List<Object?> get props => [phone];
}

class BasketConfirmationLocationPicked extends BasketConfirmationEvent {
  final double latitude;
  final double longitude;

  const BasketConfirmationLocationPicked({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}

class BasketConfirmationSubmitRequested extends BasketConfirmationEvent {
  const BasketConfirmationSubmitRequested();
}

/// UI applied [BasketConfirmationState.pendingFieldSync] to controllers.
class BasketConfirmationFieldSyncConsumed extends BasketConfirmationEvent {
  const BasketConfirmationFieldSyncConsumed();
}

/// UI handled post-create order success side effects (clear cart, etc).
class BasketConfirmationSuccessHandled extends BasketConfirmationEvent {
  const BasketConfirmationSuccessHandled();
}

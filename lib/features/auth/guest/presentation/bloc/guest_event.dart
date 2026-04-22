part of 'guest_bloc.dart';

abstract class GuestEvent extends Equatable {
  const GuestEvent();

  @override
  List<Object?> get props => [];
}

class GuestLoginSubmitted extends GuestEvent {
  const GuestLoginSubmitted();
}

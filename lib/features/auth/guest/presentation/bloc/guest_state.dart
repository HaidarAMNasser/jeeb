part of 'guest_bloc.dart';

abstract class GuestState extends Equatable {
  const GuestState();

  @override
  List<Object?> get props => [];
}

class GuestInitial extends GuestState {
  const GuestInitial();
}

class GuestLoading extends GuestState {
  const GuestLoading();
}

class GuestSuccess extends GuestState {
  const GuestSuccess();
}

class GuestError extends GuestState {
  final String message;

  const GuestError({required this.message});

  @override
  List<Object> get props => [message];
}

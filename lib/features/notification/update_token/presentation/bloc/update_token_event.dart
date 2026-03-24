part of 'update_token_bloc.dart';

sealed class UpdateTokenEvent extends Equatable {
  const UpdateTokenEvent();

  @override
  List<Object?> get props => [];
}

class UpdateTokenInitializeRequested extends UpdateTokenEvent {
  const UpdateTokenInitializeRequested();
}

class UpdateTokenLoginSucceeded extends UpdateTokenEvent {
  const UpdateTokenLoginSucceeded();
}

class UpdateTokenReceived extends UpdateTokenEvent {
  final String token;

  const UpdateTokenReceived(this.token);

  @override
  List<Object?> get props => [token];
}

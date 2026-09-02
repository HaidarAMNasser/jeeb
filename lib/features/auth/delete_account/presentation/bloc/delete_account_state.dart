part of 'delete_account_bloc.dart';

abstract class DeleteAccountState extends Equatable {
  const DeleteAccountState();

  @override
  List<Object?> get props => [];
}

class DeleteAccountInitial extends DeleteAccountState {
  const DeleteAccountInitial();
}

class DeleteAccountLoading extends DeleteAccountState {
  const DeleteAccountLoading();
}

class DeleteAccountSuccess extends DeleteAccountState {
  const DeleteAccountSuccess();
}

class DeleteAccountError extends DeleteAccountState {
  final String message;

  const DeleteAccountError({required this.message});

  @override
  List<Object> get props => [message];
}

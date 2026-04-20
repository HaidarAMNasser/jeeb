part of 'pay_admin_bloc.dart';

sealed class PayAdminState extends Equatable {
  const PayAdminState();

  @override
  List<Object?> get props => [];
}

final class PayAdminInitial extends PayAdminState {
  const PayAdminInitial();
}

final class PayAdminSubmitting extends PayAdminState {
  const PayAdminSubmitting();
}

final class PayAdminSuccess extends PayAdminState {
  const PayAdminSuccess();
}

final class PayAdminFailureState extends PayAdminState {
  const PayAdminFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

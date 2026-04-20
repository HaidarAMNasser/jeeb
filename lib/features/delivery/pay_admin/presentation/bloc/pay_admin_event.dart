part of 'pay_admin_bloc.dart';

sealed class PayAdminEvent extends Equatable {
  const PayAdminEvent();

  @override
  List<Object?> get props => [];
}

final class PayAdminSubmit extends PayAdminEvent {
  const PayAdminSubmit({
    required this.orderIds,
    required this.receiptImagePath,
  });

  final List<String> orderIds;
  final String receiptImagePath;

  @override
  List<Object?> get props => [orderIds, receiptImagePath];
}

final class PayAdminReset extends PayAdminEvent {
  const PayAdminReset();
}

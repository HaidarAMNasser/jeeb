part of 'order_before_confirm_bloc.dart';

abstract class OrderBeforeConfirmState extends Equatable {
  const OrderBeforeConfirmState();

  @override
  List<Object?> get props => [];
}

class OrderBeforeConfirmInitial extends OrderBeforeConfirmState {
  const OrderBeforeConfirmInitial();
}

class OrderBeforeConfirmLoading extends OrderBeforeConfirmState {
  const OrderBeforeConfirmLoading();
}

class OrderBeforeConfirmSuccess extends OrderBeforeConfirmState {
  const OrderBeforeConfirmSuccess(this.preview);

  final OrderBeforeConfirmPreview preview;

  @override
  List<Object?> get props => [preview];
}

class OrderBeforeConfirmFailure extends OrderBeforeConfirmState {
  const OrderBeforeConfirmFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

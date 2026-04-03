part of 'order_before_confirm_bloc.dart';

abstract class OrderBeforeConfirmEvent extends Equatable {
  const OrderBeforeConfirmEvent();

  @override
  List<Object?> get props => [];
}

class FetchOrderDataBeforeConfirm extends OrderBeforeConfirmEvent {
  const FetchOrderDataBeforeConfirm({
    required this.merchantId,
    required this.latitude,
    required this.longitude,
    required this.products,
  });

  final int merchantId;
  final double latitude;
  final double longitude;
  final List<OrderBeforeConfirmProductRequest> products;

  @override
  List<Object?> get props => [merchantId, latitude, longitude, products];
}

class OrderBeforeConfirmReset extends OrderBeforeConfirmEvent {
  const OrderBeforeConfirmReset();
}

part of 'manage_order_bloc.dart';

abstract class ManageOrderEvent extends Equatable {
  const ManageOrderEvent();

  @override
  List<Object?> get props => [];
}

class AcceptDeliveryEvent extends ManageOrderEvent {
  final String id;
  final int deliveryTime;

  const AcceptDeliveryEvent({
    required this.id,
    required this.deliveryTime,
  });

  @override
  List<Object?> get props => [id, deliveryTime];
}

class ConfirmPickupEvent extends ManageOrderEvent {
  final String id;
  final String reason;

  const ConfirmPickupEvent({
    required this.id,
    required this.reason,
  });

  @override
  List<Object?> get props => [id, reason];
}

class MarkOnTheWayEvent extends ManageOrderEvent {
  final String id;
  final String reason;

  const MarkOnTheWayEvent({
    required this.id,
    required this.reason,
  });

  @override
  List<Object?> get props => [id, reason];
}

class MarkAsDeliveredEvent extends ManageOrderEvent {
  final String id;
  final String reason;
  final double lat;
  final double lng;

  const MarkAsDeliveredEvent({
    required this.id,
    required this.reason,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [id, reason, lat, lng];
}

class RejectDeliveryEvent extends ManageOrderEvent {
  final String id;
  final String reason;

  const RejectDeliveryEvent({
    required this.id,
    required this.reason,
  });

  @override
  List<Object?> get props => [id, reason];
}

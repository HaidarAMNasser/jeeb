part of 'delivery_home_bloc.dart';

abstract class DeliveryHomeEvent extends Equatable {
  const DeliveryHomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadDeliveryHomeEvent extends DeliveryHomeEvent {
  const LoadDeliveryHomeEvent();
}

class RefreshDeliveryHomeEvent extends DeliveryHomeEvent {
  const RefreshDeliveryHomeEvent();
}

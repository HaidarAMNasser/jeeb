part of 'offer_details_bloc.dart';

abstract class OfferDetailsEvent extends Equatable {
  const OfferDetailsEvent();

  @override
  List<Object> get props => [];
}

class GetOfferDetailsEvent extends OfferDetailsEvent {
  final String id;

  const GetOfferDetailsEvent({required this.id});

  @override
  List<Object> get props => [id];
}

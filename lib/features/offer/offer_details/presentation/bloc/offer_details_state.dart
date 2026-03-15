part of 'offer_details_bloc.dart';

abstract class OfferDetailsState extends Equatable {
  const OfferDetailsState();

  @override
  List<Object?> get props => [];
}

class OfferDetailsInitial extends OfferDetailsState {
  const OfferDetailsInitial();
}

class OfferDetailsLoading extends OfferDetailsState {
  const OfferDetailsLoading();
}

class OfferDetailsLoaded extends OfferDetailsState {
  final OfferEntity offer;

  const OfferDetailsLoaded({required this.offer});

  @override
  List<Object?> get props => [offer];
}

class OfferDetailsError extends OfferDetailsState {
  final String message;

  const OfferDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

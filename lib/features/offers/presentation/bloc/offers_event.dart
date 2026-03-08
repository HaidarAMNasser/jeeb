part of 'offers_bloc.dart';

abstract class OffersEvent extends Equatable {
  const OffersEvent();

  @override
  List<Object?> get props => [];
}

class FetchOffers extends OffersEvent {
  final String? search;
  final bool? isActive;
  final String? merchantId;

  const FetchOffers({
    this.search,
    this.isActive,
    this.merchantId,
  });

  @override
  List<Object?> get props => [search, isActive, merchantId];
}

class LoadMoreOffers extends OffersEvent {
  final String? search;
  final bool? isActive;
  final String? merchantId;

  const LoadMoreOffers({
    this.search,
    this.isActive,
    this.merchantId,
  });

  @override
  List<Object?> get props => [search, isActive, merchantId];
}

part of 'list_offer_bloc.dart';

abstract class ListOfferEvent extends Equatable {
  const ListOfferEvent();

  @override
  List<Object?> get props => [];
}

class GetOffersEvent extends ListOfferEvent {
  final bool loadMore;
  final String? merchantId;

  const GetOffersEvent({this.loadMore = false, this.merchantId});

  @override
  List<Object?> get props => [loadMore, merchantId];
}

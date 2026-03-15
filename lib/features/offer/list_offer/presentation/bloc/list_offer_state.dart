part of 'list_offer_bloc.dart';

abstract class ListOfferState extends Equatable {
  const ListOfferState();

  @override
  List<Object?> get props => [];
}

class ListOfferInitial extends ListOfferState {
  const ListOfferInitial();
}

class ListOfferLoading extends ListOfferState {
  const ListOfferLoading();
}

class ListOfferLoaded extends ListOfferState {
  final List<OfferEntity> offers;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final String? merchantId;

  const ListOfferLoaded({
    required this.offers,
    this.hasMore = true,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.merchantId,
  });

  ListOfferLoaded copyWith({
    List<OfferEntity>? offers,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    String? merchantId,
  }) {
    return ListOfferLoaded(
      offers: offers ?? this.offers,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      merchantId: merchantId ?? this.merchantId,
    );
  }

  @override
  List<Object?> get props => [offers, hasMore, currentPage, isLoadingMore, merchantId];
}

class ListOfferLoadingMore extends ListOfferState {
  final List<OfferEntity> offers;
  final int currentPage;

  const ListOfferLoadingMore({
    required this.offers,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [offers, currentPage];
}

class ListOfferError extends ListOfferState {
  final String message;

  const ListOfferError({required this.message});

  @override
  List<Object?> get props => [message];
}

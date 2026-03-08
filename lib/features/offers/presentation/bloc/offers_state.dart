part of 'offers_bloc.dart';

abstract class OffersState extends Equatable {
  const OffersState();

  @override
  List<Object?> get props => [];
}

class OffersStateInitial extends OffersState {
  const OffersStateInitial();
}

class OffersStateLoading extends OffersState {
  const OffersStateLoading();
}

class OffersStateLoaded extends OffersState {
  final List<OfferEntity> offers;
  final PaginationEntity pagination;
  final bool hasReachedMax;

  const OffersStateLoaded({
    required this.offers,
    required this.pagination,
    required this.hasReachedMax,
  });

  @override
  List<Object?> get props => [offers, pagination, hasReachedMax];

  OffersStateLoaded copyWith({
    List<OfferEntity>? offers,
    PaginationEntity? pagination,
    bool? hasReachedMax,
  }) {
    return OffersStateLoaded(
      offers: offers ?? this.offers,
      pagination: pagination ?? this.pagination,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class OffersStateError extends OffersState {
  final String message;

  const OffersStateError(this.message);

  @override
  List<Object?> get props => [message];
}

class OffersStateLoadingMore extends OffersState {
  final List<OfferEntity> offers;
  final PaginationEntity pagination;

  const OffersStateLoadingMore({
    required this.offers,
    required this.pagination,
  });

  @override
  List<Object?> get props => [offers, pagination];
}

// Extension for convenience
extension OffersStateX on OffersState {
  bool get isInitial => this is OffersStateInitial;
  bool get isLoading => this is OffersStateLoading;
  bool get isLoadingMore => this is OffersStateLoadingMore;
  bool get isLoaded => this is OffersStateLoaded;
  bool get isError => this is OffersStateError;

  OffersStateLoaded? get asLoaded =>
      isLoaded ? this as OffersStateLoaded : null;
  OffersStateError? get asError => isError ? this as OffersStateError : null;
}

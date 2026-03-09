part of 'list_merchant_bloc.dart';

abstract class ListMerchantState extends Equatable {
  const ListMerchantState();

  @override
  List<Object?> get props => [];
}

class ListMerchantInitial extends ListMerchantState {
  const ListMerchantInitial();
}

class ListMerchantLoading extends ListMerchantState {
  const ListMerchantLoading();
}

class ListMerchantLoaded extends ListMerchantState {
  final List<MerchantEntity> merchants;
  final bool hasMore;
  final int currentPage;
  final String? search;
  final Set<String> favoriteMerchantIds;

  const ListMerchantLoaded({
    required this.merchants,
    this.hasMore = true,
    this.currentPage = 1,
    this.search,
    this.favoriteMerchantIds = const {},
  });

  @override
  List<Object?> get props => [merchants, hasMore, currentPage, search, favoriteMerchantIds];
}

class ListMerchantError extends ListMerchantState {
  final String message;

  const ListMerchantError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ListMerchantLoadingMore extends ListMerchantState {
  final List<MerchantEntity> merchants;
  final int currentPage;
  final String? search;
  final Set<String> favoriteMerchantIds;

  const ListMerchantLoadingMore({
    required this.merchants,
    required this.currentPage,
    this.search,
    this.favoriteMerchantIds = const {},
  });

  @override
  List<Object?> get props => [merchants, currentPage, search, favoriteMerchantIds];
}


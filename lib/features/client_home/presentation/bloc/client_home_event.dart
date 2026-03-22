import 'package:equatable/equatable.dart';

abstract class ClientHomeEvent extends Equatable {
  const ClientHomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadClientHomeEvent extends ClientHomeEvent {
  const LoadClientHomeEvent();
}

class SelectCategoryEvent extends ClientHomeEvent {
  final String? categoryId;
  const SelectCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class SearchProductsEvent extends ClientHomeEvent {
  final String? query;
  const SearchProductsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class RefreshClientHomeEvent extends ClientHomeEvent {
  const RefreshClientHomeEvent();
}

class ApplyFiltersEvent extends ClientHomeEvent {
  final double? minPrice;
  final double? maxPrice;
  final int? minRating;
  final String? categoryId;

  const ApplyFiltersEvent({
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.categoryId,
  });

  @override
  List<Object?> get props => [minPrice, maxPrice, minRating, categoryId];
}

class LoadMoreProductsEvent extends ClientHomeEvent {
  const LoadMoreProductsEvent();
}

class GlobalSearchEvent extends ClientHomeEvent {
  final String query;
  const GlobalSearchEvent(this.query);

  @override
  List<Object?> get props => [query];
}

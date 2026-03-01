part of 'country_bloc.dart';

abstract class CountryEvent extends Equatable {
  const CountryEvent();

  @override
  List<Object> get props => [];
}

class LoadCountries extends CountryEvent {
  final bool withLoading;
  final String? searchText;
  final bool? isFiltered;

  const LoadCountries({
    this.withLoading = false,
    this.searchText,
    this.isFiltered,
  });

  @override
  List<Object> get props => [withLoading, searchText ?? '', isFiltered ?? false];
}

class LoadMoreCountries extends CountryEvent {
  const LoadMoreCountries();
}


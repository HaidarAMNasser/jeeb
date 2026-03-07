part of 'city_bloc.dart';

abstract class CityEvent extends Equatable {
  const CityEvent();

  @override
  List<Object> get props => [];
}

class LoadCities extends CityEvent {
  final int countryId;
  final bool withLoading;
  final String? searchText;
  final bool? isFiltered;

  const LoadCities({
    required this.countryId,
    this.withLoading = false,
    this.searchText,
    this.isFiltered,
  });

  @override
  List<Object> get props => [countryId, withLoading, searchText ?? '', isFiltered ?? false];
}

class LoadMoreCities extends CityEvent {
  const LoadMoreCities();
}

class ResetCities extends CityEvent {
  const ResetCities();
}


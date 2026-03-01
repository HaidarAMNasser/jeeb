part of 'country_bloc.dart';

abstract class CountryState extends Equatable {
  const CountryState();

  @override
  List<Object> get props => [];
}

class CountryInitial extends CountryState {}

class CountryLoading extends CountryState {}

class CountryLoaded extends CountryState {
  final List<CountryEntity> countries;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final int page;
  final bool? isFiltered;
  final String? currentSearchText;

  const CountryLoaded({
    required this.countries,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.page = 1,
    this.isFiltered,
    this.currentSearchText,
  });

  CountryLoaded copyWith({
    List<CountryEntity>? countries,
    bool? isLoadingMore,
    bool? hasReachedMax,
    int? page,
    bool? isFiltered,
    String? currentSearchText,
  }) {
    return CountryLoaded(
      countries: countries ?? this.countries,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      isFiltered: isFiltered ?? this.isFiltered,
      currentSearchText: currentSearchText ?? this.currentSearchText,
    );
  }

  @override
  List<Object> get props => [
        countries,
        isLoadingMore,
        hasReachedMax,
        page,
        isFiltered ?? false,
        currentSearchText ?? '',
      ];
}

class CountryError extends CountryState {
  final String message;

  const CountryError({required this.message});

  @override
  List<Object> get props => [message];
}


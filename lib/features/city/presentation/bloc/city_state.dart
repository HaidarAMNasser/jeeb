part of 'city_bloc.dart';

abstract class CityState extends Equatable {
  const CityState();

  @override
  List<Object> get props => [];
}

class CityInitial extends CityState {}

class CityLoading extends CityState {}

class CityLoaded extends CityState {
  final List<CityEntity> cities;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final int page;
  final bool? isFiltered;
  final String? currentSearchText;

  const CityLoaded({
    required this.cities,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.page = 1,
    this.isFiltered,
    this.currentSearchText,
  });

  CityLoaded copyWith({
    List<CityEntity>? cities,
    bool? isLoadingMore,
    bool? hasReachedMax,
    int? page,
    bool? isFiltered,
    String? currentSearchText,
  }) {
    return CityLoaded(
      cities: cities ?? this.cities,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      isFiltered: isFiltered ?? this.isFiltered,
      currentSearchText: currentSearchText ?? this.currentSearchText,
    );
  }

  @override
  List<Object> get props => [
        cities,
        isLoadingMore,
        hasReachedMax,
        page,
        isFiltered ?? false,
        currentSearchText ?? '',
      ];
}

class CityError extends CityState {
  final String message;

  const CityError({required this.message});

  @override
  List<Object> get props => [message];
}


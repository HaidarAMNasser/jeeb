import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/city/data/repositories/city_repository.dart';
import 'package:jeeb_app/features/city/domain/entities/city_entity.dart';

part 'city_event.dart';
part 'city_state.dart';

class CityBloc extends Bloc<CityEvent, CityState> {
  final CityRepository _cityRepository;
  bool _isLoadingMore = false;
  int _page = 1;
  bool _hasNextPage = true;
  List<CityEntity> _accumulatedCities = [];
  String? _currentSearchText;
  int? _currentCountryId;
  final int _pageSize = 20;

  CityBloc(this._cityRepository) : super(CityInitial()) {
    on<LoadCities>(_onLoadCities);
    on<LoadMoreCities>(_onLoadMoreCities);
    on<ResetCities>(_onResetCities);
  }

  Future<void> _onLoadCities(
    LoadCities event,
    Emitter<CityState> emit,
  ) async {
    if (event.withLoading) {
      emit(CityLoading());
    }

    _currentCountryId = event.countryId;
    _currentSearchText = event.searchText;
    _page = 1;
    _hasNextPage = true;
    _isLoadingMore = false;
    _accumulatedCities.clear();

    final result = await _cityRepository.getCitiesByCountry(
      countryId: event.countryId,
      page: _page,
      limit: _pageSize,
    );

    result.fold(
      (failure) => emit(CityError(message: failure.message)),
      (cities) {
        _accumulatedCities.addAll(cities);
        _hasNextPage = cities.length >= _pageSize;

        emit(CityLoaded(
          cities: List.from(_accumulatedCities),
          isLoadingMore: false,
          hasReachedMax: !_hasNextPage,
          page: _page,
          isFiltered: event.isFiltered ?? false,
          currentSearchText: _currentSearchText,
        ));
      },
    );
  }

  Future<void> _onLoadMoreCities(
    LoadMoreCities event,
    Emitter<CityState> emit,
  ) async {
    if (!_hasNextPage ||
        _isLoadingMore ||
        state is! CityLoaded ||
        _currentCountryId == null) {
      return;
    }

    _isLoadingMore = true;
    final currentState = state as CityLoaded;
    emit(currentState.copyWith(isLoadingMore: true));

    _page++;

    final result = await _cityRepository.getCitiesByCountry(
      countryId: _currentCountryId!,
      page: _page,
      limit: _pageSize,
    );

    _isLoadingMore = false;

    result.fold(
      (failure) {
        _page--;
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (cities) {
        _accumulatedCities.addAll(cities);
        _hasNextPage = cities.length >= _pageSize;

        emit(currentState.copyWith(
          cities: List.from(_accumulatedCities),
          isLoadingMore: false,
          hasReachedMax: !_hasNextPage,
          page: _page,
        ));
      },
    );
  }

  void _onResetCities(
    ResetCities event,
    Emitter<CityState> emit,
  ) {
    _page = 1;
    _hasNextPage = true;
    _isLoadingMore = false;
    _accumulatedCities.clear();
    _currentSearchText = null;
    _currentCountryId = null;
    emit(CityInitial());
  }
}


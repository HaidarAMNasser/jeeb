import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/country/data/repositories/country_repository.dart';
import 'package:jeeb_app/features/country/domain/entities/country_entity.dart';

part 'country_event.dart';
part 'country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  final CountryRepository _countryRepository;
  bool _isLoadingMore = false;
  int _page = 1;
  bool _hasNextPage = true;
  List<CountryEntity> _accumulatedCountries = [];
  String? _currentSearchText;
  final int _pageSize = 20;

  CountryBloc(this._countryRepository) : super(CountryInitial()) {
    on<LoadCountries>(_onLoadCountries);
    on<LoadMoreCountries>(_onLoadMoreCountries);
  }

  Future<void> _onLoadCountries(
    LoadCountries event,
    Emitter<CountryState> emit,
  ) async {
    if (event.withLoading) {
      emit(CountryLoading());
    }

    _currentSearchText = event.searchText;
    _page = 1;
    _hasNextPage = true;
    _isLoadingMore = false;
    _accumulatedCountries.clear();

    final result = await _countryRepository.getAllCountries(
      page: _page,
      limit: _pageSize,
    );

    result.fold((failure) => emit(CountryError(message: failure.message)), (
      countries,
    ) {
      _accumulatedCountries.addAll(countries);
      _hasNextPage = countries.length >= _pageSize;

      emit(
        CountryLoaded(
          countries: List.from(_accumulatedCountries),
          isLoadingMore: false,
          hasReachedMax: !_hasNextPage,
          page: _page,
          isFiltered: event.isFiltered ?? false,
          currentSearchText: _currentSearchText,
        ),
      );
    });
  }

  Future<void> _onLoadMoreCountries(
    LoadMoreCountries event,
    Emitter<CountryState> emit,
  ) async {
    if (!_hasNextPage || _isLoadingMore || state is! CountryLoaded) {
      return;
    }

    _isLoadingMore = true;
    final currentState = state as CountryLoaded;
    emit(currentState.copyWith(isLoadingMore: true));

    _page++;

    final result = await _countryRepository.getAllCountries(
      page: _page,
      limit: _pageSize,
    );

    _isLoadingMore = false;

    result.fold(
      (failure) {
        _page--;
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (countries) {
        _accumulatedCountries.addAll(countries);
        _hasNextPage = countries.length >= _pageSize;

        emit(
          currentState.copyWith(
            countries: List.from(_accumulatedCountries),
            isLoadingMore: false,
            hasReachedMax: !_hasNextPage,
            page: _page,
          ),
        );
      },
    );
  }
}

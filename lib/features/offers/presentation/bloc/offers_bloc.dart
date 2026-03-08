import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/offer_entity.dart';
import '../../domain/entities/pagination_entity.dart';
import '../../data/repositories/offers_repository.dart';

part 'offers_event.dart';
part 'offers_state.dart';

class OffersBloc extends Bloc<OffersEvent, OffersState> {
  final OffersRepository _repository;
  int _currentPage = 1;
  bool _isLoadingMore = false;

  OffersBloc(this._repository) : super(const OffersStateInitial()) {
    on<FetchOffers>(_onFetchOffers);
    on<LoadMoreOffers>(_onLoadMoreOffers);
  }

  Future<void> _onFetchOffers(
    FetchOffers event,
    Emitter<OffersState> emit,
  ) async {
    emit(const OffersStateLoading());
    _currentPage = 1;

    final result = await _repository.getOffers(
      page: _currentPage,
      limit: 20,
      search: event.search,
      isActive: event.isActive,
      merchantId: event.merchantId,
    );

    result.fold(
      (failure) => emit(OffersStateError(failure.message)),
      (response) => emit(
        OffersStateLoaded(
          offers: response.data,
          pagination: response.pagination,
          hasReachedMax: !response.pagination.hasNextPage,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreOffers(
    LoadMoreOffers event,
    Emitter<OffersState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OffersStateLoaded ||
        _isLoadingMore ||
        currentState.hasReachedMax) {
      return;
    }

    _isLoadingMore = true;
    _currentPage++;

    final result = await _repository.getOffers(
      page: _currentPage,
      limit: 20,
      search: event.search,
      isActive: event.isActive,
      merchantId: event.merchantId,
    );

    result.fold(
      (failure) {
        _isLoadingMore = false;
        emit(OffersStateError(failure.message));
      },
      (response) {
        _isLoadingMore = false;
        final updatedOffers = List<OfferEntity>.from(currentState.offers)
          ..addAll(response.data);

        emit(
          OffersStateLoaded(
            offers: updatedOffers,
            pagination: response.pagination,
            hasReachedMax: !response.pagination.hasNextPage,
          ),
        );
      },
    );
  }
}

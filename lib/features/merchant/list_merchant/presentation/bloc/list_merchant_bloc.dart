import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/merchant/list_merchant/data/repositories/list_merchant_repository.dart';
import 'package:jeeb_app/features/merchant/favorites/data/repositories/favorites_repository.dart';

part 'list_merchant_event.dart';
part 'list_merchant_state.dart';

class ListMerchantBloc extends Bloc<ListMerchantEvent, ListMerchantState> {
  final ListMerchantRepository _repository;
  final FavoritesRepository _favoritesRepository;
  static const int _pageSize = 20;

  ListMerchantBloc(this._repository, this._favoritesRepository)
      : super(const ListMerchantInitial()) {
    on<ListMerchantEvent>((event, emit) async {
      if (event is GetMerchantsEvent) {
        if (event.loadMore) {
          final currentState = state;
          if (currentState is ListMerchantLoaded) {
            emit(ListMerchantLoadingMore(
              merchants: currentState.merchants,
              currentPage: currentState.currentPage,
              search: currentState.search,
              favoriteMerchantIds: currentState.favoriteMerchantIds,
            ));

            final nextPage = currentState.currentPage + 1;
            final searchQuery = event.search ?? currentState.search;
            final result = await _repository.getMerchants(
              page: nextPage,
              limit: _pageSize,
              search: searchQuery,
            );

            result.fold(
              (failure) => emit(ListMerchantError(message: failure.message)),
              (newMerchants) {
                final updatedMerchants = [
                  ...currentState.merchants,
                  ...newMerchants,
                ];
                emit(ListMerchantLoaded(
                  merchants: updatedMerchants,
                  hasMore: newMerchants.length == _pageSize,
                  currentPage: nextPage,
                  search: searchQuery,
                  favoriteMerchantIds: currentState.favoriteMerchantIds,
                ));
              },
            );
          }
        } else {
          emit(const ListMerchantLoading());
          final result = await _repository.getMerchants(
            page: 1,
            limit: _pageSize,
            search: event.search,
          );

          result.fold(
            (failure) => emit(ListMerchantError(message: failure.message)),
            (merchants) => emit(ListMerchantLoaded(
              merchants: merchants,
              hasMore: merchants.length == _pageSize,
              currentPage: 1,
              search: event.search,
            )),
          );
        }
      } else if (event is ToggleFavoriteMerchantEvent) {
        final currentState = state;
        if (currentState is! ListMerchantLoaded &&
            currentState is! ListMerchantLoadingMore) return;
        final merchantIdInt = int.tryParse(event.merchantId);
        if (merchantIdInt == null) return;
        final result = await _favoritesRepository.toggleFavorites(
          restaurantIds: [merchantIdInt],
        );
        result.fold(
          (_) => {},
          (favResult) {
            final ids = favResult.restaurantIds;
            if (currentState is ListMerchantLoaded) {
              emit(ListMerchantLoaded(
                merchants: currentState.merchants,
                hasMore: currentState.hasMore,
                currentPage: currentState.currentPage,
                search: currentState.search,
                favoriteMerchantIds: ids,
              ));
            } else if (currentState is ListMerchantLoadingMore) {
              emit(ListMerchantLoadingMore(
                merchants: currentState.merchants,
                currentPage: currentState.currentPage,
                search: currentState.search,
                favoriteMerchantIds: ids,
              ));
            }
          },
        );
      }
    });
  }
}


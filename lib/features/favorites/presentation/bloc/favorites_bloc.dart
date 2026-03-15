import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/favorites/data/repositories/favorites_repository.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

part 'favorites_event.dart';
part 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _repository;

  FavoritesBloc(this._repository) : super(const FavoritesInitial()) {
    on<LoadFavoritesEvent>(_onLoadFavorites);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
  }

  Future<void> _onLoadFavorites(
    LoadFavoritesEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesLoading());
    final result = await _repository.getFavorites(page: 1, limit: 100);
    result.fold(
      (failure) => emit(FavoritesError(failure.message)),
      (products) => emit(FavoritesLoaded(
        products: products,
        favoriteProductIds: products.map((p) => p.id).toSet(),
        togglingProductIds: const {},
      )),
    );
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    final productIdInt = int.tryParse(event.productId);
    if (productIdInt == null) return;

    final current = state;
    if (current is! FavoritesLoaded) return;

    final newIds = Set<String>.from(current.favoriteProductIds);
    final wasFavorite = newIds.contains(event.productId);
    if (wasFavorite) {
      newIds.remove(event.productId);
    } else {
      newIds.add(event.productId);
    }
    final toggling = Set<String>.from(current.togglingProductIds)..add(event.productId);

    // Optimistic update + show loading on this heart
    emit(FavoritesLoaded(
      products: current.products,
      favoriteProductIds: newIds,
      togglingProductIds: toggling,
    ));

    final result = await _repository.toggleFavorites(productIds: [productIdInt]);
    // Use a new set so we don't mutate the one in the emitted state (else BlocBuilder won't rebuild)
    final togglingDone = Set<String>.from(toggling)..remove(event.productId);

    if (!isClosed) {
      result.fold(
        (failure) {
          // Revert optimistic update on failure
          final revertedIds = Set<String>.from(newIds);
          if (wasFavorite) {
            revertedIds.add(event.productId);
          } else {
            revertedIds.remove(event.productId);
          }
          emit(FavoritesLoaded(
            products: current.products,
            favoriteProductIds: revertedIds,
            togglingProductIds: togglingDone,
          ));
        },
        (_) {
          // Success: emit with fresh Set copies so UI always sees a new state and rebuilds
          final newProducts = wasFavorite
              ? current.products.where((p) => p.id != event.productId).toList()
              : current.products;
          emit(FavoritesLoaded(
            products: newProducts,
            favoriteProductIds: Set<String>.from(newIds),
            togglingProductIds: togglingDone,
          ));
        },
      );
    }
  }
}

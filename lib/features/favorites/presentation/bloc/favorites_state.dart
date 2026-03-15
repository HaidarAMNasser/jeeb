part of 'favorites_bloc.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  final List<ProductEntity> products;
  final Set<String> favoriteProductIds;
  /// Product IDs currently being toggled (show loading instead of heart).
  final Set<String> togglingProductIds;

  const FavoritesLoaded({
    required this.products,
    required this.favoriteProductIds,
    this.togglingProductIds = const {},
  });

  bool isFavorite(String productId) => favoriteProductIds.contains(productId);
  bool isToggling(String productId) => togglingProductIds.contains(productId);

  @override
  List<Object?> get props => [products, favoriteProductIds, togglingProductIds];
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}

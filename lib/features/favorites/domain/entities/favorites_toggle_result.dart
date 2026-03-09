import 'package:equatable/equatable.dart';

/// Result of favorites/toggle API: current favorite restaurant and product ids.
class FavoritesToggleResult extends Equatable {
  final Set<String> restaurantIds;
  final Set<String> productIds;

  const FavoritesToggleResult({
    this.restaurantIds = const {},
    this.productIds = const {},
  });

  @override
  List<Object?> get props => [restaurantIds, productIds];
}

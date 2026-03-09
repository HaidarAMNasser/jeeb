import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class FavoritesRemoteDataSource {
  Future<Response> toggleFavorites({
    List<int>? restaurantIds,
    List<int>? productIds,
  });
}

class FavoritesRemoteDataSourceImpl implements FavoritesRemoteDataSource {
  final AppApiServiceClient _api;

  FavoritesRemoteDataSourceImpl(this._api);

  @override
  Future<Response> toggleFavorites({
    List<int>? restaurantIds,
    List<int>? productIds,
  }) {
    return _api.toggleFavorites(
      restaurants: restaurantIds,
      products: productIds,
    );
  }
}

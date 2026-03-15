import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/favorites/data/data_sources/favorites_remote_data_source.dart';
import 'package:jeeb_app/features/favorites/domain/entities/favorites_toggle_result.dart';

class FavoritesRepository {
  final FavoritesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  FavoritesRepository(this._remote, this._networkInfo);

  Future<Either<Failure, FavoritesToggleResult>> toggleFavorites({
    List<int>? restaurantIds,
    List<int>? productIds,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remote.toggleFavorites(
        restaurantIds: restaurantIds,
        productIds: productIds,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ServerFailure(message: 'Invalid response'));
      }
      final statusCode = data['statusCode'] as int? ?? data['status_code'] as int?;
      if (statusCode != 200) {
        return Left(ServerFailure(
          message: data['message'] as String? ?? 'Failed to toggle favorites',
          code: statusCode,
        ));
      }
      final dataPayload = data['data'] as Map<String, dynamic>?;
      if (dataPayload == null) {
        return const Right(FavoritesToggleResult());
      }
      final restaurants = dataPayload['restaurants'] as List<dynamic>? ?? [];
      final products = dataPayload['products'] as List<dynamic>? ?? [];
      final restaurantIdsSet = restaurants
          .map((e) => (e is Map && e['id'] != null) ? e['id'].toString() : null)
          .whereType<String>()
          .toSet();
      final productIdsSet = products
          .map((e) => (e is Map && e['id'] != null) ? e['id'].toString() : null)
          .whereType<String>()
          .toSet();
      return Right(FavoritesToggleResult(
        restaurantIds: restaurantIdsSet,
        productIds: productIdsSet,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

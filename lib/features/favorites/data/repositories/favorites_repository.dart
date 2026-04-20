import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/favorites/data/data_sources/favorites_remote_data_source.dart';
import 'package:jeeb_app/features/favorites/domain/entities/favorites_toggle_result.dart';
import 'package:jeeb_app/features/product/list_product/data/mappers/product_mapper.dart';
import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

class FavoritesRepository {
  final FavoritesRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  FavoritesRepository(this._remote, this._networkInfo);

  Future<Either<Failure, List<ProductEntity>>> getFavorites({
    int? page,
    int? limit,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remote.getFavorites(page: page, limit: limit);
      final dataRaw = response.data;
      if (dataRaw is! Map<String, dynamic>) {
        return const Left(ServerFailure(message: 'Invalid response'));
      }
      final statusCode = dataRaw['statusCode'] as int? ?? dataRaw['status_code'] as int?;
      if (statusCode != 200) {
        return Left(ServerFailure(
          message: dataRaw['message'] as String? ?? 'Failed to load favorites',
          code: statusCode,
        ));
      }
      final dataList = dataRaw['data'];
      if (dataList is! List) {
        return const Right([]);
      }
      final productMaps = <Map<String, dynamic>>[];
      for (final e in dataList) {
        if (e is Map<String, dynamic>) {
          final products = e['products'];
          if (products is List) {
            for (final p in products) {
              if (p is Map<String, dynamic>) productMaps.add(p);
            }
          }
        }
      }
      final entities = productMaps
          .map((m) => ProductModel.fromJson(m).toDomain())
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

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

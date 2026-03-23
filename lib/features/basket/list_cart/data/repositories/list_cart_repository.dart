import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/basket/list_cart/data/data_sources/list_cart_remote_data_source.dart';
import 'package:jeeb_app/features/basket/list_cart/data/mappers/basket_mapper.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/basket_model.dart';
import 'package:jeeb_app/features/basket/list_cart/domain/entities/basket_entity.dart';

class ListCartRepository {
  final ListCartRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  ListCartRepository(this._remote, this._networkInfo);

  Future<Either<Failure, BasketEntity?>> getCart() async {
    if (!await _networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final response = await _remote.getCart();
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        return const Left(ServerFailure(message: 'Invalid response'));
      }
      final statusCode = raw['statusCode'] as int? ?? raw['status_code'] as int?;
      if (statusCode != 200) {
        return Left(
          ServerFailure(message: raw['message']?.toString() ?? 'Failed to load cart'),
        );
      }
      if (raw['data'] == null) return const Right(null);
      final model = BasketModel.fromJson((raw['data'] as Map).cast<String, dynamic>());
      return Right(model.toDomain());
    } catch (e) {
      if (e is DioException) {
        // Backend can return 404 when no cart exists yet.
        if (e.response?.statusCode == 404) {
          return const Right(null);
        }
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

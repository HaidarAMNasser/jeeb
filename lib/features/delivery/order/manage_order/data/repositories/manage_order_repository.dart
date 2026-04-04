import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/delivery/order/manage_order/data/data_sources/manage_order_remote_data_source.dart';

class ManageOrderRepository {
  final ManageOrderRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ManageOrderRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, bool>> acceptDelivery(
    String id,
    int deliveryTime,
  ) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.acceptDelivery(id, deliveryTime);
        return const Right(true);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, bool>> confirmPickup(String id, String reason) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.confirmPickup(id, reason);
        return const Right(true);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, bool>> markOnTheWay(String id, String reason) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.markOnTheWay(id, reason);
        return const Right(true);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, bool>> markAsDelivered({
    required String id,
    required String reason,
    required double lat,
    required double lng,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.markAsDelivered(id, reason, lat, lng);
        return const Right(true);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, bool>> rejectDelivery(String id, String reason) async {
    if (await _networkInfo.isConnected) {
      try {
        await _remoteDataSource.rejectDelivery(id, reason);
        return const Right(true);
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/delivery/tracking/data/datasources/delivery_tracking_remote_data_source.dart';
import 'package:jeeb_app/features/delivery/tracking/domain/repositories/delivery_tracking_repository.dart';

class DeliveryTrackingRepositoryImpl implements DeliveryTrackingRepository {
  DeliveryTrackingRepositoryImpl(this._remote, this._networkInfo);

  final DeliveryTrackingRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, Unit>> pushLocationUpdate({
    required int orderId,
    required double lat,
    required double lng,
    required int timestampMs,
    required double speedKmh,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.postLocationUpdate(
        orderId: orderId,
        lat: lat,
        lng: lng,
        timestampMs: timestampMs,
        speedKmh: speedKmh,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}

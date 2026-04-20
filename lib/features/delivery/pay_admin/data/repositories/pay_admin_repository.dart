import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/delivery/pay_admin/data/data_sources/pay_admin_remote_data_source.dart';

class PayAdminRepository {
  PayAdminRepository(this._remote, this._networkInfo);

  final PayAdminRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  Future<Either<Failure, void>> submitMediatorPaymentProof({
    required List<String> orderIds,
    required String receiptImagePath,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.submitMediatorPaymentProof(
        orderIds: orderIds,
        receiptImagePath: receiptImagePath,
      );
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}

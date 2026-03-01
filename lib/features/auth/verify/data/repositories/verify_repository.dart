import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/api_response_model.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/auth/verify/data/data_sources/verify_remote_data_source.dart';

class VerifyRepository {
  final VerifyRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const VerifyRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, void>> verify({
    required String email,
    required String otp,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.verify(email: email, otp: otp);
      final apiResponse = ApiResponseModel<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => null,
      );
      if (apiResponse.isSuccess) {
        return const Right(null);
      }
      return const Left(ServerFailure(message: 'Verification failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

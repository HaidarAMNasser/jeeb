import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/api_response_model.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/auth/reset_password/data/data_sources/reset_password_remote_data_source.dart';

class ResetPasswordRepository {
  final ResetPasswordRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ResetPasswordRepository(
      this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.resetPassword(
        email: email,
        otp: otp,
        password: password,
      );
      final apiResponse = ApiResponseModel<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => null,
      );
      if (apiResponse.isSuccess) {
        return const Right(null);
      }
      return const Left(ServerFailure(message: 'Reset password failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

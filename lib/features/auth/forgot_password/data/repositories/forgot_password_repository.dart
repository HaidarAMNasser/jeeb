import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/api_response_model.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/auth/forgot_password/data/data_sources/forgot_password_remote_data_source.dart';

class ForgotPasswordRepository {
  final ForgotPasswordRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ForgotPasswordRepository(
      this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.forgotPassword(email: email);
      final apiResponse = ApiResponseModel<void>.fromJson(
        response.data as Map<String, dynamic>,
        (_) => null,
      );
      if (apiResponse.isSuccess) {
        return const Right(null);
      }
      return const Left(ServerFailure(message: 'Forgot password failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

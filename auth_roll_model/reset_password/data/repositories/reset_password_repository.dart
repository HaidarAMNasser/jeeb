import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../lib/core/common/errors/failure.dart';
import '../../../../lib/core/common/models/api_response_model.dart';
import '../../../../lib/core/common/utils/error_handler.dart';
import '../../../../lib/core/infrastructure/network/network_info.dart';
import '../data_sources/reset_password_remote_data_source.dart';

class ResetPasswordRepository {
  final ResetPasswordRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ResetPasswordRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, void>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.resetPassword(
          email: email,
          otp: otp,
          password: password,
        );

        final apiResponse = ApiResponseModel<void>.fromJson(
          response.data as Map<String, dynamic>,
          null,
        );

        if (apiResponse.isSuccess) {
          return const Right(null);
        } else {
          return Left(
            ErrorHandler.handle(
              DioException(
                type: DioExceptionType.badResponse,
                response: response,
                requestOptions: response.requestOptions,
              ),
            ),
          );
        }
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

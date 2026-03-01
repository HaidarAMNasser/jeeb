import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../lib/core/common/errors/failure.dart';
import '../../../../lib/core/common/models/api_response_model.dart';
import '../../../../lib/core/common/utils/error_handler.dart';
import '../../../../lib/core/infrastructure/network/network_info.dart';
import '../data_sources/forgot_password_remote_data_source.dart';

class ForgotPasswordRepository {
  final ForgotPasswordRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ForgotPasswordRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, void>> forgotPassword({required String email}) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.forgotPassword(email: email);

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

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../lib/core/common/errors/failure.dart';
import '../../../../lib/core/common/models/api_response_model.dart';
import '../../../../lib/core/common/utils/error_handler.dart';
import '../../../../lib/core/infrastructure/network/network_info.dart';
import '../data_sources/register_remote_data_source.dart';

class RegisterRepository {
  final RegisterRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const RegisterRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, int>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String role,
    required int countryId,
    required int cityId,
    required String notificationChannel,
    String? address,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.register(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          phone: phone,
          role: role,
          countryId: countryId,
          cityId: cityId,
          notificationChannel: notificationChannel,
          address: address,
        );

        final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
          response.data as Map<String, dynamic>,
          null,
        );

        if (apiResponse.isSuccess) {
          final userId = apiResponse.data?['userId'] as int?;
          if (userId != null) {
            return Right(userId);
          }
        }

        return Left(
          ErrorHandler.handle(
            DioException(
              type: DioExceptionType.badResponse,
              response: response,
              requestOptions: response.requestOptions,
            ),
          ),
        );
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

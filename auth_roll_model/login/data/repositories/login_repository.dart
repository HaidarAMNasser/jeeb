import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../lib/core/common/errors/failure.dart';
import '../../../../lib/core/common/models/api_response_model.dart';
import '../../../../lib/core/common/utils/error_handler.dart';
import '../../../../lib/core/infrastructure/network/network_info.dart';
import '../../domain/entities/token_entity.dart';
import '../data_sources/login_remote_data_source.dart';
import '../models/token_model.dart';

class LoginRepository {
  final LoginRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const LoginRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, TokenEntity>> login({
    required String email,
    required String password,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.login(
          email: email,
          password: password,
        );

        final apiResponse = ApiResponseModel<TokenModel>.fromJson(
          response.data as Map<String, dynamic>,
          (json) => TokenModel.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.isSuccess && apiResponse.data != null) {
          try {
            return Right(apiResponse.data!.toDomain());
          } catch (domainError) {
            return Left(ErrorHandler.handle(domainError));
          }
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

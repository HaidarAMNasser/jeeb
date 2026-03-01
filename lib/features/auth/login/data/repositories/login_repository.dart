import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/api_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/auth/domain/entities/token_entity.dart';
import 'package:jeeb_app/features/auth/login/data/data_sources/login_remote_data_source.dart';
import 'package:jeeb_app/features/auth/login/data/models/token_model.dart';

class LoginRepository {
  final LoginRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const LoginRepository(
    this._remoteDataSource,
    this._networkInfo,
  );

  Future<Either<Failure, TokenEntity>> login({
    required String email,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
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
        } catch (e) {
          return Left(ErrorHandler.handle(e));
        }
      }
      return Left(ErrorHandler.handle(
        DioException(
          type: DioExceptionType.badResponse,
          response: response,
          requestOptions: response.requestOptions,
        ),
      ));
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}

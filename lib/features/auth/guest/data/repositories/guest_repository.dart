import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/api_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/auth/login/data/models/token_model.dart';
import 'package:jeeb_app/features/auth/login/domain/entities/token_entity.dart';

import '../data_sources/guest_remote_data_source.dart';

class GuestRepository {
  final GuestRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const GuestRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, TokenEntity>> loginAsGuest({
    required String firebaseToken,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.guestLogin(
        firebaseToken: firebaseToken,
      );
      final apiResponse = ApiResponseModel<TokenModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => TokenModel.fromJson(json as Map<String, dynamic>),
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return Right(apiResponse.data!.toDomain());
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
  }
}

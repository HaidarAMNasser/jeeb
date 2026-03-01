import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../core/common/errors/failure.dart';
import '../../../../../core/common/models/api_response_model.dart';
import '../../../../../core/common/utils/error_handler.dart';
import '../../../../../core/infrastructure/network/network_info.dart';
import '../data_sources/verify_remote_data_source.dart';

class VerifyRepository {
  final VerifyRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const VerifyRepository(
    this._remoteDataSource,
    this._networkInfo,
  );

  Future<Either<Failure, void>> verify({
    required String email,
    required String otp,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.verify(
          email: email,
          otp: otp,
        );

        final apiResponse = ApiResponseModel<void>.fromJson(
          response.data as Map<String, dynamic>,
          null,
        );

        if (apiResponse.isSuccess) {
          return const Right(null);
        } else {
          return Left(ErrorHandler.handle(
            DioException(
              type: DioExceptionType.badResponse,
              response: response,
              requestOptions: response.requestOptions,
            ),
          ));
        }
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, void>> resendOtp({
    required String email,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.resendOtp(email: email);

        final apiResponse = ApiResponseModel<void>.fromJson(
          response.data as Map<String, dynamic>,
          null,
        );

        if (apiResponse.isSuccess) {
          return const Right(null);
        } else {
          return Left(ErrorHandler.handle(
            DioException(
              type: DioExceptionType.badResponse,
              response: response,
              requestOptions: response.requestOptions,
            ),
          ));
        }
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}


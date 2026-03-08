import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../core/common/errors/failure.dart';
import '../../../../../core/common/models/api_response_model.dart';
import '../../../../../core/common/utils/error_handler.dart';
import '../../../../../core/infrastructure/network/network_info.dart';
import '../../../login/domain/entities/user_entity.dart';
import '../data_sources/profile_remote_data_source.dart';
import '../../../login/data/models/user_model.dart';

class ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ProfileRepository(
    this._remoteDataSource,
    this._networkInfo,
  );

  Future<Either<Failure, UserEntity>> getProfile() async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getProfile();

        final apiResponse = ApiResponseModel<UserModel>.fromJson(
          response.data as Map<String, dynamic>,
          (json) => UserModel.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.isSuccess && apiResponse.data != null) {
          try {
            return Right(apiResponse.data!.toDomain());
          } catch (domainError) {
            return Left(ErrorHandler.handle(domainError));
          }
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

  Future<Either<Failure, UserEntity>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    int? countryId,
    int? cityId,
    String? address,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.updateProfile(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          countryId: countryId,
          cityId: cityId,
          address: address,
        );

        final apiResponse = ApiResponseModel<UserModel>.fromJson(
          response.data as Map<String, dynamic>,
          (json) => UserModel.fromJson(json as Map<String, dynamic>),
        );

        if (apiResponse.isSuccess && apiResponse.data != null) {
          try {
            return Right(apiResponse.data!.toDomain());
          } catch (domainError) {
            return Left(ErrorHandler.handle(domainError));
          }
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
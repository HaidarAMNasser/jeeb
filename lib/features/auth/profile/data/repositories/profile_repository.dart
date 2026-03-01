import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/api_response_model.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/auth/domain/entities/user_entity.dart';
import 'package:jeeb_app/features/auth/login/data/models/user_model.dart';
import 'package:jeeb_app/features/auth/profile/data/data_sources/profile_remote_data_source.dart';

class ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ProfileRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, UserEntity>> getProfile() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.getProfile();
      final apiResponse = ApiResponseModel<UserModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.isSuccess && apiResponse.data != null) {
        return Right(apiResponse.data!.toDomain());
      }
      return const Left(ServerFailure(message: 'Failed to load profile'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
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
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
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
        return Right(apiResponse.data!.toDomain());
      }
      return const Left(ServerFailure(message: 'Failed to update profile'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

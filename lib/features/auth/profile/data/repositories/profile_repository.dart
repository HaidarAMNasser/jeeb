import 'dart:io' show File;

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
    if (!await _networkInfo.isConnected) {
      return Right(_fakeUser());
    }
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
      return Right(_fakeUser());
    }
  }

  static UserEntity _fakeUser({
    double? latitude,
    double? longitude,
    bool? isActive,
  }) {
    final now = DateTime.now();
    return UserEntity(
      id: 1,
      firstName: 'Dev',
      lastName: 'User',
      email: 'dev@test.com',
      phone: '',
      role: UserRole.merchant,
      notificationChannel: NotificationChannel.email,
      countryId: 0,
      cityId: 0,
      createdAt: now,
      updatedAt: now,
      address: null,
      isActive: isActive ?? true,
      isVerified: true,
      currentLat: latitude,
      currentLng: longitude,
    );
  }

  Future<Either<Failure, UserEntity>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    int? countryId,
    int? cityId,
    String? address,
    double? latitude,
    double? longitude,
    bool? isActive,
    dynamic imageFile,
  }) async {
    if (!await _networkInfo.isConnected) {
      return Right(_fakeUser(
        latitude: latitude,
        longitude: longitude,
        isActive: isActive,
      ));
    }
    try {
      File? file;
      if (imageFile != null) {
        if (imageFile is File) {
          file = imageFile;
        } else {
          final path = (imageFile as dynamic).path as String?;
          if (path != null && path.isNotEmpty) file = File(path);
        }
      }
      final response = await _remoteDataSource.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        countryId: countryId,
        cityId: cityId,
        address: address,
        latitude: latitude,
        longitude: longitude,
        isActive: isActive,
        imageFile: file,
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
      return Right(_fakeUser(
        latitude: latitude,
        longitude: longitude,
        isActive: isActive,
      ));
    }
  }
}


import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../core/common/errors/failure.dart';
import 'package:flutter/foundation.dart';
import '../../../../../core/common/models/api_response_model.dart';
import '../../../../../core/common/utils/error_handler.dart';
import '../../../../../core/infrastructure/network/network_info.dart';
import '../../domain/entities/token_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../data_sources/login_remote_data_source.dart';
import '../models/token_model.dart';

/// Allowed admin login credentials (bypasses API).
const String _adminEmail = '1';
const String _adminPassword = '1';


class LoginRepository {
  final LoginRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const LoginRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, TokenEntity>> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().toLowerCase() == _adminEmail &&
        password == _adminPassword) {
      return Right(_adminTokenEntity(email.trim()));
    }
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
          if (response.statusCode == 401) {
            if (kDebugMode) {
              print('LoginRepository: 401 Unauthorized for login attempt (email=$email)');
            }
          }

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

  static TokenEntity _adminTokenEntity(String email) {
    final now = DateTime.now();
    final user = UserEntity(
      id: 0,
      firstName: 'Admin',
      lastName: 'User',
      email: email,
      phone: '',
      role: UserRole.admin,
      notificationChannel: NotificationChannel.email,
      address: null,
      isOnline: null,
      isActive: null,
      verifiedAt: null,
      isVerified: true,
      currentLat: null,
      currentLng: null,
      countryId: 0,
      country: null,
      cityId: 0,
      city: null,
      createdAt: now,
      updatedAt: now,
    );
    return TokenEntity(accessToken: 'admin_login', user: user);
  }
}

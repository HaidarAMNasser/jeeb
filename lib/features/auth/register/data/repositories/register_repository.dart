import 'dart:io' show File;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/features/auth/login/data/models/token_model.dart';
import 'package:jeeb_app/features/auth/login/domain/entities/token_entity.dart';
import '../../../../../core/common/errors/failure.dart';
import '../../../../../core/common/models/api_response_model.dart';
import '../../../../../core/common/utils/error_handler.dart';
import '../../../../../core/infrastructure/network/network_info.dart';
import '../data_sources/register_remote_data_source.dart';

class RegisterRepository {
  final RegisterRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const RegisterRepository(this._remoteDataSource, this._networkInfo);

  /// Returns [TokenEntity] when the register API returns access_token and user (store in SharedPreferences).
  /// Returns null when success but no token (e.g. old API only returns userId). Verify will rely on stored token.
  Future<Either<Failure, TokenEntity?>> register({
    required String firstName,
    required String lastName,
    String? email,
    required String password,
    required String phone,
    required String role,
    int? countryId,
    int? cityId,
    double? latitude,
    double? longitude,
    required String notificationChannel,
    String? address,
    String? birthday,
    dynamic imageFile,
    dynamic idFrontFile,
    dynamic idBackFile,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      File? file;
      if (imageFile != null) {
        if (imageFile is File) {
          file = imageFile;
        } else {
          final path = (imageFile as dynamic).path as String?;
          if (path != null && path.isNotEmpty) {
            file = File(path);
          }
        }
      }

      File? idFront;
      if (idFrontFile != null) {
        if (idFrontFile is File) {
          idFront = idFrontFile;
        } else {
          final path = (idFrontFile as dynamic).path as String?;
          if (path != null && path.isNotEmpty) {
            idFront = File(path);
          }
        }
      }

      File? idBack;
      if (idBackFile != null) {
        if (idBackFile is File) {
          idBack = idBackFile;
        } else {
          final path = (idBackFile as dynamic).path as String?;
          if (path != null && path.isNotEmpty) {
            idBack = File(path);
          }
        }
      }
      final response = await _remoteDataSource.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
        role: role,
        countryId: countryId,
        cityId: cityId,
        latitude: latitude,
        longitude: longitude,
        notificationChannel: notificationChannel,
        address: address,
        birthday: birthday,
        imageFile: file,
        idFrontFile: idFront,
        idBackFile: idBack,
      );

      final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json is Map<String, dynamic> ? json : {},
      );

      if (apiResponse.isSuccess) {
        final data = apiResponse.data ?? {};
        final accessToken = data['access_token'];
        final user = data['user'];
        if (accessToken != null &&
            accessToken.toString().isNotEmpty &&
            user is Map<String, dynamic>) {
          try {
            final tokenModel = TokenModel.fromJson(data);
            return Right(tokenModel.toDomain());
          } catch (_) {
            // Fallback: success with no token (e.g. userId only)
            return const Right(null);
          }
        }
        // Success but no token in response (e.g. only userId)
        return const Right(null);
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

  /// Client (customer) sign-up via `auth/register/customer/init`.
  /// Sends only first/last name, phone and password.
  Future<Either<Failure, TokenEntity?>> registerCustomerInit({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.registerCustomerInit(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
      );

      final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json is Map<String, dynamic> ? json : {},
      );

      if (apiResponse.isSuccess) {
        final data = apiResponse.data ?? {};
        final accessToken = data['access_token'];
        final user = data['user'];
        if (accessToken != null &&
            accessToken.toString().isNotEmpty &&
            user is Map<String, dynamic>) {
          try {
            final tokenModel = TokenModel.fromJson(data);
            return Right(tokenModel.toDomain());
          } catch (_) {
            return const Right(null);
          }
        }
        return const Right(null);
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

  /// Client sign-up step 2: verify phone OTP.
  /// Returns the success payload (may contain a token) or null when none.
  Future<Either<Failure, Map<String, dynamic>?>> verifyCustomerPhone({
    required String phone,
    required String otp,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.verifyCustomerPhone(
        phone: phone,
        otp: otp,
      );

      final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json is Map<String, dynamic> ? json : {},
      );

      if (apiResponse.isSuccess) {
        return Right(apiResponse.data);
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

  /// Client sign-up step 3: complete registration. All fields optional except phone.
  Future<Either<Failure, TokenEntity?>> completeCustomerRegistration({
    required String phone,
    String? email,
    int? countryId,
    int? cityId,
    dynamic imageFile,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      File? file;
      if (imageFile != null) {
        if (imageFile is File) {
          file = imageFile;
        } else {
          final path = (imageFile as dynamic).path as String?;
          if (path != null && path.isNotEmpty) {
            file = File(path);
          }
        }
      }

      final response = await _remoteDataSource.completeCustomerRegistration(
        phone: phone,
        email: email,
        countryId: countryId,
        cityId: cityId,
        imageFile: file,
      );

      final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json is Map<String, dynamic> ? json : {},
      );

      if (apiResponse.isSuccess) {
        final data = apiResponse.data ?? {};
        final accessToken = data['access_token'];
        final user = data['user'];
        if (accessToken != null &&
            accessToken.toString().isNotEmpty &&
            user is Map<String, dynamic>) {
          try {
            final tokenModel = TokenModel.fromJson(data);
            return Right(tokenModel.toDomain());
          } catch (_) {
            return const Right(null);
          }
        }
        return const Right(null);
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

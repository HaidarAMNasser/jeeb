import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/get_settings/data/data_sources/get_settings_data_source.dart';
import 'package:jeeb_app/features/get_settings/data/mappers/get_settings_mapper.dart';
import 'package:jeeb_app/features/get_settings/domain/entities/settings_entity.dart';
import 'package:flutter/foundation.dart';

class GetSettingsRepository {
  final GetSettingsRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const GetSettingsRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, SettingsEntity>> getSettings() async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.getSettings();
      if (kDebugMode) {
        print('GetSettingsRepository: http status=${response.statusCode}, data=${response.data}');
        if (response.statusCode == 401) {
          print('GetSettingsRepository: Unauthorized (401) on getSettings');
        }
      }
      final responseData = response.data;
      if (responseData == null || responseData is! Map<String, dynamic>) {
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

      final statusCode =
          responseData['statusCode'] as int? ??
          responseData['status_code'] as int?;
      if (statusCode != 200) {
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

      final data = responseData['data'] as Map<String, dynamic>?;
      return Right(GetSettingsMapper.fromJson(data));
    } catch (error) {
      return Left(ErrorHandler.handle(error));
    }
  }
}

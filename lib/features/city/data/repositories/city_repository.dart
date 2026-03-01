import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/city/data/data_sources/city_remote_data_source.dart';
import 'package:jeeb_app/features/city/data/models/city_model.dart';
import 'package:jeeb_app/features/city/domain/entities/city_entity.dart';

class CityRepository {
  final CityRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const CityRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, List<CityEntity>>> getCitiesByCountry({
    required int countryId,
    int page = 1,
    int limit = 100,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getCitiesByCountry(
          countryId: countryId,
          page: page,
          limit: limit,
        );

        BaseResponseModel<dynamic> baseResponseModel =
            BaseResponseModel<dynamic>.fromJson(response.data!, (json) => json);

        if (baseResponseModel.status == 200 ||
            baseResponseModel.success == true ||
            baseResponseModel.statusCode == 200) {
          dynamic data = baseResponseModel.data;
          if (data is String) {
            data = jsonDecode(data);
          }

          if (data is Map<String, dynamic> && data['data'] is List) {
            final List<dynamic> dataList = data['data'] as List<dynamic>;
            final cities = dataList
                .map((item) => CityModel.fromJson(item as Map<String, dynamic>))
                .map((model) => model.toDomain())
                .toList();
            return Right(cities);
          } else if (data is List) {
            final cities = data
                .map((item) => CityModel.fromJson(item as Map<String, dynamic>))
                .map((model) => model.toDomain())
                .toList();
            return Right(cities);
          } else {
            return const Right([]);
          }
        } else {
          return Left(
            ErrorHandler.handle(
              DioException(
                type: DioExceptionType.badResponse,
                response: response,
                requestOptions: RequestOptions(),
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

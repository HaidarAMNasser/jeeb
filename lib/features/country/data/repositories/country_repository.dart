import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/country/data/data_sources/country_remote_data_source.dart';
import 'package:jeeb_app/features/country/data/models/country_model.dart';
import 'package:jeeb_app/features/country/domain/entities/country_entity.dart';

class CountryRepository {
  final CountryRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const CountryRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, List<CountryEntity>>> getAllCountries({
    int page = 1,
    int limit = 100,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getAllCountries(
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
            final countries = dataList
                .map(
                  (item) => CountryModel.fromJson(item as Map<String, dynamic>),
                )
                .map((model) => model.toDomain())
                .toList();
            return Right(countries);
          } else if (data is List) {
            final countries = data
                .map(
                  (item) => CountryModel.fromJson(item as Map<String, dynamic>),
                )
                .map((model) => model.toDomain())
                .toList();
            return Right(countries);
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

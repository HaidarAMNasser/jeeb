import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/merchant/list_merchant/data/data_sources/list_merchant_data_source.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/mappers/merchant_mapper.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/models/merchant_model.dart';

class ListMerchantRepository {
  final ListMerchantRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ListMerchantRepository(
    this._remoteDataSource,
    this._networkInfo,
  );

  Future<Either<Failure, List<MerchantEntity>>> getMerchants({
    int? page,
    int? limit,
    String? search,
    int? countryId,
    int? cityId,
    bool? isActive,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getMerchants(
          page: page,
          limit: limit,
          search: search,
          countryId: countryId,
          cityId: cityId,
          isActive: isActive,
        );

        BaseResponseModel<List<MerchantModel>> baseResponseModel =
            BaseResponseModel<List<MerchantModel>>.fromJson(
          response.data!,
          (json) {
            if (json is String) {
              final parsedJson = jsonDecode(json) as List<dynamic>;
              return parsedJson
                  .map((item) =>
                      MerchantModel.fromJson(item as Map<String, dynamic>))
                  .toList();
            } else if (json is List) {
              return json
                  .map((item) =>
                      MerchantModel.fromJson(item as Map<String, dynamic>))
                  .toList();
            } else {
              throw FormatException(
                  'Expected data to be String or List, but got ${json.runtimeType}');
            }
          },
        );

        if (baseResponseModel.status == 200 ||
            baseResponseModel.success == true ||
            baseResponseModel.statusCode == 200) {
          if (baseResponseModel.data == null) {
            return Left(ErrorHandler.handle(DioException(
              type: DioExceptionType.badResponse,
              response: response,
              requestOptions: RequestOptions(),
            )));
          }

          try {
            return Right(baseResponseModel.data!.toDomain());
          } catch (domainError) {
            return Left(ErrorHandler.handle(domainError));
          }
        } else {
          return Left(ErrorHandler.handle(DioException(
            type: DioExceptionType.badResponse,
            response: response,
            requestOptions: RequestOptions(),
          )));
        }
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}


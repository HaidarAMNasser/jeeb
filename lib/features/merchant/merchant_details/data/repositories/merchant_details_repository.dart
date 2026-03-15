import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/data_sources/merchant_details_data_source.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/mappers/merchant_mapper.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/models/merchant_model.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';

class MerchantDetailsRepository {
  final MerchantDetailsRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const MerchantDetailsRepository(
    this._remoteDataSource,
    this._networkInfo,
  );

  Future<Either<Failure, MerchantEntity>> getMerchantDetails(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getMerchantDetails(id);

        BaseResponseModel<MerchantModel> baseResponseModel =
            BaseResponseModel<MerchantModel>.fromJson(
          response.data!,
          (json) {
            if (json is String) {
              final parsedJson = jsonDecode(json) as Map<String, dynamic>;
              return MerchantModel.fromJson(parsedJson);
            } else if (json is Map<String, dynamic>) {
              return MerchantModel.fromJson(json);
            } else {
              throw FormatException(
                  'Expected data to be String or Map, but got ${json.runtimeType}');
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


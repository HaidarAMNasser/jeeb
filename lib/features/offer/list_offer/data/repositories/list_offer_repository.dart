import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/offer/list_offer/data/data_sources/list_offer_data_source.dart';
import 'package:jeeb_app/features/offer/list_offer/data/mappers/offer_mapper.dart';
import 'package:jeeb_app/features/offer/list_offer/data/models/offer_model.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';

class ListOfferRepository {
  final ListOfferRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ListOfferRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, List<OfferEntity>>> getOffers({
    int? page,
    int? limit,
    String? restaurantId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getOffers(
          page: page,
          limit: limit,
          restaurantId: restaurantId,
        );

        BaseResponseModel<List<OfferModel>> baseResponseModel =
            BaseResponseModel<List<OfferModel>>.fromJson(
          response.data!,
          (json) {
            if (json is String) {
              final parsed = jsonDecode(json) as List<dynamic>;
              return parsed
                  .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
            if (json is List) {
              return json
                  .map((e) => OfferModel.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
            throw FormatException(
                'Expected data to be String or List, got ${json.runtimeType}');
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
          } catch (e) {
            return Left(ErrorHandler.handle(e));
          }
        }
        return Left(ErrorHandler.handle(DioException(
          type: DioExceptionType.badResponse,
          response: response,
          requestOptions: RequestOptions(),
        )));
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    }
    return const Left(NetworkFailure());
  }
}

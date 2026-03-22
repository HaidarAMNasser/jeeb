import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/offer/list_offer/data/mappers/offer_mapper.dart';
import 'package:jeeb_app/features/offer/list_offer/data/models/offer_model.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/offer/offer_details/data/data_sources/offer_details_data_source.dart';

class OfferDetailsRepository {
  final OfferDetailsRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const OfferDetailsRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, OfferEntity>> getOfferDetails(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getOfferDetails(id);

        BaseResponseModel<OfferModel> baseResponseModel =
            BaseResponseModel<OfferModel>.fromJson(
          response.data!,
          (json) {
            OfferModel fromList(List<dynamic> list) {
              final maps = list.whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              );
              final matched = maps.firstWhere(
                (m) => m['id']?.toString() == id,
                orElse: () => maps.isNotEmpty ? maps.first : <String, dynamic>{},
              );
              return OfferModel.fromJson(matched);
            }

            if (json is String) {
              final parsed = jsonDecode(json);
              if (parsed is Map<String, dynamic>) {
                return OfferModel.fromJson(parsed);
              }
              if (parsed is List) {
                return fromList(parsed);
              }
              throw FormatException(
                'Expected parsed json to be Map or List, got ${parsed.runtimeType}',
              );
            }
            if (json is Map<String, dynamic>) {
              return OfferModel.fromJson(json);
            }
            if (json is List) {
              return fromList(json);
            }
            throw FormatException(
              'Expected data to be String, Map or List, got ${json.runtimeType}',
            );
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
          return Right(baseResponseModel.data!.toDomain());
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

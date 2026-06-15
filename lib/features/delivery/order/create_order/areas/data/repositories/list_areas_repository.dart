import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/data/data_sources/list_areas_data_source.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/data/mappers/area_mapper.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/data/models/area_model.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/domain/entities/paginated_areas.dart';

class ListAreasRepository {
  final ListAreasRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ListAreasRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, PaginatedAreas>> getAreas({
    int? page,
    int? limit,
    String? search,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.getAreas(
        page: page,
        limit: limit,
        search: search,
      );

      BaseResponseModel<List<AreaModel>>
      baseResponseModel = BaseResponseModel<List<AreaModel>>.fromJson(
        response.data!,
        (json) {
          if (json is String) {
            final parsedJson = jsonDecode(json) as List<dynamic>;
            return parsedJson
                .map(
                  (item) => AreaModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          } else if (json is List) {
            return json
                .map(
                  (item) => AreaModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          } else {
            throw FormatException(
              'Expected data to be String or List, but got ${json.runtimeType}',
            );
          }
        },
      );

      if (baseResponseModel.status == 200 ||
          baseResponseModel.success == true ||
          baseResponseModel.statusCode == 200) {
        if (baseResponseModel.data == null) {
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

        try {
          return Right(
            PaginatedAreas(
              areas: baseResponseModel.data!.toDomain(),
              pagination: baseResponseModel.pagination,
            ),
          );
        } catch (domainError) {
          return Left(ErrorHandler.handle(domainError));
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
  }
}

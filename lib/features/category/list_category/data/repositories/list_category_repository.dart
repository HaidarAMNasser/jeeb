import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/category/list_category/data/data_sources/list_category_data_source.dart';
import 'package:jeeb_app/features/category/list_category/data/models/category_model.dart';
import 'package:jeeb_app/features/category/list_category/data/mappers/category_mapper.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';

import 'package:jeeb_app/features/category/list_category/domain/entities/paginated_categories.dart';

class ListCategoryRepository {
  final ListCategoryRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ListCategoryRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, PaginatedCategories>> getCategories({
    int? page,
    int? limit,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getCategories(
          page: page,
          limit: limit,
        );

        BaseResponseModel<List<CategoryModel>> baseResponseModel =
            BaseResponseModel<List<CategoryModel>>.fromJson(
          response.data!,
          (json) {
            if (json is String) {
              final parsedJson = jsonDecode(json) as List<dynamic>;
              return parsedJson
                  .map(
                    (item) =>
                        CategoryModel.fromJson(item as Map<String, dynamic>),
                  )
                  .toList();
            } else if (json is List) {
              return json
                  .map(
                    (item) =>
                        CategoryModel.fromJson(item as Map<String, dynamic>),
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
              PaginatedCategories(
                categories: baseResponseModel.data!.toDomain(),
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
    } else {
      return const Left(NetworkFailure());
    }
  }
}

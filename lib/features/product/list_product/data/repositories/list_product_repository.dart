import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/product/list_product/data/data_sources/list_product_data_source.dart';
import 'package:jeeb_app/features/product/list_product/data/mappers/product_mapper.dart';
import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/paginated_products.dart';

class ListProductRepository {
  final ListProductRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ListProductRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, PaginatedProducts>> getProducts({
    int? page,
    int? limit,
    String? search,
    String? categoryId,
    String? restaurantId,
    double? minPrice,
    double? maxPrice,
    int? minRating,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.getProducts(
        page: page,
        limit: limit,
        search: search,
        categoryId: categoryId,
        restaurantId: restaurantId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minRating: minRating,
      );

      BaseResponseModel<List<ProductModel>>
      baseResponseModel = BaseResponseModel<List<ProductModel>>.fromJson(
        response.data!,
        (json) {
          if (json is String) {
            final parsedJson = jsonDecode(json) as List<dynamic>;
            return parsedJson
                .map(
                  (item) => ProductModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          } else if (json is List) {
            return json
                .map(
                  (item) => ProductModel.fromJson(item as Map<String, dynamic>),
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
            PaginatedProducts(
              products: baseResponseModel.data!.toDomain(),
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

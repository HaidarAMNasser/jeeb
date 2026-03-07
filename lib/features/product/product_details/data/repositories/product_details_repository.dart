import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/product_details/data/data_sources/product_details_data_source.dart';
import 'package:jeeb_app/features/product/list_product/data/mappers/product_mapper.dart';
import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';

class ProductDetailsRepository {
  final ProductDetailsRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ProductDetailsRepository(
    this._remoteDataSource,
    this._networkInfo,
  );

  Future<Either<Failure, ProductEntity>> getProductDetails(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getProductDetails(id);

        BaseResponseModel<ProductModel> baseResponseModel =
            BaseResponseModel<ProductModel>.fromJson(
          response.data!,
          (json) {
            if (json is String) {
              final parsedJson = jsonDecode(json) as Map<String, dynamic>;
              return ProductModel.fromJson(parsedJson);
            } else if (json is Map<String, dynamic>) {
              return ProductModel.fromJson(json);
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


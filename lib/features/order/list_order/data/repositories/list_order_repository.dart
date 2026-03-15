import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/order/list_order/data/data_sources/list_order_data_source.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/order/order_details/data/models/order_model.dart';
import 'package:jeeb_app/features/order/order_details/data/mappers/order_mapper.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
class ListOrderRepository {
  final ListOrderRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ListOrderRepository(
    this._remoteDataSource,
    this._networkInfo,
  );

  Future<Either<Failure, List<OrderEntity>>> getOrders({
    int? page,
    int? limit,
    String? search,
    String? merchantId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getOrders(
          page: page,
          limit: limit,
          search: search,
          merchantId: merchantId,
        );

        BaseResponseModel<List<OrderModel>> baseResponseModel =
            BaseResponseModel<List<OrderModel>>.fromJson(
          response.data!,
          (json) {
            if (json is String) {
              final parsedJson = jsonDecode(json) as List<dynamic>;
              return parsedJson
                  .map((item) =>
                      OrderModel.fromJson(item as Map<String, dynamic>))
                  .toList();
            } else if (json is List) {
              return json
                  .map((item) =>
                      OrderModel.fromJson(item as Map<String, dynamic>))
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


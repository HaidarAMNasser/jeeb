import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/order/list_order/data/data_sources/list_order_data_source.dart';
import 'package:jeeb_app/features/order/order_details/data/mappers/order_mapper.dart';
import 'package:jeeb_app/features/order/order_details/data/models/order_model.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';

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
    String? ownerId,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getOrders(
          page: page,
          limit: limit,
          search: search,
          ownerId: ownerId,
        );

        final statusCode = response.statusCode ?? 0;
        if (statusCode < 200 || statusCode >= 300) {
          return Left(ErrorHandler.handle(DioException(
            type: DioExceptionType.badResponse,
            response: response,
            requestOptions: response.requestOptions,
          )));
        }

        final raw = response.data;
        if (raw is! Map<String, dynamic>) {
          return Left(ErrorHandler.handle(
            FormatException('Orders response is not a JSON object'),
          ));
        }

        final data = raw['data'];
        if (data is! List) {
          return Left(ErrorHandler.handle(
            FormatException('Orders list missing or invalid'),
          ));
        }

        final orders = data
            .whereType<Map>()
            .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        return Right(orders.map((m) => m.toDomain()).toList());
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }

  Future<Either<Failure, List<OrderEntity>>> getAvailableOrders() async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getAvailableOrders();

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

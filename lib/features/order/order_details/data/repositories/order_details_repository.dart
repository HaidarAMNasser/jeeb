import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/base_response_model.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/order/order_details/data/data_sources/order_details_data_source.dart';
import 'package:jeeb_app/features/order/order_details/data/mappers/order_mapper.dart';
import 'package:jeeb_app/features/order/order_details/data/models/order_model.dart';
import 'package:jeeb_app/features/order/order_details/domain/entities/order_entity.dart';

class OrderDetailsRepository {
  final OrderDetailsRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const OrderDetailsRepository(
    this._remoteDataSource,
    this._networkInfo,
  );

  Future<Either<Failure, OrderEntity>> getOrderDetails(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getOrderDetails(id);

        BaseResponseModel<OrderModel> baseResponseModel =
            BaseResponseModel<OrderModel>.fromJson(
          response.data!,
          (json) => OrderModel.fromJson(json as Map<String, dynamic>),
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


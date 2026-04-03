import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/delivery/order/order_details/data/data_sources/order_details_data_source.dart';
import 'package:jeeb_app/features/delivery/order/order_details/data/mappers/order_mapper.dart';
import 'package:jeeb_app/features/delivery/order/order_details/data/models/order_model.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

class OrderDetailsRepository {
  final OrderDetailsRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const OrderDetailsRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, OrderEntity>> getOrderDetails(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.getOrderDetails(id);

        final statusCode = response.statusCode ?? 0;
        if (statusCode < 200 || statusCode >= 300) {
          return Left(
            ErrorHandler.handle(
              DioException(
                type: DioExceptionType.badResponse,
                response: response,
                requestOptions: response.requestOptions,
              ),
            ),
          );
        }

        final raw = response.data;
        if (raw is! Map<String, dynamic>) {
          return Left(
            ErrorHandler.handle(
              FormatException('Order details response is not a JSON object'),
            ),
          );
        }

        Map<String, dynamic> orderJson;
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          final nestedOrder = data['order'];
          if (nestedOrder is Map<String, dynamic>) {
            orderJson = nestedOrder;
          } else {
            orderJson = data;
          }
        } else {
          orderJson = raw;
        }

        final model = OrderModel.fromJson(orderJson);
        return Right(model.toDomain());
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

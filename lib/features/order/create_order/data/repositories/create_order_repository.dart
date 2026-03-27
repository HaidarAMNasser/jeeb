import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/order/create_order/data/data_sources/create_order_remote_data_source.dart';
import 'package:jeeb_app/features/order/create_order/domain/entities/create_order_params.dart';

class CreateOrderRepository {
  final CreateOrderRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  const CreateOrderRepository(this._remote, this._networkInfo);

  Future<Either<Failure, String>> createOrder(CreateOrderParams params) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remote.createOrder(params);
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
            FormatException('Invalid create order response'),
          ));
        }

        final data = raw['data'];
        Map<String, dynamic>? orderMap;
        if (data is Map<String, dynamic>) {
          if (data['order'] is Map<String, dynamic>) {
            orderMap = data['order'] as Map<String, dynamic>;
          } else if (data['id'] != null) {
            orderMap = data;
          }
        }

        final id = orderMap?['id']?.toString();
        if (id == null || id.isEmpty) {
          return Left(ErrorHandler.handle(
            FormatException('Order id missing in response'),
          ));
        }

        return Right(id);
      } catch (e) {
        return Left(ErrorHandler.handle(e));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

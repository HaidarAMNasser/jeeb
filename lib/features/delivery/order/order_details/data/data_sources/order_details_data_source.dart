import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class OrderDetailsRemoteDataSource {
  Future<Response> getOrderDetails(String id);

  Future<Response> cancelOrder(String id);
}

class OrderDetailsRemoteDataSourceImpl implements OrderDetailsRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  OrderDetailsRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getOrderDetails(String id) {
    return _appApiServiceClient.getOrderDetails(id);
  }

  @override
  Future<Response> cancelOrder(String id) {
    return _appApiServiceClient.cancelOrder(id);
  }
}


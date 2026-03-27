import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ListOrderRemoteDataSource {
  Future<Response> getOrders({
    int? page,
    int? limit,
    String? search,
    String? merchantId,
  });

  Future<Response> getAvailableOrders();
}

class ListOrderRemoteDataSourceImpl implements ListOrderRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  ListOrderRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getOrders({
    int? page,
    int? limit,
    String? search,
    String? merchantId,
  }) {
    return _appApiServiceClient.getOrders(
      page: page,
      limit: limit,
      search: search,
      merchantId: merchantId,
    );
  }

  @override
  Future<Response> getAvailableOrders() {
    return _appApiServiceClient.getOrders();
  }
}


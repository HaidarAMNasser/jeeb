import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class OrderBeforeConfirmRemoteDataSource {
  Future<Response> calculateDeliveryCost(Map<String, dynamic> body);
}

class OrderBeforeConfirmRemoteDataSourceImpl
    implements OrderBeforeConfirmRemoteDataSource {
  OrderBeforeConfirmRemoteDataSourceImpl(this._client);

  final AppApiServiceClient _client;

  @override
  Future<Response> calculateDeliveryCost(Map<String, dynamic> body) {
    return _client.calculateDeliveryCost(body);
  }
}

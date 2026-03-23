import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ListCartRemoteDataSource {
  Future<Response> getCart();
}

class ListCartRemoteDataSourceImpl implements ListCartRemoteDataSource {
  final AppApiServiceClient _api;

  ListCartRemoteDataSourceImpl(this._api);

  @override
  Future<Response> getCart() => _api.getCart();
}

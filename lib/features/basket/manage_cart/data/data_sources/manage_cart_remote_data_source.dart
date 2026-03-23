import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ManageCartRemoteDataSource {
  Future<Response> getCart();
  Future<Response> createCart(Map<String, dynamic> body);
  Future<Response> updateCart(Map<String, dynamic> body);
  Future<Response> clearCart();
}

class ManageCartRemoteDataSourceImpl implements ManageCartRemoteDataSource {
  final AppApiServiceClient _api;

  ManageCartRemoteDataSourceImpl(this._api);

  @override
  Future<Response> getCart() => _api.getCart();

  @override
  Future<Response> createCart(Map<String, dynamic> body) => _api.createCart(body);

  @override
  Future<Response> updateCart(Map<String, dynamic> body) => _api.updateCart(body);

  @override
  Future<Response> clearCart() => _api.clearCart();
}

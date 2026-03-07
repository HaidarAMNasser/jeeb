import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ProductDetailsRemoteDataSource {
  Future<Response> getProductDetails(String id);
}

class ProductDetailsRemoteDataSourceImpl
    implements ProductDetailsRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  ProductDetailsRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getProductDetails(String id) {
    return _appApiServiceClient.getProductDetails(id);
  }
}


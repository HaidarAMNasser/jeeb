import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ListCategoryRemoteDataSource {
  Future<Response> getCategories();
}

class ListCategoryRemoteDataSourceImpl implements ListCategoryRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  ListCategoryRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getCategories() {
    return _appApiServiceClient.getCategories();
  }
}


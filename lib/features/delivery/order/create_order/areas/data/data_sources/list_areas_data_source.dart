import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ListAreasRemoteDataSource {
  Future<Response> getAreas({
    int? page,
    int? limit,
    String? search,
  });
}

class ListAreasRemoteDataSourceImpl implements ListAreasRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  ListAreasRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getAreas({
    int? page,
    int? limit,
    String? search,
  }) {
    return _appApiServiceClient.getAreas(page, limit, search);
  }
}

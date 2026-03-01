import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class CityRemoteDataSource {
  Future<Response> getCitiesByCountry({
    required int countryId,
    int page = 1,
    int limit = 100,
  });
}

class CityRemoteDataSourceImpl implements CityRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  CityRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getCitiesByCountry({
    required int countryId,
    int page = 1,
    int limit = 100,
  }) {
    return _appApiServiceClient.getCities(
      countryId,
      page,
      limit,
    );
  }
}


import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class CountryRemoteDataSource {
  Future<Response> getAllCountries({int page = 1, int limit = 100});
}

class CountryRemoteDataSourceImpl implements CountryRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  CountryRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getAllCountries({int page = 1, int limit = 100}) {
    return _appApiServiceClient.getCountries(page, limit);
  }
}

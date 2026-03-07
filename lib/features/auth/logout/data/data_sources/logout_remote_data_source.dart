import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class LogoutRemoteDataSource {
  Future<Response> logout();
}

class LogoutRemoteDataSourceImpl implements LogoutRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  LogoutRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> logout() {
    return _appApiServiceClient.logout();
  }
}


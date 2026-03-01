import 'package:dio/dio.dart';
import 'package:jeeb_admin/core/infrastructure/api/api_service.dart';

abstract class LoginRemoteDataSource {
  Future<Response> login({
    required String email,
    required String password,
  });
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  LoginRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> login({
    required String email,
    required String password,
  }) {
    return _appApiServiceClient.loginWithEmail(
      email,
      password,
      false, // is_mobile_pass
    );
  }
}


import 'package:dio/dio.dart';
import '../../../../../core/infrastructure/api/api_service.dart';

abstract class LogInRemoteDataSource {
  Future<Response> login({
    required String emailOrPhone,
    required String password,
    int? phoneCodeId,
    required bool directLogin,
    required bool loginWithPhone,
  });
}

class LogInRemoteDataSourceImpl implements LogInRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  LogInRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> login({
    required String emailOrPhone,
    required String password,
    int? phoneCodeId,
    required bool directLogin,
    required bool loginWithPhone,
  }) async {
    if (loginWithPhone) {
      return await _appApiServiceClient.loginWithPhone(
        emailOrPhone,
        password,
        directLogin,
        phoneCodeId!,
      );
    } else {
      return await _appApiServiceClient.loginWithEmail(
        emailOrPhone,
        password,
        directLogin,
      );
    }
  }
}

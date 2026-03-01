import 'package:dio/dio.dart';
import 'package:jeeb_admin/core/infrastructure/api/api_service.dart';

abstract class ResetPasswordRemoteDataSource {
  Future<Response> resetPassword({
    required String email,
    required String otp,
    required String password,
  });
}

class ResetPasswordRemoteDataSourceImpl
    implements ResetPasswordRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  ResetPasswordRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) {
    return _appApiServiceClient.resetPassword(
      email,
      otp,
      password,
    );
  }
}


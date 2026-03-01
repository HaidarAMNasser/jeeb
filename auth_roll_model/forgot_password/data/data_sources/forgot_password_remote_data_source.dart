import 'package:dio/dio.dart';
import 'package:jeeb_admin/core/infrastructure/api/api_service.dart';

abstract class ForgotPasswordRemoteDataSource {
  Future<Response> forgotPassword({
    required String email,
  });
}

class ForgotPasswordRemoteDataSourceImpl
    implements ForgotPasswordRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  ForgotPasswordRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> forgotPassword({
    required String email,
  }) {
    return _appApiServiceClient.forgotPassword(
      email,
    );
  }
}


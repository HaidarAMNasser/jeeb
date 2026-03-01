import 'package:dio/dio.dart';
import 'package:jeeb_admin/core/infrastructure/api/api_service.dart';

abstract class VerifyRemoteDataSource {
  Future<Response> verify({
    required String email,
    required String otp,
  });

  Future<Response> resendOtp({
    required String email,
  });
}

class VerifyRemoteDataSourceImpl implements VerifyRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  VerifyRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> verify({
    required String email,
    required String otp,
  }) {
    return _appApiServiceClient.verify(
      email,
      otp,
    );
  }

  @override
  Future<Response> resendOtp({
    required String email,
  }) {
    return _appApiServiceClient.resendOtp(
      email,
    );
  }
}


import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class RegisterRemoteDataSource {
  Future<Response> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String role,
    required int countryId,
    required int cityId,
    required String notificationChannel,
    String? address,
  });
}

class RegisterRemoteDataSourceImpl implements RegisterRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  RegisterRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String role,
    required int countryId,
    required int cityId,
    required String notificationChannel,
    String? address,
  }) {
    return _appApiServiceClient.register(
      firstName,
      lastName,
      email,
      password,
      phone,
      role,
      countryId,
      cityId,
      notificationChannel,
      address,
    );
  }
}


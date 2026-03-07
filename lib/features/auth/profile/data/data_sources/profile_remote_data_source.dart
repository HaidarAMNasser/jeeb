import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ProfileRemoteDataSource {
  Future<Response> getProfile();

  Future<Response> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    int? countryId,
    int? cityId,
    String? address,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  ProfileRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getProfile() {
    return _appApiServiceClient.getProfile();
  }

  @override
  Future<Response> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    int? countryId,
    int? cityId,
    String? address,
  }) {
    return _appApiServiceClient.updateProfile(
      firstName,
      lastName,
      phone,
      countryId,
      cityId,
      address,
    );
  }
}


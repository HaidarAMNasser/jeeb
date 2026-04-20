import 'dart:io' show File;

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
    double? latitude,
    double? longitude,
    bool? isActive,
    File? imageFile,
    String? password,
    String? newPassword,
    String? confirmedPassword,
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
    double? latitude,
    double? longitude,
    bool? isActive,
    File? imageFile,
    String? password,
    String? newPassword,
    String? confirmedPassword,
  }) async {
    MultipartFile? image;
    if (imageFile != null) {
      final path = imageFile.path;
      final name = path.contains(RegExp(r'[/\\]')) ? path.split(RegExp(r'[/\\]')).last : path;
      image = await MultipartFile.fromFile(path, filename: name);
    }
    return _appApiServiceClient.updateProfile(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      countryId: countryId,
      cityId: cityId,
      address: address,
      latitude: latitude,
      longitude: longitude,
      isActive: isActive,
      image: image,
      password: password,
      newPassword: newPassword,
      confirmedPassword: confirmedPassword,
    );
  }
}


import 'dart:io' show File;

import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class RegisterRemoteDataSource {
  Future<Response> register({
    required String firstName,
    required String lastName,
    String? email,
    required String password,
    required String phone,
    required String role,
    int? countryId,
    int? cityId,
    double? latitude,
    double? longitude,
    required String notificationChannel,
    String? address,
    String? birthday,
    File? imageFile,
    File? idFrontFile,
    File? idBackFile,
  });

  /// Client (customer) sign-up: only first/last name, phone, password.
  Future<Response> registerCustomerInit({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  });

  /// Client sign-up step 2: verify phone OTP.
  Future<Response> verifyCustomerPhone({
    required String phone,
    required String otp,
  });

  /// Client sign-up step 3: complete registration (all optional except phone).
  Future<Response> completeCustomerRegistration({
    required String phone,
    String? email,
    int? countryId,
    int? cityId,
    File? imageFile,
  });
}

class RegisterRemoteDataSourceImpl implements RegisterRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  RegisterRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> register({
    required String firstName,
    required String lastName,
    String? email,
    required String password,
    required String phone,
    required String role,
    int? countryId,
    int? cityId,
    double? latitude,
    double? longitude,
    required String notificationChannel,
    String? address,
    String? birthday,
    File? imageFile,
    File? idFrontFile,
    File? idBackFile,
  }) async {
    MultipartFile? image;
    if (imageFile != null) {
      final path = imageFile.path;
      final name = path.contains(RegExp(r'[/\\]'))
          ? path.split(RegExp(r'[/\\]')).last
          : path;
      image = await MultipartFile.fromFile(path, filename: name);
    }
    final idImageFiles = <MultipartFile>[];
    for (final file in [idFrontFile, idBackFile]) {
      if (file != null) {
        final path = file.path;
        final name = path.contains(RegExp(r'[/\\]'))
            ? path.split(RegExp(r'[/\\]')).last
            : path;
        idImageFiles.add(await MultipartFile.fromFile(path, filename: name));
      }
    }
    return _appApiServiceClient.register(
      firstName,
      lastName,
      email,
      password,
      phone,
      role,
      countryId,
      cityId,
      latitude,
      longitude,
      notificationChannel,
      address,
      birthday,
      image,
      idImageFiles.isEmpty ? null : idImageFiles,
    );
  }

  @override
  Future<Response> registerCustomerInit({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) {
    return _appApiServiceClient.registerCustomerInit(
      firstName,
      lastName,
      phone,
      password,
    );
  }

  @override
  Future<Response> verifyCustomerPhone({
    required String phone,
    required String otp,
  }) {
    return _appApiServiceClient.verifyCustomerPhone(phone, otp);
  }

  @override
  Future<Response> completeCustomerRegistration({
    required String phone,
    String? email,
    int? countryId,
    int? cityId,
    File? imageFile,
  }) async {
    MultipartFile? image;
    if (imageFile != null) {
      final path = imageFile.path;
      final name = path.contains(RegExp(r'[/\\]'))
          ? path.split(RegExp(r'[/\\]')).last
          : path;
      image = await MultipartFile.fromFile(path, filename: name);
    }
    return _appApiServiceClient.completeCustomerRegistration(
      phone,
      email,
      countryId,
      cityId,
      image,
    );
  }
}

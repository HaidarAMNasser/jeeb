import 'dart:io' show File;

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
    MultipartFile? idFront;
    if (idFrontFile != null) {
      final path = idFrontFile.path;
      final name = path.contains(RegExp(r'[/\\]'))
          ? path.split(RegExp(r'[/\\]')).last
          : path;
      idFront = await MultipartFile.fromFile(path, filename: name);
    }
    MultipartFile? idBack;
    if (idBackFile != null) {
      final path = idBackFile.path;
      final name = path.contains(RegExp(r'[/\\]'))
          ? path.split(RegExp(r'[/\\]')).last
          : path;
      idBack = await MultipartFile.fromFile(path, filename: name);
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
      idFront,
      idBack,
    );
  }
}

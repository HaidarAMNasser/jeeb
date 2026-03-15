import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';
import 'package:flutter/foundation.dart';

abstract class GetSettingsRemoteDataSource {
  Future<Response> getSettings();
}

class GetSettingsRemoteDataSourceImpl implements GetSettingsRemoteDataSource {
  final AppApiServiceClient _api;

  GetSettingsRemoteDataSourceImpl(this._api);

  @override
  Future<Response> getSettings() async {
    print('GET settings');
    final response = await _api.getSettings();
    if (kDebugMode) {
      print('GetSettingsRemoteDataSourceImpl: http status=${response.statusCode}, data=${response.data}');
    }
    return response;
  }
}

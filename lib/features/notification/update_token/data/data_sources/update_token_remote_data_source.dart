import 'package:dio/dio.dart';
import '../../../../../../core/infrastructure/api/api_service.dart';

abstract class UpdateTokenRemoteDataSource {
  Future<Response> updateDeviceToken({
    required String token,
    required String platform,
  });
}

class UpdateTokenRemoteDataSourceImpl implements UpdateTokenRemoteDataSource {
  final AppApiServiceClient _api;

  UpdateTokenRemoteDataSourceImpl(this._api);

  @override
  Future<Response> updateDeviceToken({
    required String token,
    required String platform,
  }) async {
    return _api.updateDeviceToken(token: token, platform: platform);
  }
}

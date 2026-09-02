import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class GuestRemoteDataSource {
  Future<Response> guestLogin({
    String? firebaseToken,
  });
}

class GuestRemoteDataSourceImpl implements GuestRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  GuestRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> guestLogin({
    String? firebaseToken,
  }) {
    final body = <String, dynamic>{};
    if (firebaseToken != null && firebaseToken.isNotEmpty) {
      body['firebaseToken'] = firebaseToken;
    }
    return _appApiServiceClient.guestLogin(body);
  }
}

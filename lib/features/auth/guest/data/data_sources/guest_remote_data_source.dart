import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class GuestRemoteDataSource {
  Future<Response> guestLogin({
    required String firebaseToken,
  });
}

class GuestRemoteDataSourceImpl implements GuestRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  GuestRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> guestLogin({
    required String firebaseToken,
  }) {
    return _appApiServiceClient.guestLogin({
      'firebaseToken': firebaseToken,
    });
  }
}

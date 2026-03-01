import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class LoginRemoteDataSource {
  Future<Response> login({
    required String email,
    required String password,
  });
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final AppApiServiceClient _apiClient;
  static const bool _useFakeData = true;

  LoginRemoteDataSourceImpl(this._apiClient);

  @override
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    if (_useFakeData) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final fakeBody = {
        'statusCode': 200,
        'message': 'Operation successful',
        'data': {
          'access_token': 'fake_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 1,
            'firstName': 'Test',
            'lastName': 'User',
            'email': email,
            'phone': '+963994636381',
            'role': 'CUSTOMER',
            'notificationChannel': 'EMAIL',
            'countryId': 1,
            'cityId': 1,
            'address': 'Damascus, Street 1',
            'isOnline': false,
            'verifiedAt': '2026-02-21T14:24:35.612Z',
            'currentLat': null,
            'currentLng': null,
            'createdAt': '2026-02-21T14:17:13.299Z',
            'updatedAt': '2026-02-21T22:07:21.076Z',
          },
        },
      };
      return Response(
        requestOptions: RequestOptions(path: 'auth/login'),
        data: fakeBody,
        statusCode: 200,
      );
    }
    return _apiClient.loginWithEmail(email, password, false);
  }
}

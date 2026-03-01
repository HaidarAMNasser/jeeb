import 'package:dio/dio.dart';

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
    String? address,
    required String notificationChannel,
  });
}

class RegisterRemoteDataSourceImpl implements RegisterRemoteDataSource {
  static const bool _useFakeData = true;

  RegisterRemoteDataSourceImpl();

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
    String? address,
    required String notificationChannel,
  }) async {
    if (_useFakeData) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return Response(
        requestOptions: RequestOptions(path: 'auth/register'),
        data: {
          'statusCode': 201,
          'message': 'User registered successfully.',
          'data': {'userId': 1, 'message': 'User registered successfully.'},
        },
        statusCode: 201,
      );
    }
    throw UnimplementedError('Real API not wired');
  }
}

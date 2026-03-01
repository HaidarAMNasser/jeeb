import 'package:dio/dio.dart';

abstract class ResetPasswordRemoteDataSource {
  Future<Response> resetPassword({
    required String email,
    required String otp,
    required String password,
  });
}

class ResetPasswordRemoteDataSourceImpl
    implements ResetPasswordRemoteDataSource {
  static const bool _useFakeData = true;

  ResetPasswordRemoteDataSourceImpl();

  @override
  Future<Response> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    if (_useFakeData) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return Response(
        requestOptions: RequestOptions(path: 'auth/reset-password'),
        data: {
          'statusCode': 200,
          'message': 'Password reset successfully.',
          'data': {'message': 'Password reset successfully.'},
        },
        statusCode: 200,
      );
    }
    throw UnimplementedError('Real API not wired');
  }
}

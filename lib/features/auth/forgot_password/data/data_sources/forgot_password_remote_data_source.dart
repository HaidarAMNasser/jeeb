import 'package:dio/dio.dart';

abstract class ForgotPasswordRemoteDataSource {
  Future<Response> forgotPassword({required String email});
}

class ForgotPasswordRemoteDataSourceImpl
    implements ForgotPasswordRemoteDataSource {
  static const bool _useFakeData = true;

  ForgotPasswordRemoteDataSourceImpl();

  @override
  Future<Response> forgotPassword({required String email}) async {
    if (_useFakeData) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return Response(
        requestOptions: RequestOptions(path: 'auth/forgot-password'),
        data: {
          'statusCode': 200,
          'message': 'OTP sent successfully.',
          'data': {'message': 'OTP sent successfully.'},
        },
        statusCode: 200,
      );
    }
    throw UnimplementedError('Real API not wired');
  }
}

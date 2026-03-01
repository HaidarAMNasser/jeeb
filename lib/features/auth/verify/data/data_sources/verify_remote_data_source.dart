import 'package:dio/dio.dart';

abstract class VerifyRemoteDataSource {
  Future<Response> verify({required String email, required String otp});
}

class VerifyRemoteDataSourceImpl implements VerifyRemoteDataSource {
  static const bool _useFakeData = true;

  VerifyRemoteDataSourceImpl();

  @override
  Future<Response> verify(
      {required String email, required String otp}) async {
    if (_useFakeData) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return Response(
        requestOptions: RequestOptions(path: 'auth/verify'),
        data: {
          'statusCode': 200,
          'message': 'Account verified successfully.',
          'data': {'message': 'Account verified successfully.'},
        },
        statusCode: 200,
      );
    }
    throw UnimplementedError('Real API not wired');
  }
}

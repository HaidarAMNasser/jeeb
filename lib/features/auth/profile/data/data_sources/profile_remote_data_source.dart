import 'package:dio/dio.dart';

abstract class ProfileRemoteDataSource {
  Future<Response> getProfile();
  Future<Response> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    int? countryId,
    int? cityId,
    String? address,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  static const bool _useFakeData = true;

  ProfileRemoteDataSourceImpl();

  @override
  Future<Response> getProfile() async {
    if (_useFakeData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final fakeUser = {
        'id': 1,
        'firstName': 'Test',
        'lastName': 'User',
        'email': 'customer@example.com',
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
      };
      return Response(
        requestOptions: RequestOptions(path: 'auth/profile'),
        data: {
          'statusCode': 200,
          'message': 'Operation successful',
          'data': fakeUser,
        },
        statusCode: 200,
      );
    }
    throw UnimplementedError('Real API not wired');
  }

  @override
  Future<Response> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    int? countryId,
    int? cityId,
    String? address,
  }) async {
    if (_useFakeData) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final fakeUser = {
        'id': 1,
        'firstName': firstName ?? 'Test',
        'lastName': lastName ?? 'User',
        'email': 'customer@example.com',
        'phone': phone ?? '+963994636381',
        'role': 'CUSTOMER',
        'notificationChannel': 'EMAIL',
        'countryId': countryId ?? 1,
        'cityId': cityId ?? 1,
        'address': address ?? 'Damascus, Street 1',
        'isOnline': false,
        'verifiedAt': '2026-02-21T14:24:35.612Z',
        'currentLat': null,
        'currentLng': null,
        'createdAt': '2026-02-21T14:17:13.299Z',
        'updatedAt': '2026-02-21T22:07:21.076Z',
      };
      return Response(
        requestOptions: RequestOptions(path: 'auth/profile'),
        data: {
          'statusCode': 200,
          'message': 'Operation successful',
          'data': fakeUser,
        },
        statusCode: 200,
      );
    }
    throw UnimplementedError('Real API not wired');
  }
}

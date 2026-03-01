import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/models/api_response_model.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/auth/register/data/data_sources/register_remote_data_source.dart';

class RegisterRepository {
  final RegisterRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const RegisterRepository(this._remoteDataSource, this._networkInfo);

  Future<Either<Failure, void>> register({
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
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
        role: role,
        countryId: countryId,
        cityId: cityId,
        address: address,
        notificationChannel: notificationChannel,
      );
      final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.isSuccess) {
        return const Right(null);
      }
      return const Left(ServerFailure(message: 'Registration failed'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

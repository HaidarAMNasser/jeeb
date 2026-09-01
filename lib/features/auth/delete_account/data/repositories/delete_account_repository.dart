import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../core/common/errors/failure.dart';
import '../../../../../core/common/models/api_response_model.dart';
import '../../../../../core/common/utils/error_handler.dart';
import '../../../../../core/infrastructure/network/network_info.dart';
import '../data_sources/delete_account_remote_data_source.dart';

class DeleteAccountRepository {
  final DeleteAccountRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const DeleteAccountRepository(
    this._remoteDataSource,
    this._networkInfo,
  );

  Future<Either<Failure, void>> deleteAccount() async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _remoteDataSource.deleteAccount();

        final apiResponse = ApiResponseModel<Map<String, dynamic>>.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>,
        );

        if (apiResponse.isSuccess) {
          return const Right(null);
        } else {
          return Left(ErrorHandler.handle(
            DioException(
              type: DioExceptionType.badResponse,
              response: response,
              requestOptions: response.requestOptions,
            ),
          ));
        }
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}

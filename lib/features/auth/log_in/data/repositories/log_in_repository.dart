import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../../core/common/errors/failure.dart';
import '../../../../../core/common/models/base_response_model.dart';
import '../../../../../core/infrastructure/network/network_info.dart';
import '../../../../../core/common/utils/api_internal_status.dart';
import '../../../../../core/common/utils/error_handler.dart';
import '../../domain/entities/log_in_entity.dart';
import '../data_sources/log_in_remote_datasource.dart';
import '../mappers/log_in_mapper.dart';
import '../models/log_in_model.dart';

class LogInRepository {
  final LogInRemoteDataSource _logInRemoteDataSource;
  final NetworkInfo _networkInfo;

  LogInRepository(this._logInRemoteDataSource, this._networkInfo);

  Future<Either<Failure, LogInEntity>> login({
    required String emailOrPhone,
    required String password,
    int? phoneCodeId,
    required bool directLogin,
    required bool loginWithPhone,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await _logInRemoteDataSource.login(
          emailOrPhone: emailOrPhone,
          password: password,
          phoneCodeId: phoneCodeId,
          directLogin: directLogin,
          loginWithPhone: loginWithPhone,
        );
        BaseResponseModel<LogInModel> baseResponseModel =
            BaseResponseModel<LogInModel>.fromJson(
          response.data!,
          (json) => LogInModel.fromJson(json as Map<String, dynamic>),
        );
        if (baseResponseModel.status == ApiInternalStatus.success) {
          return Right(baseResponseModel.data!.toDomain());
        } else {
          return Left(
            ErrorHandler.handle(
              DioException(
                type: DioExceptionType.badResponse,
                response: response,
                requestOptions: RequestOptions(),
              ),
            ),
          );
        }
      } catch (error) {
        return Left(ErrorHandler.handle(error));
      }
    } else {
      return const Left(NetworkFailure());
    }
  }
}


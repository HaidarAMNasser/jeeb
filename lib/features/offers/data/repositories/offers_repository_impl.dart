import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/common/errors/failure.dart';
import '../../domain/entities/offers_response_entity.dart';
import '../data_sources/offers_remote_data_source.dart';
import '../models/offers_response_model.dart';
import 'offers_repository.dart';

class OffersRepositoryImpl implements OffersRepository {
  final OffersRemoteDataSource _remoteDataSource;

  OffersRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, OffersResponseEntity>> getOffers({
    int page = 1,
    int limit = 10,
    String? search,
    bool? isActive,
    String? merchantId,
  }) async {
    try {
      final response = await _remoteDataSource.getOffers(
        page: page,
        limit: limit,
        search: search,
        isActive: isActive,
        merchantId: merchantId,
      );

      if (response.statusCode == 200) {
        final offersResponse = OffersResponseModel.fromJson(response.data);
        return Right(offersResponse.toDomain());
      } else {
        return Left(
          ServerFailure(
            message: 'Failed to fetch offers',
            code: response.statusCode,
          ),
        );
      }
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          message: e.message ?? 'Server error occurred',
          code: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Unexpected error occurred'));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/merchant/reviews/data/data_sources/reviews_remote_data_source.dart';
import 'package:jeeb_app/features/merchant/reviews/data/models/review_model.dart';
import 'package:jeeb_app/features/merchant/reviews/domain/entities/review_entity.dart';

class ReviewsRepository {
  final ReviewsRemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  ReviewsRepository(this._remote, this._networkInfo);

  Future<Either<Failure, ReviewEntity>> createReview({
    required String entityType,
    required int entityId,
    required int rating,
    required String comment,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remote.createReview(
        entityType: entityType,
        entityId: entityId,
        rating: rating,
        comment: comment,
      );
      final data = response.data;
      final map = data is Map<String, dynamic> ? data : data['data'] as Map<String, dynamic>?;
      if (map == null) return const Left(ServerFailure(message: 'Invalid response'));
      return Right(ReviewModel.fromJson(map));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, ReviewEntity>> getReview(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remote.getReview(id);
      final data = response.data;
      final map = data is Map<String, dynamic> ? data : data['data'] as Map<String, dynamic>?;
      if (map == null) return const Left(ServerFailure(message: 'Invalid response'));
      return Right(ReviewModel.fromJson(map));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, ReviewEntity>> updateReview(
    String id, {
    int? rating,
    String? comment,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remote.updateReview(id, rating: rating, comment: comment);
      final data = response.data;
      final map = data is Map<String, dynamic> ? data : data['data'] as Map<String, dynamic>?;
      if (map == null) return const Left(ServerFailure(message: 'Invalid response'));
      return Right(ReviewModel.fromJson(map));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, void>> deleteReview(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await _remote.deleteReview(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

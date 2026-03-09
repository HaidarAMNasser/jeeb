import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ReviewsRemoteDataSource {
  Future<Response> createReview({
    required String entityType,
    required int entityId,
    required int rating,
    required String comment,
  });

  Future<Response> getReview(String id);
  Future<Response> updateReview(String id, {int? rating, String? comment});
  Future<Response> deleteReview(String id);
}

class ReviewsRemoteDataSourceImpl implements ReviewsRemoteDataSource {
  final AppApiServiceClient _api;

  ReviewsRemoteDataSourceImpl(this._api);

  @override
  Future<Response> createReview({
    required String entityType,
    required int entityId,
    required int rating,
    required String comment,
  }) {
    return _api.createReview(
      entityType: entityType,
      entityId: entityId,
      rating: rating,
      comment: comment,
    );
  }

  @override
  Future<Response> getReview(String id) => _api.getReview(id);

  @override
  Future<Response> updateReview(String id, {int? rating, String? comment}) {
    return _api.updateReview(id, rating: rating, comment: comment);
  }

  @override
  Future<Response> deleteReview(String id) => _api.deleteReview(id);
}

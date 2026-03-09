part of 'reviews_bloc.dart';

abstract class ReviewsEvent extends Equatable {
  const ReviewsEvent();

  @override
  List<Object?> get props => [];
}

class CreateReviewEvent extends ReviewsEvent {
  final String entityType;
  final int entityId;
  final int rating;
  final String comment;

  const CreateReviewEvent({
    required this.entityType,
    required this.entityId,
    required this.rating,
    required this.comment,
  });

  @override
  List<Object?> get props => [entityType, entityId, rating, comment];
}

class GetMyReviewEvent extends ReviewsEvent {
  final String reviewId;

  const GetMyReviewEvent(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

class UpdateReviewEvent extends ReviewsEvent {
  final String reviewId;
  final int? rating;
  final String? comment;

  const UpdateReviewEvent({
    required this.reviewId,
    this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [reviewId, rating, comment];
}

class DeleteReviewEvent extends ReviewsEvent {
  final String reviewId;

  const DeleteReviewEvent(this.reviewId);

  @override
  List<Object?> get props => [reviewId];
}

class SetMyReviewEvent extends ReviewsEvent {
  final ReviewEntity? review;

  const SetMyReviewEvent(this.review);

  @override
  List<Object?> get props => [review];
}

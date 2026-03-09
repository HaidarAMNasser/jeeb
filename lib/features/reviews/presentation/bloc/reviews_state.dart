part of 'reviews_bloc.dart';

abstract class ReviewsState extends Equatable {
  const ReviewsState();

  @override
  List<Object?> get props => [];
}

class ReviewsInitial extends ReviewsState {
  const ReviewsInitial();
}

class ReviewsLoading extends ReviewsState {
  const ReviewsLoading();
}

class ReviewsCreateSuccess extends ReviewsState {
  final ReviewEntity review;

  const ReviewsCreateSuccess(this.review);

  @override
  List<Object?> get props => [review];
}

class ReviewsLoaded extends ReviewsState {
  final ReviewEntity review;

  const ReviewsLoaded(this.review);

  @override
  List<Object?> get props => [review];
}

class ReviewsUpdateSuccess extends ReviewsState {
  final ReviewEntity review;

  const ReviewsUpdateSuccess(this.review);

  @override
  List<Object?> get props => [review];
}

class ReviewsDeleteSuccess extends ReviewsState {
  const ReviewsDeleteSuccess();
}

class ReviewsError extends ReviewsState {
  final String message;

  const ReviewsError(this.message);

  @override
  List<Object?> get props => [message];
}
